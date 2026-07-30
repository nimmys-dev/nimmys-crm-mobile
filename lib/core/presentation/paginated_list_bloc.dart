import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../network/api_client.dart';
import '../network/api_response.dart';
import '../utils/result.dart';
import 'view_state.dart';

/// Base event for any list screen.
///
/// Deliberately *not* sealed: features subclass it to add their own events
/// (`LeadFilterChanged`, `LeadSearchSubmitted`) and a sealed class cannot be
/// extended outside its own library.
abstract class ListEvent extends Equatable {
  const ListEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Fetch the first page. Ignored when data is already present unless [force].
class ListLoadRequested extends ListEvent {
  const ListLoadRequested({this.force = false});

  final bool force;

  @override
  List<Object?> get props => <Object?>[force];
}

/// Pull-to-refresh: reload page one, keeping the current rows visible.
class ListRefreshRequested extends ListEvent {
  const ListRefreshRequested();
}

/// Infinite scroll: append the next page.
class ListLoadMoreRequested extends ListEvent {
  const ListLoadMoreRequested();
}

/// A ready-made ViewModel for every paginated list in the app.
///
/// Subclasses supply [fetchPage] and nothing else — load, refresh, append,
/// empty detection, error recovery and the eight [ViewState] transitions are
/// all inherited. That is the difference between adding a list screen in
/// twenty lines and re-deriving the same paging bugs each time.
///
/// The accumulated [items] and [pageInfo] are held as fields rather than read
/// back out of the current state. It matters for error recovery: when a
/// "load more" fails, the state becomes an [ErrorState], but the paging
/// position survives here, so retrying resumes from page 3 instead of
/// restarting at page 1.
abstract class PaginatedListBloc<I> extends Bloc<ListEvent, ViewState<List<I>>> {
  PaginatedListBloc({this.pageSize = 20}) : super(InitialState<List<I>>()) {
    on<ListLoadRequested>(_onLoad);
    on<ListRefreshRequested>(_onRefresh);
    on<ListLoadMoreRequested>(_onLoadMore);
  }

  final int pageSize;

  /// Cancels in-flight work when the bloc closes, so a screen popped
  /// mid-request does not hold the response — or emit into a closed bloc.
  final ApiCancelToken cancelToken = ApiCancelToken();

  List<I> _items = <I>[];
  PageInfo _pageInfo = PageInfo.single;

  /// The rows accumulated so far, across every page fetched.
  @protected
  List<I> get items => List<I>.unmodifiable(_items);

  @protected
  PageInfo get pageInfo => _pageInfo;

  /// Fetches one page. The only method a subclass must write.
  ///
  /// [isRefresh] lets an implementation bypass a cache on pull-to-refresh
  /// while still serving page one from cache on a cold open.
  @protected
  Future<Result<PaginatedData<I>>> fetchPage(
    int page, {
    required bool isRefresh,
  });

  /// Copy for the empty state, overridable per feature ("No leads yet").
  @protected
  String? get emptyMessage => null;

  // ------------------------------------------------------------------ Load

  Future<void> _onLoad(
    ListLoadRequested event,
    Emitter<ViewState<List<I>>> emit,
  ) async {
    // Re-entering a tab should not refetch what is already there.
    if (!event.force && (state.hasData || state.isBusy)) {
      return;
    }

    emit(LoadingState<List<I>>());
    _emitPage(emit, await fetchPage(1, isRefresh: false), replace: true);
  }

  // --------------------------------------------------------------- Refresh

  Future<void> _onRefresh(
    ListRefreshRequested event,
    Emitter<ViewState<List<I>>> emit,
  ) async {
    if (state.isBusy) {
      return;
    }

    // With rows on screen this is a refresh; on a cold start there is nothing
    // to keep visible, so it is really a first load.
    emit(
      _items.isEmpty
          ? LoadingState<List<I>>()
          : RefreshingState<List<I>>(_items, pageInfo: _pageInfo),
    );

    final Result<PaginatedData<I>> result = await fetchPage(1, isRefresh: true);

    // A failed refresh must not discard good data — show the rows that are
    // already there and let the UI surface the error alongside them.
    _emitPage(emit, result, replace: true, keepDataOnError: _items.isNotEmpty);
  }

  // -------------------------------------------------------------- Load more

  Future<void> _onLoadMore(
    ListLoadMoreRequested event,
    Emitter<ViewState<List<I>>> emit,
  ) async {
    // `isBusy` is the guard that stops a fast scroll from firing the same
    // page three times before the first response lands.
    if (state.isBusy || !_pageInfo.hasMore || _items.isEmpty) {
      return;
    }

    emit(LoadingMoreState<List<I>>(_items, pageInfo: _pageInfo));

    final Result<PaginatedData<I>> result = await fetchPage(
      _pageInfo.page + 1,
      isRefresh: false,
    );

    _emitPage(emit, result, replace: false, keepDataOnError: true);
  }

  // ----------------------------------------------------------------- Shared

  /// Folds a page result into the next state.
  ///
  /// One place for the loaded/empty/error decision so the three handlers
  /// above cannot drift apart in how they interpret the same result.
  void _emitPage(
    Emitter<ViewState<List<I>>> emit,
    Result<PaginatedData<I>> result, {
    required bool replace,
    bool keepDataOnError = false,
  }) {
    result.fold(
      onSuccess: (PaginatedData<I> page) {
        _items = replace ? page.items : <I>[..._items, ...page.items];
        _pageInfo = PageInfo(
          page: page.page,
          hasMore: page.hasMore,
          totalItems: page.totalItems,
        );

        emit(
          _items.isEmpty
              ? EmptyState<List<I>>(message: emptyMessage)
              : LoadedState<List<I>>(_items, pageInfo: _pageInfo),
        );
      },
      onFailure: (exception) => emit(
        ErrorState<List<I>>(
          exception,
          previousData: keepDataOnError && _items.isNotEmpty ? _items : null,
        ),
      ),
    );
  }

  /// Drops a row locally after a successful delete, without a full refetch.
  @protected
  void removeItem(
    Emitter<ViewState<List<I>>> emit,
    bool Function(I item) test,
  ) {
    _items = _items.where((I item) => !test(item)).toList(growable: false);
    emit(
      _items.isEmpty
          ? EmptyState<List<I>>(message: emptyMessage)
          : LoadedState<List<I>>(_items, pageInfo: _pageInfo),
    );
  }

  /// Replaces a row in place after an edit, for the same reason.
  @protected
  void replaceItem(
    Emitter<ViewState<List<I>>> emit,
    bool Function(I item) test,
    I replacement,
  ) {
    _items = _items
        .map((I item) => test(item) ? replacement : item)
        .toList(growable: false);
    emit(LoadedState<List<I>>(_items, pageInfo: _pageInfo));
  }

  @override
  Future<void> close() {
    cancelToken.cancel('The list was closed.');
    return super.close();
  }
}
