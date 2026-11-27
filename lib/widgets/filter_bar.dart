import 'package:material_ui/material_ui.dart';

import '../models/subscription.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final SubscriptionFilter selected;
  final ValueChanged<SubscriptionFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: SubscriptionFilter.values.map((f) {
          final isSelected = f == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f.label),
              selected: isSelected,
              onSelected: (_) => onChanged(f),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}
