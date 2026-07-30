import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../network/api_client.dart';
import '../utils/result.dart';
import 'view_state.dart';

/// Base ViewModel for screens holding a single value rather than a list —
/// detail pages, forms, dashboards.
///
/// The two helpers below cover almost every handler a feature writes.
/// [loadData] is for reads and [submit] for writes; the difference is what
/// they emit on success ([LoadedState] versus [SuccessState]) and how they
/// treat existing data on failure. Routing both through here means the
/// loading/error transitions are identical everywhere without each bloc
/// re-implementing them.
abstract class ViewModelBloc<E, T> extends Bloc<E, ViewState<T>> {
  ViewModelBloc() : super(InitialState<T>());

  /// Cancelled on [close] so a screen popped mid-request abandons its work
  /// instead of emitting into a closed bloc.
  final ApiCancelToken cancelToken = ApiCancelToken();

  /// Runs a read.
  ///
  /// Emits [RefreshingState] rather than [LoadingState] when data is already
  /// present, so a re-fetch does not blank the screen. On failure the old
  /// data is carried into [ErrorState] for the same reason.
  ///
  /// [isEmpty] distinguishes "loaded nothing" from "loaded something" for
  /// types where that is meaningful; without it any success is [LoadedState].
  @protected
  Future<void> loadData(
    Emitter<ViewState<T>> emit,
    Future<Result<T>> Function() request, {
    bool Function(T data)? isEmpty,
    String? emptyMessage,
  }) async {
    final T? existing = state.dataOrNull;
    emit(existing == null ? LoadingState<T>() : RefreshingState<T>(existing));

    final Result<Object?> result = await request();

    emit(
      switch (result) {
        Success<Object?>(data: final Object? data) =>
          (isEmpty?.call(data as T) ?? false)
              ? EmptyState<T>(message: emptyMessage)
              : LoadedState<T>(data as T),
        FailureResult<Object?>(exception: final exception) =>
          ErrorState<T>(exception, previousData: existing),
      },
    );
  }

  /// Runs a write.
  ///
  /// Ends on [SuccessState], which a `BlocListener` reacts to by popping the
  /// route or showing a snackbar. Failure keeps the current data so a
  /// rejected form re-renders with the user's input intact rather than
  /// clearing everything they typed.
  @protected
  Future<void> submit(
    Emitter<ViewState<T>> emit,
    Future<Result<T>> Function() request, {
    String? successMessage,
  }) async {
    final T? existing = state.dataOrNull;
    emit(LoadingState<T>());

    final Result<T> result = await request();

    emit(
      result.fold(
        onSuccess: (T data) =>
            SuccessState<T>(data: data, message: successMessage),
        onFailure: (exception) =>
            ErrorState<T>(exception, previousData: existing),
      ),
    );
  }

  @override
  Future<void> close() {
    cancelToken.cancel('The screen was closed.');
    return super.close();
  }
}
