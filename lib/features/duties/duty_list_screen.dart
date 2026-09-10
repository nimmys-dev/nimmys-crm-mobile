import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nimmys_crm/core/preferences/app_preferences.dart';
import 'package:nimmys_crm/enum/status.dart';
import 'package:nimmys_crm/features/dashboard/cubit/dashboard_cubit.dart';
import 'package:nimmys_crm/features/duties/model/tasks_list_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../routing/app_route_name.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_gradient_header.dart';
import '../../shared/widgets/app_search_field.dart';
import '../../shared/widgets/app_section_card.dart';

class DutyListScreen extends StatefulWidget {
  final String? taskStatus; // e.g. 'overdue_duty', 'today_duty', etc.
  final String? scope;
  const DutyListScreen({
    super.key,
    required this.taskStatus,
    required this.scope,
  });

  @override
  State<DutyListScreen> createState() => _DutyListScreenState();
}

class _DutyListScreenState extends State<DutyListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _query = '';
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Initial fetch: page 1, using the given taskStatus as filter
      await context.read<DashboardCubit>().getTaskCounts(
        refresh: true,
        filter: widget.taskStatus ?? '',
        scope: widget.scope,
        page: 1,
      );
      if (mounted) setState(() => _isInitialLoading = false);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final cubit = context.read<DashboardCubit>();
    final state = cubit.state;
    // Prevent multiple loads
    if (state.isLoadingMoreTasks ||
        state.taskCountsUIState?.status == Status.LOADING) {
      return;
    }
    final pagination = state.taskPagination;
    if (pagination == null || !pagination.hasNextPage) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final pixels = _scrollController.position.pixels;
    if (pixels >= maxScroll - 200) {
      // Load next page
      cubit.goToTaskPage(pagination.nextPage);
    }
  }

  Future<void> _refreshTasks() async {
    await context.read<DashboardCubit>().refreshTaskCounts();
  }

  void _onSearchChanged(String value) {
    _query = value;
    // When search changes, we re‑fetch page 1 with the current filter.
    // The cubit will replace the list because refresh is true.
    context.read<DashboardCubit>().getTaskCounts(
      refresh: true,
      filter: widget.taskStatus ?? '',
      scope: widget.scope,
      page: 1,
    );
  }

  List<Task> _visibleDuties(List<Task> all_tasks) {
    final needle = _query.trim().toLowerCase();
    if (needle.isEmpty) return all_tasks;
    return all_tasks.where((task) {
      final title = task.title?.toLowerCase() ?? '';
      final description = task.description?.toLowerCase() ?? '';
      final assignee = task.assignedUser?.name?.toLowerCase() ?? '';
      return title.contains(needle) ||
          description.contains(needle) ||
          assignee.contains(needle);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: context.palette.canvas,
          body: BlocBuilder<DashboardCubit, DashboardState>(
            builder: (context, state) {
              final all_tasks = state.taskList ?? [];
              final isLoading =
                  _isInitialLoading ||
                  (state.taskCountsUIState?.status == Status.LOADING &&
                      all_tasks.isEmpty);
              final hasError = state.taskCountsUIState?.status == Status.ERROR;
              final error = state.taskCountsUIState?.errorType;
              final total = state.taskPagination?.total ?? all_tasks.length;
              final hasMore = state.taskPagination?.hasNextPage ?? false;
              final isLoadingMore = state.isLoadingMoreTasks;

              return Column(
                children: <Widget>[
                  AppGradientHeader(
                    title: 'Duties',
                    eyebrow: 'MY DUTIES',
                    leading: const AppBackButton(),
                    actions: const <Widget>[],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      AppSpacing.md,
                      AppSpacing.gutter,
                      AppSpacing.sm,
                    ),
                    child: AppSearchField(
                      hint: 'Search duties, people…',
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: KeyedSubtree(
                        key: ValueKey<String>(
                          isLoading
                              ? 'loading'
                              : hasError && all_tasks.isEmpty
                              ? 'error'
                              : all_tasks.isEmpty
                              ? 'empty'
                              : 'list',
                        ),
                        child: _buildBody(
                          context,
                          isLoading: isLoading,
                          hasError: hasError,
                          error: error,
                          all_tasks: all_tasks,
                          totalTaskCount: total,
                          hasMore: hasMore,
                          isLoadingMore: isLoadingMore,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          floatingActionButton: DutyListFab(
            onPressed: () => context.push(AppRouteName.dutyAdd),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required bool isLoading,
    required bool hasError,
    required Object? error,
    required List<Task> all_tasks,
    required int totalTaskCount,
    required bool hasMore,
    required bool isLoadingMore,
  }) {
    if (isLoading) {
      return RefreshIndicator(
        onRefresh: _refreshTasks,
        child: const _AlwaysScrollableBody(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (hasError && all_tasks.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshTasks,
        child: _AlwaysScrollableBody(
          child: _ErrorRetry(onRetry: _refreshTasks),
        ),
      );
    }

    final tasks = _visibleDuties(all_tasks);

    if (tasks.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshTasks,
        child: _AlwaysScrollableBody(
          child: DutyEmptyState(hasQuery: _query.isNotEmpty),
        ),
      );
    }

    // FIX: itemCount = tasks.length + 2 so footer is reachable
    return RefreshIndicator(
      onRefresh: _refreshTasks,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          left: AppSpacing.gutter,
          right: AppSpacing.gutter,
          bottom: AppSpacing.xl,
        ),
        itemCount: tasks.length + 2,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return DutyListCount(count: tasks.length, total: totalTaskCount);
          }

          if (index <= tasks.length) {
            final task = tasks[index - 1];
            // FIX: remove outer InkWell, let DutyListTile handle navigation
            return DutyListTile(task: task);
          }

          // Footer: loading or end message
          return _buildFooter(hasMore, isLoadingMore);
        },
      ),
    );
  }

  Widget _buildFooter(bool hasMore, bool isLoadingMore) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.red),
          ),
        ),
      );
    }
    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            'No more tasks',
            style: TextStyle(fontSize: 12, color: context.palette.muted),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

// ---------------------------------------------------------------------------
// Supporting widgets (unchanged except where noted)
// ---------------------------------------------------------------------------

class _AlwaysScrollableBody extends StatelessWidget {
  const _AlwaysScrollableBody({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) => ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: <Widget>[SizedBox(height: constraints.maxHeight, child: child)],
    ),
  );
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.error_outline, size: 48, color: context.palette.muted),
          const SizedBox(height: AppSpacing.sm),
          Text('Could not load duties', style: context.type.cardTitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Please check your connection and try again.',
            style: context.type.bodyMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(label: 'Retry', onPressed: onRetry),
        ],
      ),
    );
  }
}

