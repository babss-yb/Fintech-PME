import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PriorityChip extends StatelessWidget {
  final String priority;

  const PriorityChip({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    Color chipColor;
    String label;

    switch (priority.toLowerCase()) {
      case 'high':
        chipColor = AppTheme.error;
        label = 'Haute';
        break;
      case 'medium':
        chipColor = AppTheme.warning;
        label = 'Moyenne';
        break;
      case 'low':
      default:
        chipColor = AppTheme.success;
        label = 'Basse';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.5), width: 1),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: chipColor,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
