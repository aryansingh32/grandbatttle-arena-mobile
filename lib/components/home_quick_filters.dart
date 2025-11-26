import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';
import 'package:grand_battle_arena/services/filter_provider.dart';

/// CHANGE: Fancy quick filters requested for Home to control tournament list + scoreboard.
class HomeQuickFilters extends StatelessWidget {
  const HomeQuickFilters({super.key});

  static const _teamSizes = ['All', 'Solo', 'Duo', 'Squad', 'Hexa'];
  static const _maps = ['All', 'Bermuda', 'Purgatory', 'Kalahari'];

  @override
  Widget build(BuildContext context) {
    final filters = context.watch<FilterProvider>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            offset: const Offset(0, 12),
            blurRadius: 25,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_alt_rounded, color: Theme.of(context).colorScheme.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Quick Filters',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildChipRow(
            label: 'Team',
            items: _teamSizes,
            selected: filters.teamSizeFilter,
            onSelected: filters.setTeamSizeFilter,
            context: context,
          ),
          const SizedBox(height: 10),
          _buildChipRow(
            label: 'Map',
            items: _maps,
            selected: filters.mapFilter,
            onSelected: filters.setMapFilter,
            context: context,
          ),
        ],
      ),
    );
  }

  Widget _buildChipRow({
    required String label,
    required List<String> items,
    required String selected,
    required ValueChanged<String> onSelected,
    required BuildContext context,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 12,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final isActive = selected == item;
            return GestureDetector(
              onTap: () => onSelected(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: isActive
                      ? LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.secondary,
                            Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                          ],
                        )
                      : null,
                  color: isActive ? null : Theme.of(context).primaryColor.withOpacity(0.4),
                  border: Border.all(
                    color: isActive
                        ? Colors.transparent
                        : Theme.of(context).disabledColor.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    color: isActive ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

