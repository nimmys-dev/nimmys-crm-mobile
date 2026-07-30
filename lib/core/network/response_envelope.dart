/// Describes the wrapper an API puts around every payload.
///
/// Most backends answer with something like
/// `{ "success": true, "data": {...}, "message": "..." }`, but the exact keys
/// differ per project and some endpoints return the object bare. Isolating
/// that shape here means models only ever see the payload itself, and
/// pointing the app at a differently-shaped API is one class, not a hundred
/// `json['data']['data']` edits.
abstract interface class ResponseEnvelope {
  /// Pulls the payload out of a full response body.
  dynamic extractData(dynamic body);

  /// The server's human-readable note, if present.
  String? extractMessage(dynamic body);

  /// Per-field validation errors, if present.
  Map<String, List<String>> extractFieldErrors(dynamic body);

  /// Whether a 2xx body actually represents success.
  ///
  /// Exists because plenty of APIs answer `200 OK` with `{"success": false}`.
  /// Checking it centrally stops every data source from having to remember.
  bool isSuccess(dynamic body);
}

/// For APIs that return the payload with no wrapper at all.
class PlainEnvelope implements ResponseEnvelope {
  const PlainEnvelope();

  @override
  dynamic extractData(dynamic body) => body;

  @override
  String? extractMessage(dynamic body) =>
      body is Map<String, dynamic> ? body['message'] as String? : null;

  @override
  Map<String, List<String>> extractFieldErrors(dynamic body) =>
      const <String, List<String>>{};

  @override
  bool isSuccess(dynamic body) => true;
}

/// The common `{ success, data, message, errors }` wrapper, with the key
/// names left configurable so the same class serves most REST backends.
class WrappedEnvelope implements ResponseEnvelope {
  const WrappedEnvelope({
    this.dataKey = 'data',
    this.messageKey = 'message',
    this.successKey = 'success',
    this.errorsKey = 'errors',
  });

  final String dataKey;
  final String messageKey;
  final String successKey;
  final String errorsKey;

  @override
  dynamic extractData(dynamic body) {
    if (body is! Map<String, dynamic>) {
      return body;
    }
    // A body with no data key is the payload — this keeps endpoints that
    // return a bare object working without a second envelope.
    return body.containsKey(dataKey) ? body[dataKey] : body;
  }

  @override
  String? extractMessage(dynamic body) =>
      body is Map<String, dynamic> ? body[messageKey] as String? : null;

  @override
  Map<String, List<String>> extractFieldErrors(dynamic body) {
    if (body is! Map<String, dynamic>) {
      return const <String, List<String>>{};
    }
    final dynamic errors = body[errorsKey];
    if (errors is! Map<String, dynamic>) {
      return const <String, List<String>>{};
    }
    // Servers are inconsistent about whether a field's errors are a list or
    // a single string, so normalise both into a list.
    return errors.map<String, List<String>>((String field, dynamic value) {
      return MapEntry<String, List<String>>(field, switch (value) {
        final List<dynamic> list => list.map((dynamic e) => e.toString()).toList(),
        final String single => <String>[single],
        _ => <String>[value.toString()],
      });
    });
  }

  @override
  bool isSuccess(dynamic body) {
    if (body is! Map<String, dynamic>) {
      return true;
    }
    final dynamic flag = body[successKey];
    // Absent flag means the endpoint does not use one; only an explicit
    // false counts as failure.
    return flag is! bool || flag;
  }
}
