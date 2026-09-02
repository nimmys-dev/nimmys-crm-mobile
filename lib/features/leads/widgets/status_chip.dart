import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nimmys_crm/core/theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status;

  Color _getColor() {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.blue.shade700;
      case 'ongoing':
        return Colors.orange.shade700;
      case 'won':
        return Colors.green.shade700;
      case 'lost':
        return Colors.red.shade700;
      case 'closed':
        return Colors.grey.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getColor().withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getColor().withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        status,
        style: context.type.caption.copyWith(
          color: _getColor(),
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
    );
  }
}
