import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

class CustomLog {

  static final _logger = Logger(printer: PrettyPrinter());

  /// The tag written in front of every line.
  ///
  /// `instance` is normally `this`, but a `static` method has no instance to
  /// pass and hands over its own type instead — `CustomLog.debug(Foo, …)`.
  /// `runtimeType` on a `Type` is `_Type`, which would make every static log
  /// line from the app read the same, so that case is unwrapped here.
  static String _tag(Object instance) =>
      instance is Type ? instance.toString() : instance.runtimeType.toString();

  static void debug(Object instance, String message) {
    if(kDebugMode){
      _logger.d("[${_tag(instance)}] $message", time: DateTimeHelper.now());
    }
  }

  static void info(Object instance, String message) {
    if(kDebugMode){
      _logger.i("[${_tag(instance)}] $message", time: DateTimeHelper.now());
    }
  }

  /// [exception] is optional: plenty of errors are a bad state rather than a
  /// caught throwable, and those callers have nothing to pass.
  static void error(Object instance, String message, [Object? exception, StackTrace? stackTrace]) {
    if(kDebugMode){
      _logger.e(
          "[${_tag(instance)}] $message",
          time: DateTimeHelper.now(),
          error: exception,
          stackTrace: stackTrace,
      );
    }
  }

}


class DateTimeHelper {
  DateTimeHelper._();

  /// Get Current Date Time
  static DateTime now() {
    return DateTime.now();
  }

  /// Get Date Time Format
  static String getDateTimeFormat(DateTime date) {
    final istDate = date.toUtc().add(const Duration(hours: 5, minutes: 30));
    var formatter = DateFormat('dd/MM/yyyy - hh:mm a');
    return formatter.format(istDate);
  }

  /// Get Time Format With Am or Pm
  static String getTimeFormatWithAmOrPm(DateTime date) {
    var formatter = DateFormat('hh:mm a');
    return formatter.format(date.toLocal());
  }

  /// Get Format Date
  static String getFormattedDate(DateTime date) {
    var formatter = DateFormat("dd-MM-yyyy");
    return formatter.format(date.toLocal());
  }

  /// Get Date With Short Name
  static String getFormattedDateWithShortMonthName(DateTime date) {
    var formatter = DateFormat("dd MMM yyyy");
    return formatter.format(date.toLocal());
  }

  /// Convert to AM or Pm
  static String convertToAmPm(String time, BuildContext context) {
    DateTime parsedTime = DateTime.parse('1970-01-01 $time:00');
    String formattedTime = TimeOfDay.fromDateTime(parsedTime).format(context);
    return formattedTime;
  }

  /// Convert to API/database format: "2025-06-14T20:00:00.000Z"
  static String convertToDatabaseFormat(String date) {
    try {
      DateTime parsedDate = DateFormat("dd/MM/yyyy").parse(date);
      // Convert to UTC and format as ISO 8601
      return parsedDate.toUtc().toIso8601String(); // e.g., "2025-06-14T00:00:00.000Z"
    } catch (e) {
      return "Invalid Date";
    }
  }


  /// Convert to database format
  static String convertToDatabaseFormat2(String date) {
    try {
      DateTime parsedDate = DateFormat("dd/MM/yyyy").parse(date);
      return DateFormat("yyyy-MM-dd").format(parsedDate);
    } catch (e) {
      return "Invalid Date";
    }
  }

  /// Output: 14 Jul, 2025, 7.30 PM
  static String formatCustomDate(DateTime date) {
    try {
    return DateFormat("d MMM y, hh:mm a").format(date.toLocal());
    } catch (e) {
      return "Invalid Date";
    }
  }

  /// convert to IST format
  static String formatCustomDateTimeIST(DateTime? date) {
    try {
      if (date == null) return "Invalid Date";
      final istDate = date.toUtc().add(const Duration(hours: 5, minutes: 30));
      return DateFormat("d MMM y, hh:mm a").format(istDate);
    } catch (e) {
      return "Invalid Date";
    }
  }

  /// convert to IST format
  static String formatCustomDateIST(DateTime? date) {
    try {
      if (date == null) return "Invalid Date";
      final istDate = date.toUtc().add(const Duration(hours: 5, minutes: 30));
      return DateFormat("d MMM y").format(istDate);
    } catch (e) {
      return "Invalid Date";
    }
  }

  static DateTime? convertStringToDateTime(String dateString) {
    try {
      // Define input format (DD/MM/YYYY)
      final DateFormat format = DateFormat("dd/MM/yyyy");
      return format.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Input Date Format : dd/MM/yyyy
  static DateTime convertToDateTimeWithCurrentTime(String date) {
    try {
      DateTime parsedDate = DateFormat("dd/MM/yyyy").parse(date);
      DateTime now = DateTime.now();
      return DateTime(parsedDate.year, parsedDate.month, parsedDate.day, now.hour, now.minute, now.second);
    } catch (e) {
      return DateTime.now();
    }
  }

  /// Input Format hh : mm a , example- 05 : 15 PM
  static TimeOfDay convertStringToTimeOfDay(String timeString) {
    try {
      final DateFormat format = DateFormat("hh : mm a");
      final DateTime parsedDateTime = format.parse(timeString);
      return TimeOfDay(hour: parsedDateTime.hour, minute: parsedDateTime.minute);
    } catch (e) {
      return TimeOfDay.now();
    }
  }



  /// Converts date and time strings into ISO8601 UTC format for API
  static String convertToApiDateTime(String date, String time) {
    try {
      // Combine date and time strings
      String input = "$date , $time";

      // Expected format
      final inputFormat = DateFormat("dd/MM/yyyy , hh : mm a");

      // Parse to DateTime in local time
      final localDateTime = inputFormat.parse(input);

      // Convert to UTC
      final utcDateTime = localDateTime.toUtc();

      // Return ISO 8601 format string
      return utcDateTime.toIso8601String();
    } catch (e) {
      return ""; // or throw an error/log it
    }


  }

  /// Converts ISO8601 string to "dd-MM-yyyy | hh:mm a" format in IST
  static String formatToDateTimeWithTime(String isoDateString) {
    try {
      final dateTime = DateTime.parse(isoDateString).toUtc().add(const Duration(hours: 5, minutes: 30));
      return DateFormat("dd-MM-yyyy | hh:mm a").format(dateTime);
    } catch (e) {
      return "Invalid Date";
    }
  }

  /// Returns current date and time plus given duration (in seconds) formatted as "dd-MM-yyyy, hh:mm a"
  static String getCurrentDateTimeWithAddedDuration(int durationInSeconds) {
    try {
      final dateTime = DateTime.now().add(Duration(seconds: durationInSeconds));
      return DateFormat("d MMM y, hh:mm a").format(dateTime);
    } catch (e) {
      return "Invalid Date";
    }
  }





}