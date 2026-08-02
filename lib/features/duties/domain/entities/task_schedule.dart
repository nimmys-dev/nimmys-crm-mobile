import 'package:equatable/equatable.dart';

/// How often a recurring task repeats.
///
/// The frequency decides which schedule inputs the form shows, so it is an
/// enum rather than a tab index: a `switch` on it is checked for
/// completeness, and [wireValue] is the only place the server spelling lives.
enum TaskFrequency {
  daily('daily', 'Daily'),
  weekly('weekly', 'Weekly'),
  monthly('monthly', 'Monthly'),
  quarterly('quarterly', 'Quarterly'),
  yearly('yearly', 'Yearly');

  const TaskFrequency(this.wireValue, this.label);

  /// What the API sends and expects.
  final String wireValue;

  /// What the user reads.
  final String label;

  /// Maps an API string to a frequency, defaulting to [daily] so an
  /// unrecognised value does not crash an edit screen.
  static TaskFrequency fromWire(String? value) {
    if (value == null) {
      return TaskFrequency.daily;
    }
    final String normalised = value.toLowerCase().trim();
    for (final TaskFrequency frequency in TaskFrequency.values) {
      if (frequency.wireValue == normalised) {
        return frequency;
      }
    }
    return TaskFrequency.daily;
  }

  /// The segmented-tab options, in declaration order.
  static List<String> get labels =>
      TaskFrequency.values.map((TaskFrequency f) => f.label).toList();
}

/// The four business quarters, starting in April.
///
/// [months] is what bounds the date range picked under a quarter: a range
/// chosen for [first] can only run inside April–June.
enum TaskQuarter {
  first('q1', '1st Quarter', <int>[4, 5, 6]),
  second('q2', '2nd Quarter', <int>[7, 8, 9]),
  third('q3', '3rd Quarter', <int>[10, 11, 12]),
  fourth('q4', '4th Quarter', <int>[1, 2, 3]);

  const TaskQuarter(this.wireValue, this.label, this.months);

  final String wireValue;
  final String label;

  /// Calendar month numbers (1–12) this quarter covers.
  final List<int> months;

  /// "April, May, June" — the caption under the quarter's name.
  String get monthsLabel => months.map(monthName).join(', ');

  /// First selectable day of this quarter, in the business year containing
  /// [reference].
  DateTime firstDay({DateTime? reference}) =>
      DateTime(_calendarYear(reference ?? DateTime.now()), months.first);

  /// Last selectable day of this quarter. Day 0 of the following month is the
  /// last day of this one, which gets February right in a leap year.
  DateTime lastDay({DateTime? reference}) =>
      DateTime(_calendarYear(reference ?? DateTime.now()), months.last + 1, 0);

  /// True when [date] falls inside this quarter's window.
  bool contains(DateTime date, {DateTime? reference}) {
    final DateTime start = firstDay(reference: reference);
    final DateTime end = lastDay(reference: reference);
    return !date.isBefore(start) && !date.isAfter(end);
  }

  /// The calendar year this quarter's months sit in. The business year runs
  /// April–March, so the January–March quarter lands in the *next* calendar
  /// year from the one the April quarter starts in.
  int _calendarYear(DateTime reference) {
    final int businessYearStart = reference.month >= 4
        ? reference.year
        : reference.year - 1;
    return months.first >= 4 ? businessYearStart : businessYearStart + 1;
  }

  static TaskQuarter? fromWire(String? value) {
    if (value == null) {
      return null;
    }
    final String normalised = value.toLowerCase().trim();
    for (final TaskQuarter quarter in TaskQuarter.values) {
      if (quarter.wireValue == normalised) {
        return quarter;
      }
    }
    return null;
  }
}

/// Full month names, indexed by month number − 1.
const List<String> kMonthNames = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// "April" for 4.
String monthName(int month) => kMonthNames[month - 1];

/// Weekday numbers in the order the day picker shows them.
///
/// Values match `DateTime.monday`–`DateTime.sunday`, so they can be compared
/// against `someDate.weekday` directly.
const List<int> kWeekdayOrder = <int>[
  DateTime.sunday,
  DateTime.monday,
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
  DateTime.friday,
  DateTime.saturday,
];

