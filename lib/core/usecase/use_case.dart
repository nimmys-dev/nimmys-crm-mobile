import '../utils/result.dart';

/// A single piece of business logic, callable like a function.
///
/// Worth writing when there is actual logic to hold: combining two
/// repositories, enforcing a rule, deriving something the API does not
/// return. A use case that only forwards one call to one repository is
/// ceremony — in that case let the bloc depend on the repository directly.
/// The pattern is here for when it earns its place, not as a mandatory layer.
///
/// [T] is what it produces, [P] what it needs.
abstract class UseCase<T, P> {
  const UseCase();

  Future<Result<T>> call(P params);
}

/// A use case taking no input.
abstract class NoParamsUseCase<T> {
  const NoParamsUseCase();

  Future<Result<T>> call();
}

/// Placeholder for `UseCase<T, NoParams>` where a call still wants an
/// argument for symmetry.
class NoParams {
  const NoParams();
}

/// Parameters shared by every paginated query, so features only declare the
/// filters that are actually their own.
class PageParams {
  const PageParams({this.page = 1, this.pageSize = 20, this.query});

  final int page;
  final int pageSize;

  /// Free-text search, when the screen has a search field.
  final String? query;

  /// Query-string form, ready to hand to the API client.
  ///
  /// Null and blank values are dropped so an empty search box does not send
  /// `?query=` and change what the server returns.
  Map<String, dynamic> toQuery() => <String, dynamic>{
    'page': page,
    'per_page': pageSize,
    if (query != null && query!.trim().isNotEmpty) 'query': query!.trim(),
  };
}
