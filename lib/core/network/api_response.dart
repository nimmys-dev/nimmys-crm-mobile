/// Turns a decoded JSON payload into a typed object.
///
/// Passed down into the client so deserialization happens in one place,
/// inside the same try/catch that converts a bad cast into a `ParseException`.
typedef ResponseParser<T> = T Function(dynamic json);

/// What a data source gets back from [ApiClient].
///
/// Carries the status code and headers alongside the parsed body because
/// pagination cursors, rate-limit budgets and ETags all live in headers, and
/// a data source that can only see the body cannot reach them.
class ApiResponse<T> {
  const ApiResponse({
    required this.data,
    required this.statusCode,
    this.message,
    this.headers = const <String, List<String>>{},
  });

  final T data;
  final int statusCode;

  /// The server's own human-readable note, when the envelope carries one.
  final String? message;

  final Map<String, List<String>> headers;

  String? header(String name) {
    final String key = name.toLowerCase();
    for (final MapEntry<String, List<String>> entry in headers.entries) {
      if (entry.key.toLowerCase() == key) {
        return entry.value.isEmpty ? null : entry.value.first;
      }
    }
    return null;
  }

  ApiResponse<R> withData<R>(R newData) => ApiResponse<R>(
    data: newData,
    statusCode: statusCode,
    message: message,
    headers: headers,
  );
}

/// One page of a list endpoint, plus enough metadata to know whether to ask
/// for another.
///
/// Generic over the item type so every paginated screen in the app shares
/// this one class instead of each feature inventing its own page wrapper.
class PaginatedData<T> {
  const PaginatedData({
    required this.items,
    required this.page,
    required this.hasMore,
    this.totalItems,
    this.totalPages,
    this.nextCursor,
  });

  const PaginatedData.empty()
    : items = const <Never>[],
      page = 1,
      hasMore = false,
      totalItems = 0,
      totalPages = 0,
      nextCursor = null;

  final List<T> items;

  /// 1-based index of the page these [items] came from.
  final int page;

  /// Whether another page exists. Trusted over comparing counts, because a
  /// server that filters after paging can return a short page that is not
  /// the last one.
  final bool hasMore;

  final int? totalItems;
  final int? totalPages;

  /// Opaque cursor for keyset-paginated APIs; null for page-number APIs.
  final String? nextCursor;

  bool get isEmpty => items.isEmpty;

  /// Builds the page that results from appending [next] to this one — the
  /// operation behind every "load more".
  PaginatedData<T> append(PaginatedData<T> next) => PaginatedData<T>(
    items: <T>[...items, ...next.items],
    page: next.page,
    hasMore: next.hasMore,
    totalItems: next.totalItems ?? totalItems,
    totalPages: next.totalPages ?? totalPages,
    nextCursor: next.nextCursor,
  );

  PaginatedData<R> map<R>(R Function(T item) transform) => PaginatedData<R>(
    items: items.map(transform).toList(growable: false),
    page: page,
    hasMore: hasMore,
    totalItems: totalItems,
    totalPages: totalPages,
    nextCursor: nextCursor,
  );

  /// Reads the common `{ data: [...], meta: { ... } }` list shape.
  ///
  /// [itemParser] handles a single element, so a feature only ever writes
  /// `Lead.fromJson` and never repeats the paging arithmetic.
  static PaginatedData<T> fromJson<T>(
    dynamic json, {
    required T Function(Map<String, dynamic> json) itemParser,
    String itemsKey = 'data',
    String metaKey = 'meta',
  }) {
    if (json is List) {
      // An unwrapped array: no metadata to read, so treat it as a single
      // complete page rather than guessing.
      return PaginatedData<T>(
        items: json
            .whereType<Map<String, dynamic>>()
            .map(itemParser)
            .toList(growable: false),
        page: 1,
        hasMore: false,
      );
    }

    final Map<String, dynamic> map = json as Map<String, dynamic>;
    final List<dynamic> rawItems = (map[itemsKey] as List<dynamic>?) ?? const <dynamic>[];
    final Map<String, dynamic> meta =
        (map[metaKey] as Map<String, dynamic>?) ?? const <String, dynamic>{};

    final int page = _asInt(meta['current_page'] ?? meta['page']) ?? 1;
    final int? totalPages = _asInt(meta['last_page'] ?? meta['total_pages']);
    final int? totalItems = _asInt(meta['total'] ?? meta['total_items']);
    final String? cursor = meta['next_cursor'] as String?;

    return PaginatedData<T>(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(itemParser)
          .toList(growable: false),
      page: page,
      hasMore: switch ((cursor, totalPages)) {
        (final String _, _) => true,
        (null, final int last) => page < last,
        (null, null) => rawItems.isNotEmpty,
      },
      totalItems: totalItems,
      totalPages: totalPages,
      nextCursor: cursor,
    );
  }

  static int? _asInt(dynamic value) => switch (value) {
    final int value => value,
    final String value => int.tryParse(value),
    final num value => value.toInt(),
    _ => null,
  };
}
