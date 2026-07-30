/// Defensive readers for JSON values.
///
/// Real APIs are inconsistent in small ways — an id that is an int in one
/// endpoint and a string in another, a date that is sometimes null, a
/// "0"/"1" where a bool was documented. Parsing through these helpers means a
/// model never throws on a surprise it could reasonably absorb, and the
/// failures that *are* worth surfacing come from required fields only.
extension JsonMap on Map<String, dynamic> {
  /// Reads a string, coercing numbers, or null.
  String? stringOrNull(String key) => switch (this[key]) {
    final String value when value.isNotEmpty => value,
    final num value => value.toString(),
    _ => null,
  };

  /// Reads a required string, falling back rather than throwing.
  String stringOr(String key, [String fallback = '']) =>
      stringOrNull(key) ?? fallback;

  int? intOrNull(String key) => switch (this[key]) {
    final int value => value,
    final num value => value.toInt(),
    final String value => int.tryParse(value),
    _ => null,
  };

  int intOr(String key, [int fallback = 0]) => intOrNull(key) ?? fallback;

  double? doubleOrNull(String key) => switch (this[key]) {
    final double value => value,
    final num value => value.toDouble(),
    final String value => double.tryParse(value),
    _ => null,
  };

  /// Reads a bool, accepting the `1`/`"true"`/`"yes"` spellings servers use.
  bool boolOr(String key, [bool fallback = false]) => switch (this[key]) {
    final bool value => value,
    final num value => value != 0,
    final String value => const <String>{
      'true',
      '1',
      'yes',
    }.contains(value.toLowerCase()),
    _ => fallback,
  };

  /// Parses an ISO-8601 timestamp, or null when absent or malformed.
  DateTime? dateOrNull(String key) => switch (this[key]) {
    final String value => DateTime.tryParse(value),
    // Epoch values arrive in seconds far more often than milliseconds.
    final int value => DateTime.fromMillisecondsSinceEpoch(
      value < 100000000000 ? value * 1000 : value,
    ),
    _ => null,
  };

  Map<String, dynamic>? mapOrNull(String key) =>
      this[key] is Map<String, dynamic> ? this[key] as Map<String, dynamic> : null;

  /// Reads a list of objects and parses each one.
  ///
  /// Elements that are not objects are skipped rather than throwing, so one
  /// malformed row in a page does not lose the other nineteen.
  List<T> listOf<T>(String key, T Function(Map<String, dynamic> json) parser) {
    final dynamic value = this[key];
    if (value is! List) {
      return const <Never>[];
    }
    return value
        .whereType<Map<String, dynamic>>()
        .map(parser)
        .toList(growable: false);
  }
}
