import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import 'app_field_label.dart';

/// Pairs an [AppFieldLabel] with its input and the spacing between form rows.
class AppFormField extends StatelessWidget {
  const AppFormField({
    super.key,
    required this.label,
    required this.child,
    this.isRequired = false,
    this.trailing,
    this.bottomSpacing = AppSpacing.md,
  });

  final String label;
  final Widget child;
  final bool isRequired;
  final Widget? trailing;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppFieldLabel(
            text: label,
            isRequired: isRequired,
            trailing: trailing,
          ),
          child,
        ],
      ),
    );
  }
}

/// Informational strip used at the foot of the form screens.
class AppHintBanner extends StatelessWidget {
  const AppHintBanner({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.palette.redWashSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.palette.redBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: context.palette.redWash,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: AppColors.red),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: context.type.cardTitle),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: context.type.caption.copyWith(
                    color: context.palette.slate,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