const Map<int, String> _weekdayNames = <int, String>{
  DateTime.monday: 'Monday',
  DateTime.tuesday: 'Tuesday',
  DateTime.wednesday: 'Wednesday',
  DateTime.thursday: 'Thursday',
  DateTime.friday: 'Friday',
  DateTime.saturday: 'Saturday',
  DateTime.sunday: 'Sunday',
};

/// "Monday" for `DateTime.monday`.
String weekdayName(int weekday) => _weekdayNames[weekday]!;

/// "MON" for `DateTime.monday` — the chip caption.
String weekdayShortName(int weekday) =>
    weekdayName(weekday).substring(0, 3).toUpperCase();

/// A from/to pair, either half of which may still be unset.
///
/// Both nullable because the user fills one field at a time, and a quarter
/// with a half-finished range must be rejected on save rather than silently
/// completed — nothing here ever guesses the missing date.
class TaskDateRange extends Equatable {
  const TaskDateRange({this.from, this.to});

  factory TaskDateRange.fromJson(Map<String, dynamic> json) =>
      TaskDateRange(from: _date(json['from']), to: _date(json['to']));

  final DateTime? from;
  final DateTime? to;

  bool get isEmpty => from == null && to == null;

  /// Both ends set, and in the right order.
  bool get isComplete => from != null && to != null && !to!.isBefore(from!);

  /// Set the wrong way round — a distinct failure from "not finished", and
  /// worth its own message.
  bool get isReversed => from != null && to != null && to!.isBefore(from!);

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (from != null) 'from': from!.toIso8601String(),
    if (to != null) 'to': to!.toIso8601String(),
  };

  /// Copies the range. Pass `clearFrom` / `clearTo` to unset an end — a null
  /// argument means "leave it alone", as everywhere else.
  TaskDateRange copyWith({
    DateTime? from,
    DateTime? to,
    bool clearFrom = false,
    bool clearTo = false,
  }) => TaskDateRange(
    from: clearFrom ? null : from ?? this.from,
    to: clearTo ? null : to ?? this.to,
  );

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  @override
  List<Object?> get props => <Object?>[from, to];
}

/// The complete recurrence for a task.
///
/// One object holds every frequency's inputs rather than a field per screen
/// state, so the form can switch frequency without losing what was already
/// picked, and so saving and restoring an edit is a single [toJson] /
/// [fromJson] pair.
///
/// Only the fields belonging to [frequency] are ever read — [validationError]
/// and [toJson] both narrow on it — which is why switching back and forth is
/// safe.
class TaskSchedule extends Equatable {
  const TaskSchedule({
    this.frequency = TaskFrequency.daily,
    this.startTimeMinutes,
    this.endTimeMinutes,
    this.weekdays = const <int>{},
    this.monthWeekdays = const <int>{},
    this.quarterRanges = const <TaskQuarter, TaskDateRange>{},
    this.yearlyRange = const TaskDateRange(),
  });

  /// Rebuilds a schedule saved by [toJson].
  factory TaskSchedule.fromJson(Map<String, dynamic> json) {
    final Map<TaskQuarter, TaskDateRange> quarters =
        <TaskQuarter, TaskDateRange>{};
    final Object? rawQuarters = json['quarters'];
    if (rawQuarters is Map) {
      rawQuarters.forEach((Object? key, Object? value) {
        final TaskQuarter? quarter = TaskQuarter.fromWire(key as String?);
        if (quarter == null) {
          return;
        }
        quarters[quarter] = value is Map<String, dynamic>
            ? TaskDateRange.fromJson(value)
            // A quarter that came back without a range is still a selected
            // quarter; it just has nothing filled in yet.
            : const TaskDateRange();
      });
    }

    return TaskSchedule(
      frequency: TaskFrequency.fromWire(json['frequency'] as String?),
      startTimeMinutes: (json['start_time_minutes'] as num?)?.toInt(),
      endTimeMinutes: (json['end_time_minutes'] as num?)?.toInt(),
      weekdays: _intSet(json['weekdays']),
      monthWeekdays: _intSet(json['month_weekdays']),
      quarterRanges: quarters,
      yearlyRange: TaskDateRange.fromJson(<String, dynamic>{
        'from': json['start_date'],
        'to': json['due_date'],
      }),
    );
  }

