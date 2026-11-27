import 'package:material_ui/material_ui.dart';

import '../models/subscription.dart';
import '../services/formatters.dart';
import '../services/subscription_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/service_icon.dart';
import 'subscription_form_screen.dart';

class SubscriptionDetailScreen extends StatelessWidget {
  const SubscriptionDetailScreen({
    super.key,
    required this.repository,
    required this.subscriptionId,
  });

  final SubscriptionRepository repository;
  final String subscriptionId;

  Future<void> _confirmDelete(BuildContext context, Subscription sub) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir assinatura?'),
        content: Text(
          'Tem certeza que deseja excluir "${sub.name}" definitivamente? '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await repository.delete(sub.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _markCanceled(BuildContext context, Subscription sub) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marcar como cancelada?'),
        content: Text(
          '"${sub.name}" sairá dos gastos ativos e entrará na economia '
          'com cancelamentos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await repository.markCanceled(sub.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assinatura marcada como cancelada.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final sub = repository.byId(subscriptionId);
        if (sub == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Assinatura')),
            body: const Center(child: Text('Assinatura não encontrada.')),
          );
        }

        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detalhes'),
            actions: [
              IconButton(
                tooltip: 'Editar',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SubscriptionFormScreen(
                        repository: repository,
                        existing: sub,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'Excluir',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context, sub),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Row(
                children: [
                  ServiceIcon(iconKey: sub.iconKey, size: 56),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sub.cycleLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _InfoCard(
                children: [
                  _InfoRow(
                    label: 'Valor',
                    value: formatCurrency(sub.amount),
                  ),
                  _InfoRow(
                    label: sub.isTrial ? 'Fim do trial' : 'Próxima cobrança',
                    value: formatDate(sub.nextBillingDate),
                  ),
                  _InfoRow(label: 'Status do prazo', value: sub.badgeLabel()),
                  if (sub.paymentMethod != null &&
                      sub.paymentMethod!.isNotEmpty)
                    _InfoRow(
                      label: 'Pagamento',
                      value: sub.paymentMethod!,
                    ),
                  _InfoRow(
                    label: 'Lembrete',
                    value: _reminderLabel(sub.reminderOffset),
                  ),
                  if (sub.cancelPath != null && sub.cancelPath!.isNotEmpty)
                    _InfoRow(
                      label: 'Como cancelar',
                      value: sub.cancelPath!,
                    ),
                  if (sub.isCanceled && sub.canceledAt != null)
                    _InfoRow(
                      label: 'Cancelada em',
                      value: formatDate(sub.canceledAt!),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              if (sub.isActive) ...[
                FilledButton.icon(
                  onPressed: () => _markCanceled(context, sub),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Marcar como Cancelada'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton.icon(
                onPressed: () => _confirmDelete(context, sub),
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('Excluir definitivamente'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _reminderLabel(ReminderOffset offset) {
    switch (offset) {
      case ReminderOffset.sameDay:
        return 'No dia';
      case ReminderOffset.oneDay:
        return '1 dia antes';
      case ReminderOffset.threeDays:
        return '3 dias antes';
      case ReminderOffset.sevenDays:
        return '7 dias antes';
    }
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(children: children),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
