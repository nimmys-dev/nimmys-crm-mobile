import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../request_keys.dart';

/// Prints traffic during development.
///
/// Two things make this safe to keep in the tree rather than commenting in
/// and out by hand:
///
/// * It is off unless `ApiConfig.enableLogging` is set, so release builds
///   never write request bodies to the device log.
/// * Authorization headers, cookies and password-ish fields are redacted even
///   when it *is* on. A token pasted into a bug report is a real incident,
///   and the mistake is easy to make while debugging.
///
/// Each request gets an id so a response can be matched to its request in a
/// log full of concurrent traffic.
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({
    this.logBodies = true,
    this.maxBodyLength = 2000,
  });

  /// Whether to include request and response bodies, not just the status line.
  final bool logBodies;

  /// Bodies longer than this are truncated — a 2 MB list response scrolls the
  /// useful lines out of the console.
  final int maxBodyLength;

  static const Set<String> _redactedHeaders = <String>{
    'authorization',
    'cookie',
    'set-cookie',
    'x-api-key',
    'proxy-authorization',
  };

  static const Set<String> _redactedFields = <String>{
    'password',
    'password_confirmation',
    'current_password',
    'new_password',
    'access_token',
    'refresh_token',
    'token',
    'secret',
    'pin',
    'otp',
  };

  int _nextId = 0;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final int id = _nextId++;
    options.extra = <String, dynamic>{
      ...options.extra,
      RequestKeys.requestId: id,
    };

    final StringBuffer buffer = StringBuffer()
      ..writeln('--> #$id ${options.method} ${options.uri}')
      ..writeln('headers: ${_redactHeaders(options.headers)}');

    if (logBodies && options.data != null) {
      buffer.writeln('body: ${_body(options.data)}');
    }

    _log(buffer.toString());
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final Object? id = response.requestOptions.extra[RequestKeys.requestId];
    final StringBuffer buffer = StringBuffer()
      ..writeln(
        '<-- #$id ${response.statusCode} '
        '${response.requestOptions.method} ${response.requestOptions.uri}',
      );

    if (logBodies) {
      buffer.writeln('body: ${_body(response.data)}');
    }

    _log(buffer.toString());
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final Object? id = err.requestOptions.extra[RequestKeys.requestId];
    _log(
      'x-- #$id ${err.response?.statusCode ?? err.type.name} '
      '${err.requestOptions.method} ${err.requestOptions.uri}\n'
      'error: ${err.message}\n'
      '${logBodies && err.response != null ? 'body: ${_body(err.response!.data)}' : ''}',
      isError: true,
    );
    handler.next(err);
  }

  Map<String, dynamic> _redactHeaders(Map<String, dynamic> headers) {
    return headers.map<String, dynamic>((String key, dynamic value) {
      final bool secret = _redactedHeaders.contains(key.toLowerCase());
      return MapEntry<String, dynamic>(key, secret ? '***' : value);
    });
  }

  String _body(dynamic data) {
    if (data is FormData) {
      // Never dump file bytes into the log; the field names are the useful
      // part anyway.
      final String fields = data.fields
          .map((MapEntry<String, String> e) => e.key)
          .join(', ');
      final String files = data.files
          .map((MapEntry<String, MultipartFile> e) => e.key)
          .join(', ');
      return 'FormData(fields: [$fields], files: [$files])';
    }

    final String encoded;
    try {
      encoded = const JsonEncoder.withIndent(
        '  ',
      ).convert(_redactBody(data is String ? jsonDecode(data) : data));
    } catch (_) {
      // Not JSON — HTML error pages and binary downloads both land here.
      final String raw = data.toString();
      return raw.length > maxBodyLength
          ? '${raw.substring(0, maxBodyLength)}… (truncated)'
          : raw;
    }

    return encoded.length > maxBodyLength
        ? '${encoded.substring(0, maxBodyLength)}… (truncated)'
        : encoded;
  }

  /// Walks the payload replacing sensitive values, at any nesting depth —
  /// tokens are usually one level down inside `data`.
  dynamic _redactBody(dynamic value) => switch (value) {
    final Map<dynamic, dynamic> map => map.map<dynamic, dynamic>((
      dynamic key,
      dynamic child,
    ) {
      final bool secret =
          key is String && _redactedFields.contains(key.toLowerCase());
      return MapEntry<dynamic, dynamic>(
        key,
        secret ? '***' : _redactBody(child),
      );
    }),
    final List<dynamic> list => list.map(_redactBody).toList(),
    _ => value,
  };

  void _log(String message, {bool isError = false}) {
    developer.log(
      message,
      name: 'api',
      level: isError ? 1000 : 800,
    );
  }
}