  final TaskFrequency frequency;

  /// Minutes since midnight, for [TaskFrequency.daily]. Ints rather than
  /// `TimeOfDay`s to keep this layer free of Flutter; the form converts at
  /// the widget boundary.
  final int? startTimeMinutes;
  final int? endTimeMinutes;

  /// `DateTime.monday`–`DateTime.sunday`, for [TaskFrequency.weekly].
  final Set<int> weekdays;

  /// Days of the week a monthly task runs on. Held separately from
  /// [weekdays] so switching between the two frequencies does not overwrite
  /// the other one's selection.
  final Set<int> monthWeekdays;

  /// The date range chosen inside each selected quarter. A quarter present
  /// with an empty range is selected but not yet filled in — which
  /// [validationError] rejects rather than filling in for the user.
  final Map<TaskQuarter, TaskDateRange> quarterRanges;

  /// The start and due date of a yearly task. Yearly is the only frequency
  /// with a date window: the others describe a repeating time or day, so a
  /// calendar range would mean nothing to them.
  final TaskDateRange yearlyRange;

  /// The quarters the user ticked, in calendar order.
  List<TaskQuarter> get selectedQuarters => TaskQuarter.values
      .where((TaskQuarter quarter) => quarterRanges.containsKey(quarter))
      .toList();

  /// The range picked for [quarter] — empty when the quarter is ticked but
  /// untouched, or was cleared.
  TaskDateRange rangeFor(TaskQuarter quarter) =>
      quarterRanges[quarter] ?? const TaskDateRange();

  /// Why this schedule cannot be saved yet, or null when it is complete.
  ///
  /// The single source of truth for "is the recurring part filled in" — the
  /// form shows it inline and blocks submit on it.
  String? get validationError {
    switch (frequency) {
      case TaskFrequency.daily:
        if (startTimeMinutes == null || endTimeMinutes == null) {
          return 'Select a start time and an end time.';
        }
        if (endTimeMinutes! <= startTimeMinutes!) {
          return 'The end time must be after the start time.';
        }
        return null;
      case TaskFrequency.weekly:
        return weekdays.isEmpty ? 'Select at least one day of the week.' : null;
      case TaskFrequency.monthly:
        return monthWeekdays.isEmpty
            ? 'Select at least one day for the monthly task.'
            : null;
      case TaskFrequency.quarterly:
        if (selectedQuarters.isEmpty) {
          return 'Select at least one quarter.';
        }
        for (final TaskQuarter quarter in selectedQuarters) {
          final TaskDateRange range = rangeFor(quarter);
          if (range.isReversed) {
            return 'The to date must be on or after the from date for the '
                '${quarter.label}.';
          }
          if (!range.isComplete) {
            return 'Select a from and to date for the ${quarter.label}.';
          }
        }
        return null;
      case TaskFrequency.yearly:
        if (yearlyRange.isReversed) {
          return 'The due date must be on or after the start date.';
        }
        return yearlyRange.isComplete
            ? null
            : 'Select a start date and a due date.';
    }
  }

  bool get isComplete => validationError == null;

