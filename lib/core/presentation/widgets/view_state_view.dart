import 'package:flutter/material.dart';

import '../../error/app_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../view_state.dart';

/// Renders any [ViewState] without the screen writing a `switch`.
///
/// The rule it encodes, and the reason it exists: **data wins**. If there is
/// anything to show, it is shown — through a refresh, through a load-more,
/// even through a failed request — and the loading or error signal is layered
/// on top rather than replacing it. Screens that hand-roll this almost always
/// end up flashing an empty view mid-refresh.
///
/// Only the no-data cases get a full-screen treatment, and each has a default
/// that a feature can override where it matters.
class ViewStateView<T> extends StatelessWidget {
  const ViewStateView({
    super.key,
    required this.state,
    required this.builder,
    this.onRetry,
    this.emptyTitle = 'Nothing here yet',
    this.emptyMessage,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyAction,
    this.initialBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.showInlineErrorBanner = true,
  });

  final ViewState<T> state;

  /// Builds the real content. Called whenever data exists, whatever else is
  /// happening around it.
  final Widget Function(BuildContext context, T data) builder;

  /// Invoked by the retry affordance. Usually re-dispatches the load event.
  final VoidCallback? onRetry;

  final String emptyTitle;
  final String? emptyMessage;
  final IconData emptyIcon;

  /// Call to action on the empty view — "Add your first lead".
  final Widget? emptyAction;

  final WidgetBuilder? initialBuilder;
  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? emptyBuilder;
  final Widget Function(BuildContext context, AppException exception)?
  errorBuilder;

  /// Whether a failure *while data is on screen* shows a strip above the
  /// content. Turn it off when the screen prefers a snackbar via
  /// `BlocListener`.
  final bool showInlineErrorBanner;

  @override
  Widget build(BuildContext context) {
    final T? data = state.dataOrNull;

    if (data != null) {
      final Widget content = builder(context, data);
      final AppException? error = state.errorOrNull;

      if (error == null || !showInlineErrorBanner) {
        return content;
      }

      // The request failed but the previous data is still good — say so
      // without taking the content away.
      return Column(
        children: <Widget>[
          _ErrorBanner(exception: error, onRetry: onRetry),
          Expanded(child: content),
        ],
      );
    }

    return switch (state) {
      // Reachable only when T is itself nullable and the load genuinely
      // produced null — the content builder is still the right answer.
      LoadedState<T>(data: final T loaded) => builder(context, loaded),

      InitialState<T>() =>
        initialBuilder?.call(context) ?? const SizedBox.shrink(),

      LoadingState<T>() =>
        loadingBuilder?.call(context) ?? const _CentredSpinner(),

      EmptyState<T>(message: final String? message) =>
        emptyBuilder?.call(context) ??
            _EmptyView(
              icon: emptyIcon,
              title: emptyTitle,
              message: message ?? emptyMessage,
              action: emptyAction,
            ),

      ErrorState<T>(exception: final AppException exception) =>
        errorBuilder?.call(context, exception) ??
            _ErrorView(exception: exception, onRetry: onRetry),

      // These three carry data in every normal flow, so reaching here means
      // there is genuinely nothing yet — treat it as a first load.
      RefreshingState<T>() ||
      LoadingMoreState<T>() ||
      SuccessState<T>() => const _CentredSpinner(),
    };
  }
}

class _CentredSpinner extends StatelessWidget {
  const _CentredSpinner();

  @override
  Widget build(BuildContext context) => const Center(
    child: SizedBox(
      height: 28,
      width: 28,
      child: CircularProgressIndicator(strokeWidth: 2.4),
    ),
  );
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 46, color: context.palette.faint),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.type.sectionTitle,
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: context.type.bodyMuted,
              ),
            ],
            if (action != null) ...<Widget>[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.exception, this.onRetry});

  final AppException exception;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              exception is NetworkException
                  ? Icons.wifi_off_rounded
                  : Icons.error_outline_rounded,
              size: 46,
              color: AppColors.red,
            ),
            const SizedBox(height: 14),
            Text(
              exception.userMessage,
              textAlign: TextAlign.center,
              style: context.type.body,
            ),
            // Retry is offered only where it could plausibly help; a 403 or a
            // validation error will fail the same way every time.
            if (onRetry != null && exception.isRetryable) ...<Widget>[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.exception, this.onRetry});

  final AppException exception;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.redWashSoft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          children: <Widget>[
            Icon(Icons.error_outline_rounded, size: 18, color: AppColors.red),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                exception.userMessage,
                style: context.type.caption,
              ),
            ),
            if (onRetry != null && exception.isRetryable)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
