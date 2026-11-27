import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/subscription.dart';
import 'notification_service.dart';
import 'storage_service.dart';

class SubscriptionRepository extends ChangeNotifier {
  SubscriptionRepository({
    StorageService? storage,
    NotificationService? notifications,
  })  : _storage = storage ?? StorageService(),
        _notifications = notifications ?? NotificationService.instance;

  final StorageService _storage;
  final NotificationService _notifications;
  final _uuid = const Uuid();

  List<Subscription> _items = [];
  bool _loading = true;
  String _themeMode = 'system';
  String _searchQuery = '';
  SubscriptionFilter _filter = SubscriptionFilter.allActive;

  List<Subscription> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  String get themeMode => _themeMode;
  String get searchQuery => _searchQuery;
  SubscriptionFilter get filter => _filter;

  Future<void> init() async {
    _loading = true;
    notifyListeners();

    _themeMode = await _storage.loadThemeMode();
    _items = await _storage.loadSubscriptions();

    final seeded = await _storage.isDemoSeeded();
    if (_items.isEmpty && !seeded) {
      _items = _buildSeedData();
      await _storage.saveSubscriptions(_items);
      await _storage.setDemoSeeded(true);
    }

    await _notifications.init();
    await _notifications.rescheduleAll(_items);

    _loading = false;
    notifyListeners();
  }

  List<Subscription> get filteredItems {
    Iterable<Subscription> list = _items;

    switch (_filter) {
      case SubscriptionFilter.allActive:
        list = list.where((s) => s.isActive);
      case SubscriptionFilter.trials:
        list = list.where((s) => s.isActive && s.isTrial);
      case SubscriptionFilter.dueSoon:
        list = list.where((s) => s.isDueWithinDays(7));
      case SubscriptionFilter.canceled:
        list = list.where((s) => s.isCanceled);
    }

    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((s) {
        final name = s.name.toLowerCase();
        final pay = (s.paymentMethod ?? '').toLowerCase();
        return name.contains(q) || pay.contains(q);
      });
    }

    final result = list.toList()
      ..sort((a, b) {
        if (a.isCanceled != b.isCanceled) {
          return a.isCanceled ? 1 : -1;
        }
        return a.nextBillingDate.compareTo(b.nextBillingDate);
      });
    return result;
  }

  List<Subscription> get urgentItems {
    final list = _items.where((s) => s.isUrgent).toList()
      ..sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
    return list;
  }

  double get monthlySpend =>
      _items.fold(0.0, (sum, s) => sum + s.monthlyEquivalent);

  double get yearlyProjection =>
      _items.fold(0.0, (sum, s) => sum + s.yearlyProjection);

  double get atRiskAmount {
    return _items
        .where((s) => s.isDueWithinDays(7))
        .fold(0.0, (sum, s) => sum + s.amount);
  }

  /// Economia estimada (base mensal) das canceladas.
  double get savingsFromCancellations {
    return _items.where((s) => s.isCanceled).fold(0.0, (sum, s) {
      switch (s.cycle) {
        case BillingCycle.weekly:
          return sum + s.amount * 52 / 12;
        case BillingCycle.monthly:
          return sum + s.amount;
        case BillingCycle.yearly:
          return sum + s.amount / 12;
        case BillingCycle.oneTime:
          return sum + s.amount;
      }
    });
  }

  bool get hasDemoData => _items.any((s) => s.isDemo);

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setFilter(SubscriptionFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  Future<void> setThemeMode(String mode) async {
    _themeMode = mode;
    await _storage.saveThemeMode(mode);
    notifyListeners();
  }

  Future<void> upsert(Subscription sub) async {
    final index = _items.indexWhere((s) => s.id == sub.id);
    if (index >= 0) {
      _items = [..._items]..[index] = sub;
    } else {
      _items = [..._items, sub];
    }
    await _persist();
    if (sub.isActive) {
      await _notifications.scheduleForSubscription(sub);
    } else {
      await _notifications.cancelForSubscription(sub.id);
    }
  }

  Future<Subscription> create({
    required String name,
    required String iconKey,
    required SubscriptionType type,
    required double amount,
    required BillingCycle cycle,
    required DateTime nextBillingDate,
    String? paymentMethod,
    String? cancelPath,
    ReminderOffset reminderOffset = ReminderOffset.threeDays,
  }) async {
    final sub = Subscription(
      id: _uuid.v4(),
      name: name,
      iconKey: iconKey,
      type: type,
      amount: amount,
      cycle: cycle,
      nextBillingDate: nextBillingDate,
      paymentMethod: paymentMethod,
      cancelPath: cancelPath,
      reminderOffset: reminderOffset,
    );
    await upsert(sub);
    return sub;
  }

  Future<void> markCanceled(String id) async {
    final index = _items.indexWhere((s) => s.id == id);
    if (index < 0) return;
    final updated = _items[index].copyWith(
      status: SubscriptionStatus.canceled,
      canceledAt: DateTime.now(),
    );
    await upsert(updated);
  }

  Future<void> delete(String id) async {
    _items = _items.where((s) => s.id != id).toList();
    await _notifications.cancelForSubscription(id);
    await _persist();
  }

  Future<void> clearDemoData() async {
    _items = _items.where((s) => !s.isDemo).toList();
    await _persist();
    await _notifications.rescheduleAll(_items);
  }

  Future<void> _persist() async {
    await _storage.saveSubscriptions(_items);
    notifyListeners();
  }

  Subscription? byId(String id) {
    try {
      return _items.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Subscription> _buildSeedData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [
      Subscription(
        id: _uuid.v4(),
        name: 'Adobe Creative Cloud',
        iconKey: 'adobe',
        type: SubscriptionType.trial,
        amount: 149.90,
        cycle: BillingCycle.monthly,
        nextBillingDate: today.add(const Duration(days: 2)),
        paymentMethod: 'Nubank •••• 4532',
        cancelPath: 'adobe.com/account > Planos',
        reminderOffset: ReminderOffset.oneDay,
        isDemo: true,
      ),
      Subscription(
        id: _uuid.v4(),
        name: 'ChatGPT Plus',
        iconKey: 'chatgpt',
        type: SubscriptionType.trial,
        amount: 109.00,
        cycle: BillingCycle.monthly,
        nextBillingDate: today.add(const Duration(days: 5)),
        paymentMethod: 'Inter Virtual',
        cancelPath: 'chat.openai.com > Configurações',
        reminderOffset: ReminderOffset.threeDays,
        isDemo: true,
      ),
      Subscription(
        id: _uuid.v4(),
        name: 'Spotify Duo',
        iconKey: 'spotify',
        type: SubscriptionType.recurring,
        amount: 27.90,
        cycle: BillingCycle.monthly,
        nextBillingDate: today.add(const Duration(days: 18)),
        paymentMethod: 'Nubank •••• 4532',
        cancelPath: 'App Spotify > Conta > Assinatura',
        reminderOffset: ReminderOffset.threeDays,
        isDemo: true,
      ),
      Subscription(
        id: _uuid.v4(),
        name: 'Amazon Prime',
        iconKey: 'amazon',
        type: SubscriptionType.recurring,
        amount: 119.00,
        cycle: BillingCycle.yearly,
        nextBillingDate: today.add(const Duration(days: 64)),
        paymentMethod: 'Visa •••• 8821',
        cancelPath: 'amazon.com.br > Conta > Assinaturas',
        reminderOffset: ReminderOffset.sevenDays,
        isDemo: true,
      ),
    ];
  }
}