class DutyListCount extends StatelessWidget {
  const DutyListCount({super.key, required this.count, required this.total});
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs, left: 2),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.fact_check_outlined,
            size: 15,
            color: context.palette.muted,
          ),
          const SizedBox(width: 5),
          Text('$count of $total Tasks', style: context.type.caption),
        ],
      ),
    );
  }
}

class DutyListTile extends StatefulWidget {
  const DutyListTile({super.key, required this.task});
  final Task task;

  @override
  State<DutyListTile> createState() => _DutyListTileState();
}

class _DutyListTileState extends State<DutyListTile> {
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'upcoming':
        return AppColors.purple;
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'overdue':
        return AppColors.red;
      case 'ongoing':
        return Colors.blue;
      case 'approved':
        return const Color.fromARGB(255, 0, 158, 11);
      default:
        return context.palette.ink;
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignee = widget.task.assignedUser?.name ?? 'Unassigned';
    final status = widget.task.status ?? 'unknown';

    // FIX: this is now the ONLY navigation trigger for a tile
    return InkWell(
      onTap: () {
        if (widget.task.id != null) {
          context.push(AppRouteName.taskDetailsFor(widget.task.id!));
        } else {
          context.push(AppRouteName.taskDetails);
        }
      },
      child: AppSectionCard(
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppIconChip(
                icon: status == 'completed'
                    ? Icons.check_circle_outline_rounded
                    : Icons.fact_check_outlined,
                size: 38,
                backgroundColor: _getStatusColor(status).withOpacity(0.15),
                iconColor: _getStatusColor(status),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      widget.task.title ?? 'Untitled',
                      style: context.type.cardTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.task.description ?? '',
                      style: context.type.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        AppTag(
                          label: widget.task.status ?? 'Unknown',
                          tagColor: _getStatusColor(widget.task.status),
                        ),
                        AppTag(
                          label: assignee,
                          icon: Icons.person_outline_rounded,
                          isAccent: false,
                        ),
                        if (widget.task.taskType != null)
                          AppTag(
                            label: widget.task.taskType!.toUpperCase(),
                            icon: Icons.repeat_rounded,
                            isAccent: false,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DutyEmptyState extends StatelessWidget {
  const DutyEmptyState({super.key, required this.hasQuery});
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final String title;
    final String message;

    if (hasQuery) {
      icon = Icons.search_off_rounded;
      title = 'No matching duties';
      message = 'Nothing matches that search.';
    } else {
      icon = Icons.event_available_outlined;
      title = 'No duties';
      message = 'You have no duties assigned yet.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: context.palette.redWash,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: AppColors.red),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: context.type.cardTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: context.type.bodyMuted,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class DutyListFab extends StatelessWidget {
  const DutyListFab({super.key, this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.red.withValues(alpha: 0.42),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: AppColors.red,
        foregroundColor: AppColors.white,
        elevation: 0,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}
