enum SubscriptionType { trial, recurring }

enum BillingCycle { monthly, yearly, weekly, oneTime }

enum ReminderOffset { sameDay, oneDay, threeDays, sevenDays }

enum SubscriptionStatus { active, canceled }

enum ServicePreset {
  netflix,
  spotify,
  amazonPrime,
  chatGpt,
  iCloud,
  adobe,
  academia,
  outro,
}

extension ServicePresetX on ServicePreset {
  String get label {
    switch (this) {
      case ServicePreset.netflix:
        return 'Netflix';
      case ServicePreset.spotify:
        return 'Spotify';
      case ServicePreset.amazonPrime:
        return 'Amazon Prime';
      case ServicePreset.chatGpt:
        return 'ChatGPT Plus';
      case ServicePreset.iCloud:
        return 'iCloud / Google One';
      case ServicePreset.adobe:
        return 'Adobe';
      case ServicePreset.academia:
        return 'Academia';
      case ServicePreset.outro:
        return 'Outro';
    }
  }

  String get iconKey {
    switch (this) {
      case ServicePreset.netflix:
        return 'netflix';
      case ServicePreset.spotify:
        return 'spotify';
      case ServicePreset.amazonPrime:
        return 'amazon';
      case ServicePreset.chatGpt:
        return 'chatgpt';
      case ServicePreset.iCloud:
        return 'cloud';
      case ServicePreset.adobe:
        return 'adobe';
      case ServicePreset.academia:
        return 'fitness';
      case ServicePreset.outro:
        return 'other';
    }
  }
}

class Subscription {
  Subscription({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.type,
    required this.amount,
    required this.cycle,
    required this.nextBillingDate,
    this.paymentMethod,
    this.cancelPath,
    this.reminderOffset = ReminderOffset.threeDays,
    this.status = SubscriptionStatus.active,
    this.canceledAt,
    this.isDemo = false,
  });

  final String id;
  final String name;
  final String iconKey;
  final SubscriptionType type;
  final double amount;
  final BillingCycle cycle;
  final DateTime nextBillingDate;
  final String? paymentMethod;
  final String? cancelPath;
  final ReminderOffset reminderOffset;
  final SubscriptionStatus status;
  final DateTime? canceledAt;
  final bool isDemo;

  bool get isActive => status == SubscriptionStatus.active;
  bool get isCanceled => status == SubscriptionStatus.canceled;
  bool get isTrial => type == SubscriptionType.trial;

  /// Valor convertido para base mensal (assinaturas ativas).
  double get monthlyEquivalent {
    if (!isActive) return 0;
    switch (cycle) {
      case BillingCycle.weekly:
        return amount * 52 / 12;
      case BillingCycle.monthly:
        return amount;
      case BillingCycle.yearly:
        return amount / 12;
      case BillingCycle.oneTime:
        return 0;
    }
  }

  /// Contribuição para projeção anual (12 meses).
  double get yearlyProjection {
    if (!isActive) return 0;
    switch (cycle) {
      case BillingCycle.weekly:
        return amount * 52;
      case BillingCycle.monthly:
        return amount * 12;
      case BillingCycle.yearly:
        return amount;
      case BillingCycle.oneTime:
        return amount;
    }
  }

  int daysUntilBilling([DateTime? from]) {
    final now = from ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(
      nextBillingDate.year,
      nextBillingDate.month,
      nextBillingDate.day,
    );
    return due.difference(today).inDays;
  }

  bool isDueWithinDays(int days, [DateTime? from]) {
    if (!isActive) return false;
    final d = daysUntilBilling(from);
    return d >= 0 && d <= days;
  }

  bool get isUrgent => isDueWithinDays(3);

  String get cycleLabel {
    if (isTrial) return 'Teste Grátis';
    switch (cycle) {
      case BillingCycle.weekly:
        return 'Semanal';
      case BillingCycle.monthly:
        return 'Mensal';
      case BillingCycle.yearly:
        return 'Anual';
      case BillingCycle.oneTime:
        return 'Cobrança Única';
    }
  }

  String badgeLabel([DateTime? from]) {
    if (isCanceled) return 'Cancelada';
    final days = daysUntilBilling(from);
    if (days < 0) return 'Vencida há ${-days} dia${-days == 1 ? '' : 's'}';
    if (days == 0) return 'Vence hoje';
    if (days == 1) return 'Falta 1 dia';
    if (days <= 7) return 'Faltam $days dias';
    if (isTrial) return 'Faltam $days dias';
    return 'Renova em $days dias';
  }

  int get reminderDays {
    switch (reminderOffset) {
      case ReminderOffset.sameDay:
        return 0;
      case ReminderOffset.oneDay:
        return 1;
      case ReminderOffset.threeDays:
        return 3;
      case ReminderOffset.sevenDays:
        return 7;
    }
  }

  Subscription copyWith({
    String? id,
    String? name,
    String? iconKey,
    SubscriptionType? type,
    double? amount,
    BillingCycle? cycle,
    DateTime? nextBillingDate,
    String? paymentMethod,
    String? cancelPath,
    ReminderOffset? reminderOffset,
    SubscriptionStatus? status,
    DateTime? canceledAt,
    bool? isDemo,
    bool clearPaymentMethod = false,
    bool clearCancelPath = false,
    bool clearCanceledAt = false,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      cycle: cycle ?? this.cycle,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      paymentMethod:
          clearPaymentMethod ? null : (paymentMethod ?? this.paymentMethod),
      cancelPath: clearCancelPath ? null : (cancelPath ?? this.cancelPath),
      reminderOffset: reminderOffset ?? this.reminderOffset,
      status: status ?? this.status,
      canceledAt: clearCanceledAt ? null : (canceledAt ?? this.canceledAt),
      isDemo: isDemo ?? this.isDemo,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconKey': iconKey,
        'type': type.name,
        'amount': amount,
        'cycle': cycle.name,
        'nextBillingDate': nextBillingDate.toIso8601String(),
        'paymentMethod': paymentMethod,
        'cancelPath': cancelPath,
        'reminderOffset': reminderOffset.name,
        'status': status.name,
        'canceledAt': canceledAt?.toIso8601String(),
        'isDemo': isDemo,
      };

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      name: json['name'] as String,
      iconKey: json['iconKey'] as String? ?? 'other',
      type: SubscriptionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SubscriptionType.recurring,
      ),
      amount: (json['amount'] as num).toDouble(),
      cycle: BillingCycle.values.firstWhere(
        (e) => e.name == json['cycle'],
        orElse: () => BillingCycle.monthly,
      ),
      nextBillingDate: DateTime.parse(json['nextBillingDate'] as String),
      paymentMethod: json['paymentMethod'] as String?,
      cancelPath: json['cancelPath'] as String?,
      reminderOffset: ReminderOffset.values.firstWhere(
        (e) => e.name == json['reminderOffset'],
        orElse: () => ReminderOffset.threeDays,
      ),
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SubscriptionStatus.active,
      ),
      canceledAt: json['canceledAt'] != null
          ? DateTime.parse(json['canceledAt'] as String)
          : null,
      isDemo: json['isDemo'] as bool? ?? false,
    );
  }
}

enum SubscriptionFilter { allActive, trials, dueSoon, canceled }

extension SubscriptionFilterX on SubscriptionFilter {
  String get label {
    switch (this) {
      case SubscriptionFilter.allActive:
        return 'Todas Ativas';
      case SubscriptionFilter.trials:
        return 'Testes Grátis';
      case SubscriptionFilter.dueSoon:
        return 'Vencendo em 7 dias';
      case SubscriptionFilter.canceled:
        return 'Canceladas';
    }
  }
}
