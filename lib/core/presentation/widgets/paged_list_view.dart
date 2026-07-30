import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../view_state.dart';
import 'view_state_view.dart';

/// An infinite-scrolling, pull-to-refresh list driven by a [ViewState].
///
/// Pairs with `PaginatedListBloc`: that class owns the paging state, this one
/// owns the paging *interaction*. Between them a feature's list screen is a
/// bloc with one `fetchPage` override and a row widget.
///
/// The trigger fires [onLoadMore] a screenful before the end rather than at
/// it, so the next page is usually in place by the time the user gets there
/// and the scroll never actually stops.
class PagedListView<I> extends StatefulWidget {
  const PagedListView({
    super.key,
    required this.state,
    required this.itemBuilder,
    required this.onRefresh,
    required this.onLoadMore,
    this.onRetry,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
    this.separatorHeight = 0,
    this.emptyTitle = 'Nothing here yet',
    this.emptyMessage,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyAction,
    this.loadMoreThreshold = 320,
  });

  final ViewState<List<I>> state;

  final Widget Function(BuildContext context, I item, int index) itemBuilder;

  /// Must complete when the refresh finishes, or the spinner never retracts.
  /// See `LeadListScreen` for the one-line bloc-stream implementation.
  final Future<void> Function() onRefresh;

  final VoidCallback onLoadMore;

  final VoidCallback? onRetry;

  final EdgeInsetsGeometry padding;
  final double separatorHeight;

  final String emptyTitle;
  final String? emptyMessage;
  final IconData emptyIcon;
  final Widget? emptyAction;

  /// Distance from the bottom, in pixels, at which the next page is fetched.
  final double loadMoreThreshold;

  @override
  State<PagedListView<I>> createState() => _PagedListViewState<I>();
}

class _PagedListViewState<I> extends State<PagedListView<I>> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) {
      return;
    }
    final ScrollPosition position = _controller.position;
    if (position.pixels < position.maxScrollExtent - widget.loadMoreThreshold) {
      return;
    }
    // `canLoadMore` is false while a page is already in flight, which is what
    // stops a fast flick from requesting page 2 several times over.
    if (widget.state.canLoadMore) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ViewStateView<List<I>>(
      state: widget.state,
      onRetry: widget.onRetry,
      emptyTitle: widget.emptyTitle,
      emptyMessage: widget.emptyMessage,
      emptyIcon: widget.emptyIcon,
      emptyAction: widget.emptyAction,
      // A list reports its own errors in the footer, right where the failed
      // page would have appeared.
      showInlineErrorBanner: false,
      builder: (BuildContext context, List<I> items) {
        return RefreshIndicator(
          onRefresh: widget.onRefresh,
          color: AppColors.red,
          child: ListView.separated(
            controller: _controller,
            padding: widget.padding,
            // Always scrollable, so pull-to-refresh still works when the
            // content is shorter than the viewport.
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: items.length + 1,
            separatorBuilder: (BuildContext context, int index) =>
                SizedBox(height: widget.separatorHeight),
            itemBuilder: (BuildContext context, int index) {
              if (index == items.length) {
                return _Footer(state: widget.state, onRetry: widget.onLoadMore);
              }
              return widget.itemBuilder(context, items[index], index);
            },
          ),
        );
      },
    );
  }
}

/// The strip below the last row: a spinner while the next page loads, or a
/// retry prompt if it failed.
class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.onRetry});

  final ViewState<List<dynamic>> state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      );
    }

    // An error *with* rows behind it is a failed load-more. The list above
    // stays usable and only the next page is offered again.
    final bool failedLoadingMore = state.hasError && state.hasData;
    if (failedLoadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          children: <Widget>[
            Text(
              state.errorOrNull?.userMessage ?? 'Could not load more.',
              textAlign: TextAlign.center,
              style: context.type.caption,
            ),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      );
    }

    return const SizedBox(height: 8);
  }
}
