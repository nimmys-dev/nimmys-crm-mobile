import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import '../../../oldLib/features/duties/domain/entities/task_schedule.dart';

/// Covers the two promises the Create Task form makes about a recurrence:
/// an incomplete one cannot be saved, and a complete one survives the trip
/// through JSON that an edit screen makes.
void main() {
  // A fixed "today" inside business year 2026-27, so the quarter windows the
  // tests assert on do not move with the calendar.
  final DateTime today = DateTime(2026, 8, 2);

  group('validation', () {
    test('daily needs both ends of the time range', () {
      const TaskSchedule empty = TaskSchedule();
      expect(empty.isComplete, isFalse);
      expect(
        empty.copyWith(startTimeMinutes: 10 * 60).isComplete,
        isFalse,
        reason: 'start alone is half a range',
      );
      expect(
        empty
            .copyWith(startTimeMinutes: 10 * 60, endTimeMinutes: 12 * 60)
            .isComplete,
        isTrue,
      );
    });

    test('daily rejects an end time at or before the start', () {
      const TaskSchedule schedule = TaskSchedule(
        startTimeMinutes: 12 * 60,
        endTimeMinutes: 10 * 60,
      );
      expect(schedule.validationError, contains('after the start time'));
      expect(
        schedule.copyWith(endTimeMinutes: 12 * 60).validationError,
        contains('after the start time'),
        reason: 'a zero-length range is not a range',
      );
    });

    test('weekly needs days, and nothing else', () {
      const TaskSchedule weekly = TaskSchedule(frequency: TaskFrequency.weekly);
      expect(weekly.validationError, 'Select at least one day of the week.');
      expect(
        weekly.toggleWeekday(DateTime.monday).isComplete,
        isTrue,
        reason: 'weekly carries no date window',
      );
      // Toggling the only day back off makes it incomplete again.
      expect(
        weekly
            .toggleWeekday(DateTime.monday)
            .toggleWeekday(DateTime.monday)
            .isComplete,
        isFalse,
      );
    });

    test('monthly needs a window and at least one date', () {
      final TaskSchedule monthly =
          const TaskSchedule(frequency: TaskFrequency.monthly).copyWith(
            monthlyRange: TaskDateRange(
              from: DateTime(2026, 8, 1),
              to: DateTime(2026, 12, 31),
            ),
          );
      expect(
        monthly.validationError,
        'Select at least one date between 1 and 30.',
      );
      expect(monthly.toggleMonthDay(15).isComplete, isTrue);

      // The window is required too.
      expect(
        const TaskSchedule(
          frequency: TaskFrequency.monthly,
        ).toggleMonthDay(15).validationError,
        'Select a start date and end date.',
      );
    });

    test('monthly stops at the 30th', () {
      const TaskSchedule monthly = TaskSchedule(
        frequency: TaskFrequency.monthly,
      );
      expect(kMonthDayValues.last, 30);
      expect(
        monthly.toggleMonthDay(31).monthDays,
        isEmpty,
        reason: '31 would skip five months a year, so it is not offered',
      );
      expect(monthly.toggleMonthDay(0).monthDays, isEmpty);
      expect(monthly.toggleMonthDay(30).monthDays, <int>{30});
    });

    test('monthly and yearly keep their own windows', () {
      final TaskSchedule schedule = const TaskSchedule().copyWith(
        monthlyRange: TaskDateRange(from: DateTime(2026, 9, 1)),
        yearlyRange: TaskDateRange(from: DateTime(2026, 4, 1)),
      );
      expect(schedule.monthlyRange.from, DateTime(2026, 9, 1));
      expect(schedule.yearlyRange.from, DateTime(2026, 4, 1));
    });

    test('quarterly needs a complete range in every selected quarter', () {
      const TaskSchedule quarterly = TaskSchedule(
        frequency: TaskFrequency.quarterly,
      );
      expect(quarterly.validationError, 'Select at least one quarter.');

      final TaskSchedule oneQuarter = quarterly.toggleQuarter(
        TaskQuarter.first,
      );
      expect(oneQuarter.isComplete, isFalse, reason: 'quarter has no range');
      expect(oneQuarter.validationError, contains('1st Quarter'));

      // Half a range is still not a range — nothing fills the other end in.
      final TaskSchedule halfFilled = oneQuarter.setQuarterRange(
        TaskQuarter.first,
        TaskDateRange(from: DateTime(2026, 4, 10)),
        reference: today,
      );
      expect(halfFilled.isComplete, isFalse);
      expect(halfFilled.rangeFor(TaskQuarter.first).to, isNull);

      final TaskSchedule filled = halfFilled.setQuarterRange(
        TaskQuarter.first,
        TaskDateRange(from: DateTime(2026, 4, 10), to: DateTime(2026, 6, 20)),
        reference: today,
      );
      expect(filled.isComplete, isTrue);

      // A second quarter added later is incomplete until it has its own range.
      final TaskSchedule twoQuarters = filled.toggleQuarter(TaskQuarter.third);
      expect(twoQuarters.isComplete, isFalse);
      expect(twoQuarters.validationError, contains('3rd Quarter'));
      expect(
        twoQuarters
            .setQuarterRange(
              TaskQuarter.third,
              TaskDateRange(
                from: DateTime(2026, 10, 1),
                to: DateTime(2026, 12, 31),
              ),
              reference: today,
            )
            .isComplete,
        isTrue,
      );
    });

    test('quarterly rejects a range set the wrong way round', () {
      final TaskSchedule schedule =
          const TaskSchedule(frequency: TaskFrequency.quarterly)
              .toggleQuarter(TaskQuarter.second)
              .setQuarterRange(
                TaskQuarter.second,
                TaskDateRange(
                  from: DateTime(2026, 9, 10),
                  to: DateTime(2026, 7, 1),
                ),
                reference: today,
              );
      expect(schedule.validationError, contains('on or after the from date'));
    });

    test('yearly needs a start date and a due date', () {
      const TaskSchedule yearly = TaskSchedule(frequency: TaskFrequency.yearly);
      expect(yearly.validationError, 'Select a start date and due date.');
      expect(
        yearly
            .copyWith(yearlyRange: TaskDateRange(from: DateTime(2026, 4, 1)))
            .isComplete,
        isFalse,
        reason: 'a start alone is half a window',
      );
      expect(
        yearly
            .copyWith(
              yearlyRange: TaskDateRange(
                from: DateTime(2026, 4, 1),
                to: DateTime(2026, 4, 30),
              ),
            )
            .isComplete,
        isTrue,
      );
    });

    test('yearly rejects a due date before the start date', () {
      final TaskSchedule schedule =
          const TaskSchedule(frequency: TaskFrequency.yearly).copyWith(
            yearlyRange: TaskDateRange(
              from: DateTime(2026, 4, 30),
              to: DateTime(2026, 4, 1),
            ),
          );
      expect(
        schedule.validationError,
        'The due date must be on or after the start date.',
      );
    });
  });

  group('quarter windows', () {
    test('the business year runs April to March', () {
      expect(TaskQuarter.first.firstDay(reference: today), DateTime(2026, 4));
      expect(
        TaskQuarter.first.lastDay(reference: today),
        DateTime(2026, 6, 30),
      );
      // Jan–Mar belongs to the next calendar year from the April quarter.
      expect(TaskQuarter.fourth.firstDay(reference: today), DateTime(2027));
      expect(
        TaskQuarter.fourth.lastDay(reference: today),
        DateTime(2027, 3, 31),
      );
    });

    test('a date before April sits in the previous business year', () {
      final DateTime february = DateTime(2026, 2, 14);
      expect(
        TaskQuarter.first.firstDay(reference: february),
        DateTime(2025, 4),
      );
      expect(
        TaskQuarter.fourth.firstDay(reference: february),
        DateTime(2026),
        reason: 'February is inside the current fourth quarter',
      );
    });

    test('a date outside the quarter is refused', () {
      final TaskSchedule schedule =
          const TaskSchedule(frequency: TaskFrequency.quarterly)
              .toggleQuarter(TaskQuarter.first)
              // October is not in April–June.
              .setQuarterRange(
                TaskQuarter.first,
                TaskDateRange(from: DateTime(2026, 10, 3)),
                reference: today,
              );
      expect(schedule.rangeFor(TaskQuarter.first).isEmpty, isTrue);
    });

    test('a range cannot be set on a quarter that is not selected', () {
      final TaskSchedule schedule =
          const TaskSchedule(
            frequency: TaskFrequency.quarterly,
          ).setQuarterRange(
            TaskQuarter.first,
            TaskDateRange(from: DateTime(2026, 4, 1)),
            reference: today,
          );
      expect(schedule.selectedQuarters, isEmpty);
    });

    test('clearing a range keeps the quarter selected', () {
      final TaskSchedule schedule =
          const TaskSchedule(frequency: TaskFrequency.quarterly)
              .toggleQuarter(TaskQuarter.second)
              .setQuarterRange(
                TaskQuarter.second,
                TaskDateRange(
                  from: DateTime(2026, 7, 1),
                  to: DateTime(2026, 9, 30),
                ),
                reference: today,
              );

      final TaskSchedule cleared = schedule.clearQuarterRange(
        TaskQuarter.second,
      );
      expect(cleared.selectedQuarters, <TaskQuarter>[TaskQuarter.second]);
      expect(cleared.rangeFor(TaskQuarter.second).isEmpty, isTrue);
      expect(cleared.isComplete, isFalse);

      // Unticking the quarter drops it altogether.
      expect(
        schedule.toggleQuarter(TaskQuarter.second).selectedQuarters,
        isEmpty,
      );
    });
  });

  group('save and restore', () {
    /// Round-trips through a real encode/decode, the way a saved task comes
    /// back from an API or from storage.
    TaskSchedule roundTrip(TaskSchedule schedule) => TaskSchedule.fromJson(
      jsonDecode(jsonEncode(schedule.toJson())) as Map<String, dynamic>,
    );

    test('daily keeps both times', () {
      const TaskSchedule schedule = TaskSchedule(
        startTimeMinutes: 10 * 60,
        endTimeMinutes: 12 * 60,
      );
      expect(roundTrip(schedule), schedule);
    });

    test('weekly keeps its days', () {
      final TaskSchedule schedule = const TaskSchedule(
        frequency: TaskFrequency.weekly,
      ).toggleWeekday(DateTime.sunday).toggleWeekday(DateTime.wednesday);

      final TaskSchedule restored = roundTrip(schedule);
      expect(restored.weekdays, <int>{DateTime.sunday, DateTime.wednesday});
      expect(restored, schedule);
    });

    test('monthly keeps its window and dates', () {
      final TaskSchedule schedule = TaskSchedule(
        frequency: TaskFrequency.monthly,
        monthlyRange: TaskDateRange(
          from: DateTime(2026, 8, 1),
          to: DateTime(2026, 12, 31),
        ),
      ).toggleMonthDay(1).toggleMonthDay(30);

      final TaskSchedule restored = roundTrip(schedule);
      expect(restored.monthDays, <int>{1, 30});
      expect(restored.monthlyRange, schedule.monthlyRange);
    });

    test('quarterly keeps every quarter and its range', () {
      final TaskSchedule schedule =
          const TaskSchedule(frequency: TaskFrequency.quarterly)
              .toggleQuarter(TaskQuarter.first)
              .setQuarterRange(
                TaskQuarter.first,
                TaskDateRange(
                  from: DateTime(2026, 4, 15),
                  to: DateTime(2026, 5, 15),
                ),
                reference: today,
              )
              .toggleQuarter(TaskQuarter.fourth)
              .setQuarterRange(
                TaskQuarter.fourth,
                TaskDateRange(
                  from: DateTime(2027, 1, 31),
                  to: DateTime(2027, 3, 2),
                ),
                reference: today,
              );

      final TaskSchedule restored = roundTrip(schedule);
      expect(restored.selectedQuarters, <TaskQuarter>[
        TaskQuarter.first,
        TaskQuarter.fourth,
      ]);
      expect(
        restored.rangeFor(TaskQuarter.first),
        TaskDateRange(from: DateTime(2026, 4, 15), to: DateTime(2026, 5, 15)),
      );
      expect(
        restored.rangeFor(TaskQuarter.fourth),
        TaskDateRange(from: DateTime(2027, 1, 31), to: DateTime(2027, 3, 2)),
      );
    });

    test('a quarter picked but left empty comes back still selected', () {
      final TaskSchedule schedule = const TaskSchedule(
        frequency: TaskFrequency.quarterly,
      ).toggleQuarter(TaskQuarter.third);
      final TaskSchedule restored = roundTrip(schedule);
      expect(restored.selectedQuarters, <TaskQuarter>[TaskQuarter.third]);
      expect(restored.rangeFor(TaskQuarter.third).isEmpty, isTrue);
      expect(restored.isComplete, isFalse);
    });

    test('yearly keeps its start and due dates', () {
      final TaskSchedule schedule =
          const TaskSchedule(frequency: TaskFrequency.yearly).copyWith(
            yearlyRange: TaskDateRange(
              from: DateTime(2026, 4, 1),
              to: DateTime(2026, 4, 30),
            ),
          );
      final Map<String, dynamic> json = schedule.toJson();
      expect(json.containsKey('start_date'), isTrue);
      expect(json.containsKey('due_date'), isTrue);
      expect(roundTrip(schedule).yearlyRange, schedule.yearlyRange);
    });

    test('only the selected frequency is sent', () {
      final TaskSchedule schedule = TaskSchedule(
        frequency: TaskFrequency.weekly,
        startTimeMinutes: 600,
        endTimeMinutes: 720,
        yearlyRange: TaskDateRange(from: DateTime(2026, 4, 1)),
      ).toggleWeekday(DateTime.friday).toggleMonthDay(9);
      final Map<String, dynamic> json = schedule.toJson();
      expect(json['weekdays'], <int>[DateTime.friday]);
      expect(json.containsKey('start_time_minutes'), isFalse);
      expect(json.containsKey('end_time_minutes'), isFalse);
      expect(json.containsKey('month_days'), isFalse);
      expect(json.containsKey('quarters'), isFalse);
      expect(json.containsKey('start_date'), isFalse);
    });

    test('repeat mode is on by default and survives the round trip', () {
      const TaskSchedule schedule = TaskSchedule();
      expect(schedule.repeat, isTrue);
      expect(roundTrip(schedule.copyWith(repeat: false)).repeat, isFalse);
      // A task saved before the toggle existed was, by definition, recurring.
      expect(
        TaskSchedule.fromJson(<String, dynamic>{'frequency': 'weekly'}).repeat,
        isTrue,
      );
    });

    test('a one-off task needs no schedule and sends none', () {
      final TaskSchedule schedule = const TaskSchedule(
        frequency: TaskFrequency.quarterly,
      ).copyWith(repeat: false);
      expect(
        schedule.isComplete,
        isTrue,
        reason: 'nothing is required once the task does not repeat',
      );

      final Map<String, dynamic> json = schedule.toJson();
      expect(json['repeat'], isFalse);
      expect(json.containsKey('quarters'), isFalse);
      expect(json.containsKey('weekdays'), isFalse);
    });

    test('an unknown frequency falls back to daily instead of throwing', () {
      final TaskSchedule restored = TaskSchedule.fromJson(<String, dynamic>{
        'frequency': 'fortnightly',
      });
      expect(restored.frequency, TaskFrequency.daily);
      expect(restored.isComplete, isFalse);
    });
  });
}
