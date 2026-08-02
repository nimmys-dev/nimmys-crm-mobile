import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_field_label.dart';
import '../../../shared/widgets/app_form_field.dart';
import '../../../shared/widgets/app_select_field.dart';
import '../domain/entities/task_schedule.dart';

/// The schedule inputs for the selected frequency, and nothing else.
///
/// Each frequency asks for something different — a time range, weekly days,
/// monthly days, or quarters with a date range under each — so this switches
/// on [TaskSchedule.frequency] and renders only that branch. No frequency
/// shows a start/end date: the screen's own date card is limited to yearly
/// tasks for the same reason.
///
/// The screen keeps one [TaskSchedule] and gets a new one back through
/// [onChanged]; nothing here holds selection state of its own.
class TaskScheduleFields extends StatelessWidget {
  const TaskScheduleFields({
    super.key,
    required this.schedule,
    required this.onChanged,
    this.errorText,
  });

  final TaskSchedule schedule;
  final ValueChanged<TaskSchedule> onChanged;

  /// Shown under the inputs after a failed save attempt.
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        switch (schedule.frequency) {
          TaskFrequency.daily => _DailyFields(
            schedule: schedule,
            onChanged: onChanged,
          ),
          TaskFrequency.weekly => _WeekdayFields(
            schedule: schedule,
            onChanged: onChanged,
          ),
          TaskFrequency.monthly => _MonthlyFields(
            schedule: schedule,
            onChanged: onChanged,
          ),
          TaskFrequency.quarterly => _QuarterFields(
            schedule: schedule,
            onChanged: onChanged,
          ),
          // Yearly asks for nothing here: its whole schedule is the start and
          // due date the screen shows in its own card.
          TaskFrequency.yearly => const SizedBox.shrink(),
        },
        if (errorText != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          TaskScheduleError(message: errorText!),
        ],
      ],
    );
  }
}

/// Daily runs between two times of day — no dates involved.
class _DailyFields extends StatelessWidget {
  const _DailyFields({required this.schedule, required this.onChanged});

  final TaskSchedule schedule;
  final ValueChanged<TaskSchedule> onChanged;

  static TimeOfDay? _time(int? minutes) => minutes == null
      ? null
      : TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: AppFormField(
                label: 'Start Time',
                isRequired: true,
                bottomSpacing: 0,
                child: AppTimeField(
                  hint: 'e.g. 10:00 AM',
                  value: _time(schedule.startTimeMinutes),
                  onChanged: (TimeOfDay value) => onChanged(
                    schedule.copyWith(
                      startTimeMinutes: value.hour * 60 + value.minute,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppFormField(
                label: 'End Time',
                isRequired: true,
                bottomSpacing: 0,
                child: AppTimeField(
                  hint: 'e.g. 12:00 PM',
                  value: _time(schedule.endTimeMinutes),
                  onChanged: (TimeOfDay value) => onChanged(
                    schedule.copyWith(
                      endTimeMinutes: value.hour * 60 + value.minute,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        const TaskScheduleCaption(
          text: 'The task runs between these times every day.',
        ),
      ],
    );
  }
}

/// Weekly picks days of the week — no dates, per the schedule rules.
class _WeekdayFields extends StatelessWidget {
  const _WeekdayFields({required this.schedule, required this.onChanged});

  final TaskSchedule schedule;
  final ValueChanged<TaskSchedule> onChanged;

  @override
  Widget build(BuildContext context) {
    return TaskWeekdayPicker(
      label: 'Repeat On',
      selected: schedule.weekdays,
      onToggle: (int weekday) => onChanged(schedule.toggleWeekday(weekday)),
      emptyCaption:
          'Pick one or more days. The task repeats every week on those days.',
      filledCaption: (String days) => 'Repeats every week on $days.',
    );
  }
}

/// Monthly runs on chosen dates of the month, inside a start/end window.
class _MonthlyFields extends StatelessWidget {
  const _MonthlyFields({required this.schedule, required this.onChanged});

  final TaskSchedule schedule;
  final ValueChanged<TaskSchedule> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TaskDateRangeFields(
          range: schedule.monthlyRange,
          endLabel: 'End Date',
          onChanged: (TaskDateRange range) =>
              onChanged(schedule.copyWith(monthlyRange: range)),
        ),
        const SizedBox(height: AppSpacing.md),
        const AppFieldLabel(text: 'Repeat On', isRequired: true),
        TaskMonthDayBox(
          selected: schedule.monthDays,
          onToggle: (int day) => onChanged(schedule.toggleMonthDay(day)),
        ),
        const SizedBox(height: AppSpacing.xs),
        TaskScheduleCaption(
          text: schedule.monthDays.isEmpty
              ? 'Pick one or more dates. The task repeats every month on those dates.'
              : 'Repeats every month on ${_ordinalList(schedule.monthDays)}.',
        ),
      ],
    );
  }

  static String _ordinalList(Set<int> days) =>
      (days.toList()..sort()).map(_ordinal).join(', ');

  /// 1 → "1st", 22 → "22nd". The teens are the exception every list of
  /// ordinals gets wrong.
  static String _ordinal(int day) {
    if (day >= 11 && day <= 13) {
      return '${day}th';
    }
    return switch (day % 10) {
      1 => '${day}st',
      2 => '${day}nd',
      3 => '${day}rd',
      _ => '${day}th',
    };
  }
}

/// Quarterly picks quarters, then a date range inside each selected quarter.
class _QuarterFields extends StatelessWidget {
  const _QuarterFields({required this.schedule, required this.onChanged});

  final TaskSchedule schedule;
  final ValueChanged<TaskSchedule> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AppFieldLabel(text: 'Quarters', isRequired: true),
        for (final TaskQuarter quarter in TaskQuarter.values) ...<Widget>[
          TaskQuarterTile(
            key: ValueKey<TaskQuarter>(quarter),
            quarter: quarter,
            isSelected: schedule.quarterRanges.containsKey(quarter),
            range: schedule.rangeFor(quarter),
            onTap: () => onChanged(schedule.toggleQuarter(quarter)),
          ),
          // The range belongs to its quarter, so it sits directly under the
          // tile that opened it.
          if (schedule.quarterRanges.containsKey(quarter))
            QuarterRangePicker(
              key: ValueKey<String>('range-${quarter.wireValue}'),
              quarter: quarter,
              range: schedule.rangeFor(quarter),
              onChanged: (TaskDateRange range) =>
                  onChanged(schedule.setQuarterRange(quarter, range)),
              onClear: () => onChanged(schedule.clearQuarterRange(quarter)),
            ),
          const SizedBox(height: AppSpacing.xs),
        ],
        TaskScheduleCaption(
          text: schedule.selectedQuarters.isEmpty
              ? 'Select one or more quarters, then set a date range inside each one.'
              : 'Set a from and to date for every selected quarter.',
        ),
      ],
    );
  }
}

