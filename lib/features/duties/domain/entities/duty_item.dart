import 'package:equatable/equatable.dart';

/// Which slice of the duty list is on screen.
///
/// One filter rather than three screens: "today", "overdue" and "upcoming" are
/// the same list read through different date windows, and splitting them would
/// mean three copies of the same row, empty state and toolbar to keep in step.
/// [wireValue] is what travels in the route's query string.
enum DutyFilter {
  today('today', 'Today', "Today's Duty"),
  overdue('overdue', 'Overdue', 'Overdue Duty'),
  upcoming('upcoming', 'Upcoming', 'Upcoming Duty');

  const DutyFilter(this.wireValue, this.label, this.title);

  /// What the route carries.
  final String wireValue;

  /// The segmented-tab caption.
  final String label;

  /// The screen title while this filter is active.
  final String title;

  /// Maps a route parameter to a filter, defaulting to [today] so a malformed
  /// or missing `?filter=` opens the list rather than failing.
  static DutyFilter fromWire(String? value) {
    if (value == null) {
      return DutyFilter.today;
    }
    final String normalised = value.toLowerCase().trim();
    for (final DutyFilter filter in DutyFilter.values) {
      if (filter.wireValue == normalised) {
        return filter;
      }
    }
    return DutyFilter.today;
  }

  /// The tab captions, in declaration order.
  static List<String> get labels =>
      DutyFilter.values.map((DutyFilter filter) => filter.label).toList();
}

/// One duty in the list.
///
/// Pure domain — no JSON and no Flutter — matching `TaskSchedule` and `Lead`
/// next to it. Serialization belongs one layer out, once a duties endpoint
/// exists to serialize.
class DutyItem extends Equatable {
  const DutyItem({
    required this.title,
    required this.detail,
    required this.dueAt,
    required this.assignee,
    this.isCompleted = false,
  });

  final String title;
  final String detail;
  final DateTime dueAt;
  final String assignee;
  final bool isCompleted;

  /// True when this duty belongs in [filter]'s window.
  ///
  /// The three windows are exclusive, so a duty appears under exactly one tab
  /// and the counts add up. A completed duty is never overdue — it was done,
  /// the date having passed says nothing.
  bool matches(DutyFilter filter, {DateTime? now}) {
    final DateTime today = now ?? DateTime.now();
    final DateTime startOfToday = DateTime(today.year, today.month, today.day);
    final DateTime endOfToday = startOfToday.add(
      const Duration(days: 1) - const Duration(microseconds: 1),
    );

    switch (filter) {
      case DutyFilter.today:
        return !dueAt.isBefore(startOfToday) && !dueAt.isAfter(endOfToday);
      case DutyFilter.overdue:
        return dueAt.isBefore(startOfToday) && !isCompleted;
      case DutyFilter.upcoming:
        return dueAt.isAfter(endOfToday);
    }
  }

  /// How late this duty is, in whole days. Zero for anything not overdue.
  int daysOverdue({DateTime? now}) {
    final DateTime today = now ?? DateTime.now();
    final DateTime startOfToday = DateTime(today.year, today.month, today.day);
    final DateTime due = DateTime(dueAt.year, dueAt.month, dueAt.day);
    if (!due.isBefore(startOfToday)) {
      return 0;
    }
    return startOfToday.difference(due).inDays;
  }

  @override
  List<Object?> get props => <Object?>[
    title,
    detail,
    dueAt,
    assignee,
    isCompleted,
  ];
}
