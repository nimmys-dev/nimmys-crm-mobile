import 'dart:io';

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';

/// Square photo well with an overlaid edit affordance.
///
/// Shows the picked file once there is one, so the user can see what will be
/// uploaded as the `photo` part of Create Staff.
class StaffPhotoPicker extends StatelessWidget {
  const StaffPhotoPicker({
    super.key,
    this.onEdit,
    this.size = 108,
    this.imagePath,
  });

  final VoidCallback? onEdit;
  final double size;

  /// Absolute path of the picked image, or null while the well is empty.
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final bool hasPhoto = imagePath != null && imagePath!.isNotEmpty;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            width: size,
            height: size,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: context.palette.inkWash,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: hasPhoto ? context.palette.redBorder : context.palette.line,
              ),
            ),
            child: hasPhoto
                // A picked file can vanish before the form is saved — a cleared
                // camera cache, say — so the placeholder stays the fallback
                // rather than letting the tile throw.
                ? Image.file(
                    File(imagePath!),
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (BuildContext context, Object error, StackTrace? stack) =>
                            const StaffPhotoPlaceholder(),
                  )
                : const StaffPhotoPlaceholder(),
          ),
          Positioned(
            right: -6,
            bottom: -6,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onEdit,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: AppColors.actionGradient,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2.5),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 15,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state of [StaffPhotoPicker].
class StaffPhotoPlaceholder extends StatelessWidget {
  const StaffPhotoPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(Icons.person_rounded, size: 38, color: context.palette.faint),
        const SizedBox(height: 2),
        Text(
          'Add photo',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: context.palette.muted,
          ),
        ),
      ],
    );
  }
}

/// Inline validation message under a form field.
///
/// Collapses to nothing when [message] is null so the form does not jump on
/// every keystroke.
class StaffFieldError extends StatelessWidget {
  const StaffFieldError({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 2),
      child: Row(
        children: <Widget>[
          const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.red),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              message!,
              style: context.type.caption.copyWith(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }
}

/// Branch picker could not be filled: `GET /api/branches` failed, or came back
/// with nothing selectable. Both are dead ends for the form, so both offer a
/// retry rather than leaving the user tapping an inert field.
class StaffBranchLoadError extends StatelessWidget {
  const StaffBranchLoadError({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.error_outline_rounded,
              size: 14,
              color: AppColors.red,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              message,
              style: context.type.caption.copyWith(color: AppColors.red),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          InkWell(
            onTap: onRetry,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.refresh_rounded, size: 14, color: AppColors.red),
                  const SizedBox(width: 3),
                  Text('Retry', style: context.type.link.copyWith(fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small heading with an info dot, used above grouped sub-sections.
class StaffSubsectionTitle extends StatelessWidget {
  const StaffSubsectionTitle({
    super.key,
    required this.title,
    this.showInfo = false,
    this.onInfoTap,
  });

  final String title;
  final bool showInfo;
  final VoidCallback? onInfoTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          Text(title, style: context.type.label.copyWith(color: AppColors.red)),
          if (showInfo) ...<Widget>[
            const SizedBox(width: 5),
            InkWell(
              onTap: onInfoTap,
              customBorder: const CircleBorder(),
              child: Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: context.palette.muted,
              ),
            ),
          ],
          const Spacer(),
          Expanded(child: Divider(color: context.palette.line, thickness: 1)),
        ],
      ),
    );
  }
}

/// One salary revision in the increment history.
class IncrementRecord {
  const IncrementRecord({
    required this.effectiveDate,
    required this.salary,
    required this.incrementSalary,
    required this.remarks,
  });

  final String effectiveDate;
  final String salary;
  final String incrementSalary;
  final String remarks;
}

/// Table of past salary revisions.
class IncrementHistoryTable extends StatelessWidget {
  const IncrementHistoryTable({
    super.key,
    required this.records,
    this.onViewAll,
  });

  final List<IncrementRecord> records;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.palette.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          const IncrementHistoryHeader(),
          for (int index = 0; index < records.length; index++)
            IncrementHistoryRow(
              record: records[index],
              isLast: index == records.length - 1,
            ),
          Divider(height: 1, color: context.palette.line),
          InkWell(
            onTap: onViewAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('View All', style: context.type.link),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.red,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Column headings for [IncrementHistoryTable].
class IncrementHistoryHeader extends StatelessWidget {
  const IncrementHistoryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.palette.inkWash,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 9),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 32,
            child: Text('EFFECTIVE', style: cellStyle(context)),
          ),
          Expanded(flex: 24, child: Text('SALARY', style: cellStyle(context))),
          Expanded(flex: 22, child: Text('HIKE', style: cellStyle(context))),
          Expanded(flex: 30, child: Text('REMARKS', style: cellStyle(context))),
        ],
      ),
    );
  }

  /// Shared heading style, resolved against the active theme.
  static TextStyle cellStyle(BuildContext context) => TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w800,
    color: context.palette.slate,
    letterSpacing: 0.5,
  );
}

/// A single revision row.
class IncrementHistoryRow extends StatelessWidget {
  const IncrementHistoryRow({
    super.key,
    required this.record,
    required this.isLast,
  });

  final IncrementRecord record;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: context.palette.line)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 11,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 32,
            child: Text(
              record.effectiveDate,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.palette.ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 24,
            child: Text(
              record.salary,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.palette.ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 22,
            child: Text(
              '+${record.incrementSalary}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.red,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 30,
            child: Text(
              record.remarks,
              style: context.type.caption.copyWith(fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
