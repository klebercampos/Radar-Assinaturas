import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/subscription.dart';

/// Encapsula `flutter_local_notifications` com gate `kIsWeb`
/// para não quebrar a execução no navegador.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> init() async {
    if (kIsWeb) {
      debugPrint('NotificationService: desabilitado na Web (kIsWeb).');
      return;
    }
    if (!isSupported) {
      debugPrint('NotificationService: plataforma sem suporte a notificações.');
      return;
    }
    if (_initialized) return;

    try {
      tz.initializeTimeZones();

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const settings = InitializationSettings(android: android, iOS: ios);

      await _plugin.initialize(settings);

      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();

      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService: init falhou (ignorado): $e');
    }
  }

  Future<void> scheduleForSubscription(Subscription sub) async {
    if (!_initialized || !sub.isActive) return;

    await cancelForSubscription(sub.id);

    final daysBefore = sub.reminderDays;
    final due = DateTime(
      sub.nextBillingDate.year,
      sub.nextBillingDate.month,
      sub.nextBillingDate.day,
      9,
    );
    final when = due.subtract(Duration(days: daysBefore));
    if (when.isBefore(DateTime.now())) return;

    final tzWhen = tz.TZDateTime.from(when, tz.local);
    final id = _notificationId(sub.id);

    const androidDetails = AndroidNotificationDetails(
      'radar_reminders',
      'Lembretes de Assinaturas',
      channelDescription: 'Alertas de trials e cobranças próximas',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    final title = sub.isTrial
        ? 'Trial terminando: ${sub.name}'
        : 'Cobrança próxima: ${sub.name}';
    final body = sub.isTrial
        ? 'Seu teste grátis termina em breve. Cancele se não quiser ser cobrado.'
        : 'Renovação em breve. Valor: ${sub.amount.toStringAsFixed(2)}.';

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzWhen,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Falha ao agendar notificação: $e');
    }
  }

  Future<void> cancelForSubscription(String subscriptionId) async {
    if (!_initialized) return;
    await _plugin.cancel(_notificationId(subscriptionId));
  }

  Future<void> rescheduleAll(List<Subscription> items) async {
    if (!_initialized) return;
    for (final sub in items.where((s) => s.isActive)) {
      await scheduleForSubscription(sub);
    }
  }

  int _notificationId(String subscriptionId) {
    return subscriptionId.hashCode & 0x7fffffff;
  }
}
