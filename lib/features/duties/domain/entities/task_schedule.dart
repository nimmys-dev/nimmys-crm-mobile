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

/// API value for a weekday, for example `monday`.
String weekdayWireValue(int weekday) => weekdayName(weekday).toLowerCase();

/// "MON" for `DateTime.monday` — the chip caption.
String weekdayShortName(int weekday) =>
    weekdayName(weekday).substring(0, 3).toUpperCase();

/// Highest day a monthly task can be scheduled on.
///
/// 30 rather than 31 by design: a task set for the 31st would skip five months
/// of the year, so the picker does not offer it.
const int kMaxMonthDay = 30;

/// The values in the monthly day box, 1–[kMaxMonthDay].
const List<int> kMonthDayValues = <int>[
  1, 2, 3, 4, 5, 6, 7, 8, 9, 10, //
  11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
  21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
];

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
    this.repeat = true,
    this.frequency = TaskFrequency.daily,
    this.startTimeMinutes,
    this.endTimeMinutes,
    this.weekStartDay,
    this.weekEndDay,
    this.weekdays = const <int>{},
    this.monthlyRange = const TaskDateRange(),
    this.monthDays = const <int>{},
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
      // Absent means an older task saved before the toggle existed, and every
      // one of those was recurring.
      repeat: json['repeat'] as bool? ?? true,
      frequency: TaskFrequency.fromWire(json['frequency'] as String?),
      startTimeMinutes: (json['start_time_minutes'] as num?)?.toInt(),
      endTimeMinutes: (json['end_time_minutes'] as num?)?.toInt(),
      weekStartDay: _weekday(json['week_start_day']),
      weekEndDay: _weekday(json['week_end_day']),
      weekdays: _intSet(json['weekdays']),
      monthlyRange: TaskDateRange.fromJson(<String, dynamic>{
        'from': json['monthly_start_date'],
        'to': json['monthly_end_date'],
      }),
      monthDays: _intSet(json['month_days']),
      quarterRanges: quarters,
      yearlyRange: TaskDateRange.fromJson(<String, dynamic>{
        'from': json['start_date'],
        'to': json['due_date'],
      }),
    );
  }

  /// Whether the task repeats at all.
  ///
  /// On by default. Turned off, the task is a one-off: nothing below applies,
  /// and [validationError] asks for none of it.
  final bool repeat;

  final TaskFrequency frequency;

  /// Minutes since midnight, for [TaskFrequency.daily]. Ints rather than
  /// `TimeOfDay`s to keep this layer free of Flutter; the form converts at
  /// the widget boundary.
  final int? startTimeMinutes;
  final int? endTimeMinutes;

  /// Inclusive weekday window for [TaskFrequency.weekly].
  final int? weekStartDay;
  final int? weekEndDay;

  /// `DateTime.monday`–`DateTime.sunday`, for [TaskFrequency.weekly]. A
  /// weekly task is only its days: it carries no date window.
  final Set<int> weekdays;

  /// The window a monthly task runs in. Held separately from [yearlyRange] so
  /// switching between the two frequencies does not overwrite the other one's
  /// dates.
  final TaskDateRange monthlyRange;

  /// Days of the month (1–[kMaxMonthDay]) a monthly task runs on.
  final Set<int> monthDays;

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
    // A one-off task has no schedule to complete.
    if (!repeat) {
      return null;
    }
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
        if (weekStartDay == null || weekEndDay == null) {
          return 'Select a start day and an end day.';
        }
        return null;
      case TaskFrequency.monthly:
        return _rangeError(monthlyRange, 'end');
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
        return _rangeError(yearlyRange, 'due');
    }
  }

  /// Why a start/end window is not usable yet, or null when it is.
  ///
  /// [endLabel] is what that frequency calls the far end — "end" for the
  /// weekly and monthly windows, "due" for the yearly one.
  static String? _rangeError(TaskDateRange range, String endLabel) {
    if (range.isReversed) {
      return 'The $endLabel date must be on or after the start date.';
    }
    return range.isComplete ? null : 'Select a start date and $endLabel date.';
  }

  bool get isComplete => validationError == null;

  /// Sends only what the chosen [frequency] uses, so a task switched from
  /// quarterly to daily does not carry its old quarters to the server — and
  /// nothing at all beyond the frequency when [repeat] is off.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'repeat': repeat,
    'frequency': frequency.wireValue,
    if (repeat) ...<String, dynamic>{
      if (frequency == TaskFrequency.daily) ...<String, dynamic>{
        if (startTimeMinutes != null) 'start_time_minutes': startTimeMinutes,
        if (endTimeMinutes != null) 'end_time_minutes': endTimeMinutes,
      },
      if (frequency == TaskFrequency.weekly)
        ...<String, dynamic>{
          if (weekStartDay != null)
            'week_start_day': weekdayWireValue(weekStartDay!),
          if (weekEndDay != null) 'week_end_day': weekdayWireValue(weekEndDay!),
        },
      if (frequency == TaskFrequency.monthly) ...<String, dynamic>{
        ..._rangeJson(monthlyRange, 'monthly_start_date', 'monthly_end_date'),
      },
      if (frequency == TaskFrequency.quarterly)
        'quarters': <String, dynamic>{
          for (final TaskQuarter quarter in selectedQuarters)
            quarter.wireValue: rangeFor(quarter).toJson(),
        },
      if (frequency == TaskFrequency.yearly)
        ..._rangeJson(yearlyRange, 'start_date', 'due_date'),
    },
  };

  static Map<String, dynamic> _rangeJson(
    TaskDateRange range,
    String fromKey,
    String toKey,
  ) => <String, dynamic>{
    if (range.from != null) fromKey: range.from!.toIso8601String(),
    if (range.to != null) toKey: range.to!.toIso8601String(),
  };

  /// Copies the schedule. Pass the `clear*` flags to unset a value — a null
  /// argument means "leave it alone", as everywhere else.
  TaskSchedule copyWith({
    bool? repeat,
    TaskFrequency? frequency,
    int? startTimeMinutes,
    int? endTimeMinutes,
    int? weekStartDay,
    int? weekEndDay,
    Set<int>? weekdays,
    TaskDateRange? monthlyRange,
    Set<int>? monthDays,
    Map<TaskQuarter, TaskDateRange>? quarterRanges,
    TaskDateRange? yearlyRange,
    bool clearStartTime = false,
    bool clearEndTime = false,
  }) => TaskSchedule(
    repeat: repeat ?? this.repeat,
    frequency: frequency ?? this.frequency,
    startTimeMinutes: clearStartTime
        ? null
        : startTimeMinutes ?? this.startTimeMinutes,
    endTimeMinutes: clearEndTime ? null : endTimeMinutes ?? this.endTimeMinutes,
    weekStartDay: weekStartDay ?? this.weekStartDay,
    weekEndDay: weekEndDay ?? this.weekEndDay,
    weekdays: weekdays ?? this.weekdays,
    monthlyRange: monthlyRange ?? this.monthlyRange,
    monthDays: monthDays ?? this.monthDays,
    quarterRanges: quarterRanges ?? this.quarterRanges,
    yearlyRange: yearlyRange ?? this.yearlyRange,
  );

  /// Adds or removes a weekly day.
  TaskSchedule toggleWeekday(int weekday) =>
      copyWith(weekdays: _toggled(weekdays, weekday));

  /// Adds or removes a day of the month. Days outside 1–[kMaxMonthDay] are
  /// ignored, so nothing the picker cannot show can end up selected.
  TaskSchedule toggleMonthDay(int day) => day < 1 || day > kMaxMonthDay
      ? this
      : copyWith(monthDays: _toggled(monthDays, day));

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

  static int? _weekday(Object? raw) {
    if (raw is! String) return null;
    final String value = raw.trim().toLowerCase();
    for (final int weekday in _weekdayNames.keys) {
      if (weekdayWireValue(weekday) == value) return weekday;
    }
    return null;
  }

  @override
  List<Object?> get props => <Object?>[
    repeat,
    frequency,
    startTimeMinutes,
    endTimeMinutes,
    weekStartDay,
    weekEndDay,
    weekdays,
    monthlyRange,
    monthDays,
    quarterRanges,
    yearlyRange,
  ];
}
