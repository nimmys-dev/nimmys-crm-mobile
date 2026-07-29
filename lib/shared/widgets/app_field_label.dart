import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';

/// Form field caption with the red required asterisk used across all forms.
class AppFieldLabel extends StatelessWidget {
  const AppFieldLabel({
    super.key,
    required this.text,
    this.isRequired = false,
    this.trailing,
  });

  final String text;
  final bool isRequired;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          Flexible(
            child: Text(
              text,
              style: context.type.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isRequired)
            const Padding(
              padding: EdgeInsets.only(left: 3),
              child: Text(
                '*',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.red,
                ),
              ),
            ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}
