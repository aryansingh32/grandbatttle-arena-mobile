import 'package:flutter/material.dart';
import 'package:grand_battle_arena/pages/filtered_tournaments_page.dart';

class HomeFilterGrid extends StatelessWidget {
  const HomeFilterGrid({super.key});

  final List<Map<String, dynamic>> _filters = const [
    {'label': 'Clash Squad', 'icon': Icons.security, 'color': Colors.orange, 'type': 'game'},
    {'label': 'Battle Royal', 'icon': Icons.map, 'color': Colors.green, 'type': 'game'},
    {'label': 'Lone Wolf', 'icon': Icons.person, 'color': Colors.red, 'type': 'game'},
    {'label': 'Duo', 'icon': Icons.people, 'color': Colors.blue, 'type': 'teamSize'},
    {'label': 'Squad', 'icon': Icons.groups, 'color': Colors.purple, 'type': 'teamSize'},
    {'label': 'Solo', 'icon': Icons.person_outline, 'color': Colors.teal, 'type': 'teamSize'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Browse by Category",
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.1,
            ),
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              final filter = _filters[index];
              return _buildFilterCard(context, filter);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard(BuildContext context, Map<String, dynamic> filter) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FilteredTournamentsPage(
              filterQuery: filter['label'],
              filterType: filter['type'],
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (filter['color'] as Color).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                filter['icon'] as IconData,
                color: filter['color'] as Color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              filter['label'] as String,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