  /// Sends only what the chosen [frequency] uses, so a task switched from
  /// quarterly to daily does not carry its old quarters to the server.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'frequency': frequency.wireValue,
    if (frequency == TaskFrequency.daily) ...<String, dynamic>{
      if (startTimeMinutes != null) 'start_time_minutes': startTimeMinutes,
      if (endTimeMinutes != null) 'end_time_minutes': endTimeMinutes,
    },
    if (frequency == TaskFrequency.weekly)
      'weekdays': (weekdays.toList()..sort()),
    if (frequency == TaskFrequency.monthly)
      'month_weekdays': (monthWeekdays.toList()..sort()),
    if (frequency == TaskFrequency.quarterly)
      'quarters': <String, dynamic>{
        for (final TaskQuarter quarter in selectedQuarters)
          quarter.wireValue: rangeFor(quarter).toJson(),
      },
    if (frequency == TaskFrequency.yearly) ...<String, dynamic>{
      if (yearlyRange.from != null)
        'start_date': yearlyRange.from!.toIso8601String(),
      if (yearlyRange.to != null) 'due_date': yearlyRange.to!.toIso8601String(),
    },
  };

  /// Copies the schedule. Pass the `clear*` flags to unset a value — a null
  /// argument means "leave it alone", as everywhere else.
  TaskSchedule copyWith({
    TaskFrequency? frequency,
    int? startTimeMinutes,
    int? endTimeMinutes,
    Set<int>? weekdays,
    Set<int>? monthWeekdays,
    Map<TaskQuarter, TaskDateRange>? quarterRanges,
    TaskDateRange? yearlyRange,
    bool clearStartTime = false,
    bool clearEndTime = false,
  }) => TaskSchedule(
    frequency: frequency ?? this.frequency,
    startTimeMinutes: clearStartTime
        ? null
        : startTimeMinutes ?? this.startTimeMinutes,
    endTimeMinutes: clearEndTime ? null : endTimeMinutes ?? this.endTimeMinutes,
    weekdays: weekdays ?? this.weekdays,
    monthWeekdays: monthWeekdays ?? this.monthWeekdays,
    quarterRanges: quarterRanges ?? this.quarterRanges,
    yearlyRange: yearlyRange ?? this.yearlyRange,
  );

  /// Adds or removes a weekly day.
  TaskSchedule toggleWeekday(int weekday) =>
      copyWith(weekdays: _toggled(weekdays, weekday));

  /// Adds or removes a monthly day.
  TaskSchedule toggleMonthWeekday(int weekday) =>
      copyWith(monthWeekdays: _toggled(monthWeekdays, weekday));

  /// Ticks or unticks a quarter. Unticking drops the range picked under it,
  /// which is what the user means by clearing the quarter.
  TaskSchedule toggleQuarter(TaskQuarter quarter) {
    final Map<TaskQuarter, TaskDateRange> next =
        Map<TaskQuarter, TaskDateRange>.from(quarterRanges);
    if (next.containsKey(quarter)) {
      next.remove(quarter);
    } else {
      next[quarter] = const TaskDateRange();
    }
    return copyWith(quarterRanges: next);
  }

  /// Sets one quarter's range. Ignored when the quarter is not selected, and
  /// when either end falls outside the quarter's own months — a stale tap
  /// cannot file an April date under the October quarter.
  TaskSchedule setQuarterRange(
    TaskQuarter quarter,
    TaskDateRange range, {
    DateTime? reference,
  }) {
    if (!quarterRanges.containsKey(quarter)) {
      return this;
    }
    final DateTime? from = range.from;
    final DateTime? to = range.to;
    if ((from != null && !quarter.contains(from, reference: reference)) ||
        (to != null && !quarter.contains(to, reference: reference))) {
      return this;
    }
    final Map<TaskQuarter, TaskDateRange> next =
        Map<TaskQuarter, TaskDateRange>.from(quarterRanges)..[quarter] = range;
    return copyWith(quarterRanges: next);
  }

  /// Empties a quarter's range while leaving the quarter selected — the
  /// "clear" action next to the two date fields.
  TaskSchedule clearQuarterRange(TaskQuarter quarter) {
    if (!quarterRanges.containsKey(quarter)) {
      return this;
    }
    final Map<TaskQuarter, TaskDateRange> next =
        Map<TaskQuarter, TaskDateRange>.from(quarterRanges)
          ..[quarter] = const TaskDateRange();
    return copyWith(quarterRanges: next);
  }

  static Set<T> _toggled<T>(Set<T> source, T value) {
    final Set<T> next = Set<T>.from(source);
    if (!next.remove(value)) {
      next.add(value);
    }
    return next;
  }

  static Set<int> _intSet(Object? raw) => raw is List
      ? raw.whereType<num>().map((num value) => value.toInt()).toSet()
      : <int>{};

  @override
  List<Object?> get props => <Object?>[
    frequency,
    startTimeMinutes,
    endTimeMinutes,
    weekdays,
    monthWeekdays,
    quarterRanges,
    yearlyRange,
  ];
}
