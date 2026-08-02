import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Tagged logging.
///
/// The first argument is whatever is doing the logging: pass `this` from an
/// instance method and the type itself from a `static` one. Both end up as the
/// same tag, which is why a class can log the same way from either side.
///
/// Debug lines compile away in release builds — `kDebugMode` is a compile-time
/// constant, so the tree shaker drops the call and the interpolated string with
/// it. Errors are kept: they are rare, and losing them is worse than the noise.
class CustomLog {
  const CustomLog._();

  static void debug(Object? source, Object? message) {
    if (kDebugMode) {
      developer.log('$message', name: _tag(source));
    }
  }

  static void error(
    Object? source,
    Object? message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    developer.log(
      '$message',
      name: _tag(source),
      error: error,
      stackTrace: stackTrace,
      level: 1000, // SEVERE
    );
  }

  static String _tag(Object? source) {
    if (source == null) {
      return 'App';
    }
    if (source is Type) {
      return source.toString();
    }
    if (source is String) {
      return source;
    }
    return source.runtimeType.toString();
  }
}