/// A start/end date pair, used by every frequency that has a window.
///
/// The two calendars police the order between them: the end cannot open
/// before the start, and moving the start past the end drops the end rather
/// than leaving the pair reversed.
class TaskDateRangeFields extends StatelessWidget {
  const TaskDateRangeFields({
    super.key,
    required this.range,
    required this.onChanged,
    this.startLabel = 'Start Date',
    this.endLabel = 'End Date',
    this.firstDate,
    this.lastDate,
  });

  final TaskDateRange range;
  final ValueChanged<TaskDateRange> onChanged;
  final String startLabel;
  final String endLabel;

  /// Bounds passed to both calendars — a quarter's window, say. Null leaves
  /// [AppDateField]'s default five-year span.
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: AppFormField(
            label: startLabel,
            isRequired: true,
            bottomSpacing: 0,
            child: AppDateField(
              hint: 'Select start date',
              value: range.from,
              firstDate: firstDate,
              lastDate: lastDate,
              onChanged: (DateTime value) => onChanged(
                range.to != null && range.to!.isBefore(value)
                    ? TaskDateRange(from: value)
                    : range.copyWith(from: value),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: AppFormField(
            label: endLabel,
            isRequired: true,
            bottomSpacing: 0,
            child: AppDateField(
              hint: 'Select ${endLabel.toLowerCase()}',
              value: range.to,
              firstDate: range.from ?? firstDate,
              lastDate: lastDate,
              onChanged: (DateTime value) =>
                  onChanged(range.copyWith(to: value)),
            ),
          ),
        ),
      ],
    );
  }
}

/// The 1–30 date box a monthly task repeats on.
class TaskMonthDayBox extends StatelessWidget {
  const TaskMonthDayBox({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  final Set<int> selected;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: context.palette.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.palette.line),
      ),
      child: Wrap(
        spacing: AppSpacing.xxs,
        runSpacing: AppSpacing.xxs,
        children: <Widget>[
          for (final int day in kMonthDayValues)
            TaskChoiceChip(
              label: '$day',
              isSelected: selected.contains(day),
              minWidth: 38,
              onTap: () => onToggle(day),
            ),
        ],
      ),
    );
  }
}

