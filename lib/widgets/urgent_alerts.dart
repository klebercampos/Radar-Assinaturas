import 'package:material_ui/material_ui.dart';

import '../models/subscription.dart';
import '../services/formatters.dart';
import '../theme/app_theme.dart';
import 'service_icon.dart';

class UrgentAlerts extends StatelessWidget {
  const UrgentAlerts({
    super.key,
    required this.items,
    required this.onTap,
  });

  final List<Subscription> items;
  final ValueChanged<Subscription> onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.priority_high_rounded, color: AppColors.danger, size: 20),
            const SizedBox(width: 6),
            Text(
              'Atenção Imediata',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...items.map((sub) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: isDark
                  ? AppColors.alert.withValues(alpha: 0.15)
                  : AppColors.urgentBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isDark
                      ? AppColors.alert.withValues(alpha: 0.5)
                      : AppColors.urgentBorder,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onTap(sub),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ServiceIcon(iconKey: sub.iconKey, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sub.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${sub.badgeLabel()} · ${formatCurrency(sub.amount)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.alert,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
