import 'package:material_ui/material_ui.dart';

import '../services/formatters.dart';
import '../theme/app_theme.dart';

class SummaryCards extends StatelessWidget {
  const SummaryCards({
    super.key,
    required this.monthly,
    required this.yearly,
    required this.atRisk,
    required this.savings,
  });

  final double monthly;
  final double yearly;
  final double atRisk;
  final double savings;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Gasto Mensal',
                value: formatCurrency(monthly),
                icon: Icons.calendar_month_outlined,
                accent: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: 'Anual Projetado',
                value: formatCurrency(yearly),
                icon: Icons.trending_up_rounded,
                accent: AppColors.primaryAlt,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Valor em Risco',
                value: formatCurrency(atRisk),
                icon: Icons.warning_amber_rounded,
                accent: AppColors.alert,
                subtitle: 'Próximos 7 dias',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: 'Economia',
                value: formatCurrency(savings),
                icon: Icons.savings_outlined,
                accent: AppColors.success,
                subtitle: 'Com cancelamentos',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