/// SUN–SAT chip row, shared by the weekly and monthly frequencies.
class TaskWeekdayPicker extends StatelessWidget {
  const TaskWeekdayPicker({
    super.key,
    required this.label,
    required this.selected,
    required this.onToggle,
    required this.emptyCaption,
    required this.filledCaption,
  });

  final String label;
  final Set<int> selected;
  final ValueChanged<int> onToggle;

  final String emptyCaption;

  /// Built with the selected day names, already joined and in display order.
  final String Function(String days) filledCaption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppFieldLabel(text: label, isRequired: true),
        Wrap(
          spacing: AppSpacing.xxs,
          runSpacing: AppSpacing.xxs,
          children: <Widget>[
            for (final int weekday in kWeekdayOrder)
              TaskChoiceChip(
                label: weekdayShortName(weekday),
                isSelected: selected.contains(weekday),
                minWidth: 44,
                onTap: () => onToggle(weekday),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        TaskScheduleCaption(
          text: selected.isEmpty
              ? emptyCaption
              : filledCaption(_selectedDayNames(selected)),
        ),
      ],
    );
  }

  /// "Monday, Thursday" in display order rather than tap order.
  static String _selectedDayNames(Set<int> weekdays) =>
      kWeekdayOrder.where(weekdays.contains).map(weekdayName).join(', ');
}

/// One quarter, tappable, with the months it covers.
class TaskQuarterTile extends StatelessWidget {
  const TaskQuarterTile({
    super.key,
    required this.quarter,
    required this.isSelected,
    required this.range,
    this.onTap,
  });

  final TaskQuarter quarter;
  final bool isSelected;

  /// Shown as a badge once both ends are set.
  final TaskDateRange range;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? context.palette.redWashSoft
              : context.palette.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected
                ? context.palette.redBorder
                : context.palette.line,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 19,
              color: isSelected ? AppColors.red : context.palette.faint,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    quarter.label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: context.palette.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    quarter.monthsLabel,
                    style: context.type.caption.copyWith(
                      color: context.palette.slate,
                    ),
                  ),
                ],
              ),
            ),
            if (range.isComplete)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: context.palette.redWash,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '${AppDateField.format(range.from!)} → '
                  '${AppDateField.format(range.to!)}',
                  style: context.type.link.copyWith(fontSize: 10.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// From/to date range for one quarter, with a clear action.
///
/// Both calendars are bounded by the quarter's own months, so a date outside
/// it cannot be picked in the first place; `to` additionally cannot open
/// before `from`.
class QuarterRangePicker extends StatelessWidget {
  const QuarterRangePicker({
    super.key,
    required this.quarter,
    required this.range,
    required this.onChanged,
    required this.onClear,
  });

  final TaskQuarter quarter;
  final TaskDateRange range;
  final ValueChanged<TaskDateRange> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final DateTime windowStart = quarter.firstDay();
    final DateTime windowEnd = quarter.lastDay();

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.palette.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Date range in ${quarter.monthsLabel}',
                  style: context.type.caption,
                ),
              ),
              if (!range.isEmpty)
                TaskClearButton(label: 'Clear', onPressed: onClear),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          TaskDateRangeFields(
            range: range,
            startLabel: 'From Date',
            endLabel: 'To Date',
            firstDate: windowStart,
            lastDate: windowEnd,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Small text action that empties a selection.
class TaskClearButton extends StatelessWidget {
  const TaskClearButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.close_rounded, size: 13, color: AppColors.red),
            const SizedBox(width: 3),
            Text(label, style: context.type.link.copyWith(fontSize: 11.5)),
          ],
        ),
      ),
    );
  }
}

/// Pill toggle used for weekdays and quarters.
class TaskChoiceChip extends StatelessWidget {
  const TaskChoiceChip({
    super.key,
    required this.label,
    required this.isSelected,
    this.onTap,
    this.minWidth = 0,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        constraints: BoxConstraints(minWidth: minWidth),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.actionGradient : null,
          color: isSelected ? null : context.palette.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isSelected ? Colors.transparent : context.palette.line,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? AppColors.white : context.palette.slate,
          ),
        ),
      ),
    );
  }
}

/// Explanatory line under a schedule input.
class TaskScheduleCaption extends StatelessWidget {
  const TaskScheduleCaption({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: context.type.caption);
  }
}

/// Inline validation message for an incomplete schedule.
class TaskScheduleError extends StatelessWidget {
  const TaskScheduleError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Icon(Icons.error_outline_rounded, size: 15, color: AppColors.red),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: context.type.caption.copyWith(
              color: AppColors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
