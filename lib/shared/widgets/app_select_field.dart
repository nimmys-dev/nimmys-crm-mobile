import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';

/// Tap-to-choose field rendered to match [AppTextField] exactly.
///
/// Presents its options in a branded bottom sheet rather than a raw dropdown so
/// long employee/approver lists stay comfortable on small screens.
class AppSelectField extends StatelessWidget {
  const AppSelectField({
    super.key,
    required this.hint,
    required this.options,
    this.value,
    this.onChanged,
    this.icon,
    this.sheetTitle,
  });

  final String hint;
  final List<String> options;
  final String? value;
  final ValueChanged<String>? onChanged;
  final IconData? icon;
  final String? sheetTitle;

  Future<void> _openPicker(BuildContext context) async {
    final String? picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return AppSelectSheet(
          title: sheetTitle ?? hint,
          options: options,
          selected: value,
        );
      },
    );
    if (picked != null) {
      onChanged?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value != null && value!.isNotEmpty;

    return InkWell(
      onTap: onChanged == null ? null : () => _openPicker(context),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: context.palette.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: hasValue ? context.palette.redBorder : context.palette.line,
          ),
        ),
        child: Row(
          children: <Widget>[
            if (icon != null)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: Icon(
                  icon,
                  size: 19,
                  color: hasValue ? AppColors.red : context.palette.faint,
                ),
              ),
            Expanded(
              child: Text(
                hasValue ? value! : hint,
                style: hasValue ? context.type.input : context.type.hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 22,
              color: context.palette.muted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet listing the choices for an [AppSelectField].
class AppSelectSheet extends StatelessWidget {
  const AppSelectSheet({
    super.key,
    required this.title,
    required this.options,
    this.selected,
  });

  final String title;
  final List<String> options;
  final String? selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.62,
      ),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const AppSheetGrabber(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Row(
              children: <Widget>[
                Expanded(child: Text(title, style: context.type.cardTitle)),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: context.palette.muted,
                  splashRadius: 20,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.palette.line),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              itemCount: options.length,
              separatorBuilder: (BuildContext context, int index) => Divider(
                height: 1,
                indent: AppSpacing.lg,
                endIndent: AppSpacing.lg,
                color: context.palette.line,
              ),
              itemBuilder: (BuildContext context, int index) {
                final String option = options[index];
                return AppSelectSheetTile(
                  label: option,
                  isSelected: option == selected,
                  onTap: () => Navigator.of(context).pop(option),
                );
              },
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom + AppSpacing.xs,
          ),
        ],
      ),
    );
  }
}

/// A single selectable row inside [AppSelectSheet].
class AppSelectSheetTile extends StatelessWidget {
  const AppSelectSheetTile({
    super.key,
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: context.type.body.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.red : context.palette.ink,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: AppColors.red,
              ),
          ],
        ),
      ),
    );
  }
}

/// The small pill at the top of a modal sheet.
class AppSheetGrabber extends StatelessWidget {
  const AppSheetGrabber({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 4,
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.palette.inkBorder,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );
  }
}

/// Read-only field that opens the native date picker.
class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    required this.hint,
    this.value,
    this.onChanged,
    this.icon = Icons.calendar_today_rounded,
  });

  final String hint;
  final DateTime? value;
  final ValueChanged<DateTime>? onChanged;
  final IconData icon;

  static const List<String> _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String format(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')} ${_months[date.month - 1]} ${date.year}';

  Future<void> _pickDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.red,
              onPrimary: AppColors.white,
              onSurface: context.palette.ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onChanged?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value != null;

    return InkWell(
      onTap: onChanged == null ? null : () => _pickDate(context),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: context.palette.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: hasValue ? context.palette.redBorder : context.palette.line,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              icon,
              size: 18,
              color: hasValue ? AppColors.red : context.palette.faint,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                hasValue ? format(value!) : hint,
                style: hasValue ? context.type.input : context.type.hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
