import 'package:equatable/equatable.dart';

import '../error/app_exception.dart';

/// Where a page sits in its data lifecycle, for any feature.
///
/// One generic type instead of a hand-written state class per bloc: a list
/// screen is `ViewState<List<Lead>>`, a detail screen `ViewState<Lead>`, a
/// form `ViewState<void>`. Every screen therefore knows the same eight cases,
/// and the shared widgets in `view_state_view.dart` can render any of them.
///
/// The design point that matters most is that [RefreshingState],
/// [LoadingMoreState] and [ErrorState] all carry the data that was already on
/// screen. Modelling a refresh as "loading, therefore no data" is what makes
/// apps blank out and jump to a spinner every time the user pulls down; here
/// the list stays put and the indicator sits on top of it.
///
/// Sealed, so a `switch` over a state is checked for exhaustiveness and
/// adding a ninth case surfaces every place that needs updating.
sealed class ViewState<T> extends Equatable {
  const ViewState();

  /// The data this state carries, from whichever field holds it.
  ///
  /// Enumerated rather than defaulted with `_` so that adding a new state
  /// forces an explicit decision here instead of silently returning null.
  T? get dataOrNull => switch (this) {
    LoadedState<T>(data: final T data) => data,
    RefreshingState<T>(data: final T data) => data,
    LoadingMoreState<T>(data: final T data) => data,
    SuccessState<T>(data: final T? data) => data,
    ErrorState<T>(previousData: final T? data) => data,
    InitialState<T>() || LoadingState<T>() || EmptyState<T>() => null,
  };

  bool get hasData => dataOrNull != null;

  /// True while any request is in flight, whether or not data is showing.
  /// Use it to disable a submit button or suppress a duplicate fetch.
  bool get isBusy =>
      this is LoadingState<T> ||
      this is RefreshingState<T> ||
      this is LoadingMoreState<T>;

  /// True only for the blocking, full-screen load — the one that should show
  /// a centred spinner rather than an inline one.
  bool get isInitialLoad => this is LoadingState<T>;

  bool get isRefreshing => this is RefreshingState<T>;

  bool get isLoadingMore => this is LoadingMoreState<T>;

  bool get hasError => this is ErrorState<T>;

  AppException? get errorOrNull => switch (this) {
    ErrorState<T>(exception: final AppException exception) => exception,
    _ => null,
  };

  /// Per-field errors when the failure was a rejected form submission.
  ///
  /// Saves every form from casting the exception itself: a field's
  /// `errorText` becomes `state.fieldErrors['email']?.first`.
  Map<String, List<String>> get fieldErrors => switch (errorOrNull) {
    ValidationException(fieldErrors: final Map<String, List<String>> errors) =>
      errors,
    _ => const <String, List<String>>{},
  };

  /// Paging position, for the states that track one.
  PageInfo get pageInfo => switch (this) {
    LoadedState<T>(pageInfo: final PageInfo info) => info,
    RefreshingState<T>(pageInfo: final PageInfo info) => info,
    LoadingMoreState<T>(pageInfo: final PageInfo info) => info,
    _ => PageInfo.single,
  };

  /// Whether a "load more" is worth firing right now.
  ///
  /// Guards on the settled [LoadedState] specifically: firing while already
  /// loading more is the double-fetch bug every infinite list starts with.
  bool get canLoadMore => this is LoadedState<T> && pageInfo.hasMore;
}

/// Nothing has been requested yet. Distinct from [LoadingState] so a screen
/// can tell "never asked" from "asking now" — useful for lazy tabs that
/// should not fetch until first shown.
final class InitialState<T> extends ViewState<T> {
  const InitialState();

  @override
  List<Object?> get props => const <Object?>[];
}

/// First load, with nothing to show behind it.
final class LoadingState<T> extends ViewState<T> {
  const LoadingState();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Data arrived and is not empty.
final class LoadedState<T> extends ViewState<T> {
  const LoadedState(this.data, {this.pageInfo = PageInfo.single});

  final T data;

  @override
  final PageInfo pageInfo;

  LoadedState<T> copyWith({T? data, PageInfo? pageInfo}) =>
      LoadedState<T>(data ?? this.data, pageInfo: pageInfo ?? this.pageInfo);

  @override
  List<Object?> get props => <Object?>[data, pageInfo];
}

/// The request succeeded and came back with nothing.
///
/// Kept separate from [LoadedState] with an empty list because the two want
/// completely different UI — an illustration and a "create your first lead"
/// call to action, versus a list.
final class EmptyState<T> extends ViewState<T> {
  const EmptyState({this.message});

  /// Optional override for the default empty copy, when a filtered list wants
  /// "no leads match this search" instead of "no leads yet".
  final String? message;

  @override
  List<Object?> get props => <Object?>[message];
}

/// A reload of page one while the existing data stays on screen.
final class RefreshingState<T> extends ViewState<T> {
  const RefreshingState(this.data, {this.pageInfo = PageInfo.single});

  final T data;

  @override
  final PageInfo pageInfo;

  @override
  List<Object?> get props => <Object?>[data, pageInfo];
}

/// Fetching the next page, with the current pages still on screen.
final class LoadingMoreState<T> extends ViewState<T> {
  const LoadingMoreState(this.data, {required this.pageInfo});

  final T data;

  @override
  final PageInfo pageInfo;

  @override
  List<Object?> get props => <Object?>[data, pageInfo];
}

/// A write completed — the state a form bloc ends on.
///
/// Read it from a `BlocListener` rather than a builder: the reaction to a
/// success is a snackbar and a pop, not a rebuild. [data] carries the created
/// or updated entity when the caller needs it.
final class SuccessState<T> extends ViewState<T> {
  const SuccessState({this.data, this.message});

  final T? data;
  final String? message;

  @override
  List<Object?> get props => <Object?>[data, message];
}

/// The request failed.
///
/// [previousData] is what was on screen beforehand. It is what lets a failed
/// "load more" show a retry footer under a list that is still perfectly
/// usable, instead of throwing away twenty rows the user was reading.
final class ErrorState<T> extends ViewState<T> {
  const ErrorState(this.exception, {this.previousData});

  final AppException exception;
  final T? previousData;

  /// Safe to render directly; the exception decides its own wording.
  String get message => exception.userMessage;

  bool get isRetryable => exception.isRetryable;

  @override
  List<Object?> get props => <Object?>[exception, previousData];
}

/// Paging position for a list-backed state.
class PageInfo extends Equatable {
  const PageInfo({required this.page, required this.hasMore, this.totalItems});

  /// For screens that are not paginated at all.
  static const PageInfo single = PageInfo(page: 1, hasMore: false);

  final int page;
  final bool hasMore;
  final int? totalItems;

  PageInfo get next => PageInfo(page: page + 1, hasMore: hasMore, totalItems: totalItems);

  @override
  List<Object?> get props => <Object?>[page, hasMore, totalItems];
}
