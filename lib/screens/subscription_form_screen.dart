import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../models/subscription.dart';
import '../services/formatters.dart';
import '../services/subscription_repository.dart';

class SubscriptionFormScreen extends StatefulWidget {
  const SubscriptionFormScreen({
    super.key,
    required this.repository,
    this.existing,
  });

  final SubscriptionRepository repository;
  final Subscription? existing;

  @override
  State<SubscriptionFormScreen> createState() => _SubscriptionFormScreenState();
}

class _SubscriptionFormScreenState extends State<SubscriptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _paymentController;
  late final TextEditingController _cancelPathController;

  late SubscriptionType _type;
  late BillingCycle _cycle;
  late DateTime _nextDate;
  late ReminderOffset _reminder;
  late String _iconKey;
  ServicePreset? _selectedPreset;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _amountController = TextEditingController(
      text: e != null ? e.amount.toStringAsFixed(2).replaceAll('.', ',') : '',
    );
    _paymentController = TextEditingController(text: e?.paymentMethod ?? '');
    _cancelPathController = TextEditingController(text: e?.cancelPath ?? '');
    _type = e?.type ?? SubscriptionType.trial;
    _cycle = e?.cycle ?? BillingCycle.monthly;
    _nextDate = e?.nextBillingDate ?? DateTime.now().add(const Duration(days: 7));
    _reminder = e?.reminderOffset ?? ReminderOffset.threeDays;
    _iconKey = e?.iconKey ?? 'other';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _paymentController.dispose();
    _cancelPathController.dispose();
    super.dispose();
  }

  void _applyPreset(ServicePreset preset) {
    setState(() {
      _selectedPreset = preset;
      _iconKey = preset.iconKey;
      if (preset != ServicePreset.outro) {
        _nameController.text = preset.label;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      locale: const Locale('pt', 'BR'),
      helpText: 'Próxima cobrança / fim do trial',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    if (picked != null) {
      setState(() => _nextDate = picked);
    }
  }

  void _addDays(int days) {
    final base = DateTime.now();
    setState(() {
      _nextDate = DateTime(base.year, base.month, base.day)
          .add(Duration(days: days));
    });
  }

  double? _parseAmount(String raw) {
    final cleaned = raw.trim().replaceAll(r'R$', '').replaceAll(' ', '');
    if (cleaned.isEmpty) return null;
    final normalized = cleaned.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = _parseAmount(_amountController.text);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um valor válido.')),
      );
      return;
    }

    final payment = _paymentController.text.trim();
    final cancelPath = _cancelPathController.text.trim();

    if (isEditing) {
      final updated = widget.existing!.copyWith(
        name: _nameController.text.trim(),
        iconKey: _iconKey,
        type: _type,
        amount: amount,
        cycle: _cycle,
        nextBillingDate: _nextDate,
        paymentMethod: payment.isEmpty ? null : payment,
        cancelPath: cancelPath.isEmpty ? null : cancelPath,
        reminderOffset: _reminder,
        clearPaymentMethod: payment.isEmpty,
        clearCancelPath: cancelPath.isEmpty,
      );
      await widget.repository.upsert(updated);
    } else {
      await widget.repository.create(
        name: _nameController.text.trim(),
        iconKey: _iconKey,
        type: _type,
        amount: amount,
        cycle: _cycle,
        nextBillingDate: _nextDate,
        paymentMethod: payment.isEmpty ? null : payment,
        cancelPath: cancelPath.isEmpty ? null : cancelPath,
        reminderOffset: _reminder,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Assinatura' : 'Nova Assinatura'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(
              'Presets rápidos',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ServicePreset.values.map((p) {
                final selected = _selectedPreset == p ||
                    (_selectedPreset == null && _iconKey == p.iconKey);
                return ChoiceChip(
                  label: Text(p.label),
                  selected: selected,
                  onSelected: (_) => _applyPreset(p),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome do serviço *',
                hintText: 'Ex.: Netflix',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Informe o nome do serviço';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Tipo de monitoramento',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<SubscriptionType>(
              segments: const [
                ButtonSegment(
                  value: SubscriptionType.trial,
                  label: Text('Teste Grátis'),
                  icon: Icon(Icons.hourglass_top_rounded),
                ),
                ButtonSegment(
                  value: SubscriptionType.recurring,
                  label: Text('Recorrente'),
                  icon: Icon(Icons.autorenew),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: _type == SubscriptionType.trial
                    ? 'Valor após o trial (R\$) *'
                    : 'Valor da parcela (R\$) *',
                hintText: '0,00',
                prefixText: r'R$ ',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Informe o valor';
                if (_parseAmount(v) == null) return 'Valor inválido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<BillingCycle>(
              key: ValueKey(_cycle),
              initialValue: _cycle,
              decoration: const InputDecoration(labelText: 'Ciclo de cobrança'),
              items: const [
                DropdownMenuItem(
                  value: BillingCycle.monthly,
                  child: Text('Mensal'),
                ),
                DropdownMenuItem(
                  value: BillingCycle.yearly,
                  child: Text('Anual'),
                ),
                DropdownMenuItem(
                  value: BillingCycle.weekly,
                  child: Text('Semanal'),
                ),
                DropdownMenuItem(
                  value: BillingCycle.oneTime,
                  child: Text('Cobrança Única'),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _cycle = v);
              },
            ),
            const SizedBox(height: 16),
            Text(
              _type == SubscriptionType.trial
                  ? 'Fim do teste grátis'
                  : 'Próxima cobrança',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  suffixIcon: Icon(Icons.edit_calendar_outlined),
                ),
                child: Text(formatDate(_nextDate)),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('+7 dias'),
                  onPressed: () => _addDays(7),
                ),
                ActionChip(
                  label: const Text('+14 dias'),
                  onPressed: () => _addDays(14),
                ),
                ActionChip(
                  label: const Text('+30 dias'),
                  onPressed: () => _addDays(30),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _paymentController,
              decoration: const InputDecoration(
                labelText: 'Cartão / meio de pagamento',
                hintText: 'Ex.: Nubank •••• 4532',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cancelPathController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Como / onde cancelar',
                hintText: 'Ex.: App Store > Assinaturas',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ReminderOffset>(
              key: ValueKey(_reminder),
              initialValue: _reminder,
              decoration: const InputDecoration(
                labelText: 'Lembrete antecipado',
              ),
              items: const [
                DropdownMenuItem(
                  value: ReminderOffset.sameDay,
                  child: Text('No dia'),
                ),
                DropdownMenuItem(
                  value: ReminderOffset.oneDay,
                  child: Text('1 dia antes'),
                ),
                DropdownMenuItem(
                  value: ReminderOffset.threeDays,
                  child: Text('3 dias antes'),
                ),
                DropdownMenuItem(
                  value: ReminderOffset.sevenDays,
                  child: Text('7 dias antes'),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _reminder = v);
              },
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(isEditing ? 'Salvar alterações' : 'Salvar'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
