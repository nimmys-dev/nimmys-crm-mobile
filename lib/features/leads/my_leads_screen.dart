import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nimmys_crm/features/dashboard/cubit/dashboard_cubit.dart';
import 'package:nimmys_crm/features/dashboard/model/lead_count_model.dart';
import 'package:nimmys_crm/features/leads/model/lead_list_model.dart';
import 'package:nimmys_crm/features/leads/widgets/status_chip.dart';
import 'package:nimmys_crm/shared/widgets/app_gradient_header.dart';
import 'package:nimmys_crm/utils/toast_messages.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/phone_dialer.dart';
import '../../data/ui_state/ui_state.dart';
import '../../enum/status.dart';
import '../../routing/app_route_name.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_search_field.dart';
import '../../shared/widgets/app_section_card.dart';
import 'widgets/lead_contact_actions.dart';

/// Leads List screen — displays leads retrieved from the DashboardCubit
/// with server‑side pagination and filtering.
class MyLeadsScreen extends StatefulWidget {
  final String? scope;
  final String? status;
  final bool isAppHeaderRequired;

  const MyLeadsScreen({
    super.key,
    required this.isAppHeaderRequired,
    required this.scope,
    this.status,
  });

  @override
  State<MyLeadsScreen> createState() => _MyLeadsScreenState();
}

class _MyLeadsScreenState extends State<MyLeadsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await context.read<DashboardCubit>().getLeads(
          refresh: true,
          filter: widget.status,
          scope: widget.scope,
        );
        if (mounted) setState(() => _isInitialLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        context.read<DashboardCubit>().getLeads(
          refresh: true,
          filter: value,
          scope: widget.scope,
        );
      }
    });
  }

  Future<void> _onRefresh() async {
    await context.read<DashboardCubit>().refreshLeads();
  }

  Future<void> _openCreateLead() async {
    final dynamic result = await context.push(AppRouteName.leadNew);
    if (result == true && mounted) {
      await context.read<DashboardCubit>().getLeads(
        refresh: true,
        filter: _searchController.text,
        scope: widget.scope,
      );
    }
  }

  void _onLeadsStateChanged(BuildContext context, DashboardState state) {
    final UIState<LeadCountModel>? uiState = state.leadListUIState;
    if (uiState?.status != Status.ERROR ||
        (state.leadList?.isNotEmpty ?? false)) {
      return;
    }
    ToastMessages.error(
      message: uiState?.errorType?.getText(context) ?? 'Failed to load leads',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: context.palette.canvas,
        body: Column(
          children: <Widget>[
            Visibility(
              visible: widget.isAppHeaderRequired,
              child: const AppGradientHeader(
                title: 'My Leads',
                eyebrow: 'LEAD MANAGEMENT',
                leading: AppBackButton(),
                actions: <Widget>[AppAvatar(initials: 'AB')],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.md,
                AppSpacing.gutter,
                AppSpacing.sm,
              ),
              child: AppSearchField(
                hint: 'Search by name, mobile, reference or item…',
                controller: _searchController,
                onChanged: _onSearchChanged,
              ),
            ),
            Expanded(
              child: BlocConsumer<DashboardCubit, DashboardState>(
                listenWhen: (previous, current) =>
                    previous.leadListUIState?.status !=
                    current.leadListUIState?.status,
                listener: _onLeadsStateChanged,
                builder: (context, state) {
                  final leads = state.leadList ?? <LeadItemData>[];
                  final status = state.leadListUIState?.status;
                  final viewKey = _isInitialLoading
                      ? 'loading'
                      : status == Status.LOADING && leads.isEmpty
                      ? 'loading'
                      : status == Status.ERROR && leads.isEmpty
                      ? 'error'
                      : leads.isEmpty
                      ? 'empty'
                      : 'list';
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: KeyedSubtree(
                      key: ValueKey<String>(viewKey),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 50),
                        child: _isInitialLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.red,
                                  ),
                                ),
                              )
                            : _MyLeadsBody(
                                state: state,
                                onRefresh: _onRefresh,
                                onRetry: _onRefresh,
                                onPreviousPage: () {
                                  final pagination = state.leadPagination;
                                  if (pagination != null &&
                                      pagination.hasPreviousPage) {
                                    context.read<DashboardCubit>().goToLeadPage(
                                      pagination.previousPage,
                                    );
                                  }
                                },
                                onNextPage: () {
                                  final pagination = state.leadPagination;
                                  if (pagination != null &&
                                      pagination.hasNextPage) {
                                    context.read<DashboardCubit>().goToLeadPage(
                                      pagination.nextPage,
                                    );
                                  }
                                },
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: MyLeadsFab(onPressed: _openCreateLead),
      ),
    );
  }
}

/// Picks between the list and its loading / error / empty stand‑ins.
class _MyLeadsBody extends StatefulWidget {
  const _MyLeadsBody({
    required this.state,
    required this.onRefresh,
    required this.onRetry,
    required this.onPreviousPage,
    required this.onNextPage,
  });

  final DashboardState state;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onRetry;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;

  @override
  State<_MyLeadsBody> createState() => _MyLeadsBodyState();
}

class _MyLeadsBodyState extends State<_MyLeadsBody> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final cubit = context.read<DashboardCubit>();
    final currentState = cubit.state;
    // Only trigger if not already loading, there is a next page, and near bottom
    if (currentState.leadListUIState?.status == Status.LOADING) return;
    final pagination = currentState.leadPagination;
    if (pagination == null || !pagination.hasNextPage) return;
    const threshold = 200.0;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - threshold) {
      cubit.goToLeadPage(pagination.nextPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<LeadItemData> leads = widget.state.leadList ?? [];
    final Status? status = widget.state.leadListUIState?.status;
    final bool isLoading = status == Status.LOADING;

    if (leads.isEmpty &&
        (isLoading || status == null || status == Status.INITIAL)) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.red),
        ),
      );
    }

    if (leads.isEmpty && status == Status.ERROR) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.red.withValues(alpha: 0.8),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Failed to load leads',
                style: context.type.cardTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.state.leadListUIState?.errorType?.getText(context) ??
                    'Something went wrong. Please try again.',
                style: context.type.bodyMuted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              AppOutlineButton(
                label: 'Retry',
                icon: Icons.refresh_rounded,
                onPressed: () => widget.onRetry(),
              ),
            ],
          ),
        ),
      );
    }

    if (leads.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        color: AppColors.red,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: MyLeadsEmptyState(
                hasQuery: widget.state.currentLeadFilter?.isNotEmpty ?? false,
              ),
            ),
          ],
        ),
      );
    }

    final pagination = widget.state.leadPagination;
    final int currentPage = pagination?.currentPage ?? 1;
    final int perPage = pagination?.perPage ?? 10;
    final int from = pagination?.from ?? ((currentPage - 1) * perPage + 1);
    final int to = pagination?.to ?? (from + leads.length - 1);
    final int total = pagination?.total ?? leads.length;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: AppColors.red,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(
          left: AppSpacing.gutter,
          right: AppSpacing.gutter,
          bottom: AppSpacing.xl + 40,
        ),
        itemCount: leads.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return MyLeadsCount(
              from: from,
              to: to,
              total: total,
              isLoading: isLoading,
            );
          }

          final LeadItemData lead = leads[index - 1];
          return MyLeadTile(
            lead: lead,
            onTap: () {
              if (lead.id != null) {
                context.push(AppRouteName.leadDetailsFor(lead.id!));
              } else {
                context.push(AppRouteName.leadDetails);
              }
            },
            onCall: lead.phone != null && lead.phone!.isNotEmpty
                ? () => PhoneDialer.call(context, lead.phone!)
                : null,
          );
        },
      ),
    );
  }
}

/// "Showing 1–10 of 25 leads" strip above the rows.
class MyLeadsCount extends StatelessWidget {
  const MyLeadsCount({
    super.key,
    required this.from,
    required this.to,
    required this.total,
    this.isLoading = false,
  });

  final int from;
  final int to;
  final int total;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final String label = total == 0
        ? 'No leads'
        : (total <= to - from + 1
              ? '$total lead${total == 1 ? '' : 's'}'
              : 'Showing $total leads');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs, left: 2, top: 4),
      child: Row(
        children: <Widget>[
          Icon(Icons.groups_outlined, size: 15, color: context.palette.muted),
          const SizedBox(width: 5),
          Text(label, style: context.type.caption),
          if (isLoading) ...<Widget>[
            const SizedBox(width: 8),
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.red),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One lead row displaying Reference, Name, Phone, Source, Assigned To,
/// Created By and Description.
class MyLeadTile extends StatelessWidget {
  const MyLeadTile({super.key, required this.lead, this.onTap, this.onCall});

  final LeadItemData lead;
  final VoidCallback? onTap;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    final String displayName = lead.name?.trim().isNotEmpty == true
        ? lead.name!.trim()
        : 'Unnamed Lead';

    final String phone = lead.phone ?? '';
    final String description = lead.cleanDescription;

    return AppSectionCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: context.palette.inkWash,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.palette.inkBorder),
                ),
                alignment: Alignment.center,
                child: Text(
                  lead.id != null ? '#${lead.id}' : '?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: context.palette.ink,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // --------------------------------------------------
                    // NAME + REFERENCE
                    // --------------------------------------------------
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            displayName,
                            style: context.type.cardTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (lead.reference != null &&
                            lead.reference!.trim().isNotEmpty) ...[
                          const SizedBox(width: AppSpacing.xs),
                          if (lead.status != null && lead.status!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: StatusChip(status: lead.status!),
                            ),
                        ],
                      ],
                    ),
                    // --------------------------------------------------
                    // PHONE
                    // --------------------------------------------------
                    if (phone.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.call_outlined,
                            size: 13,
                            color: context.palette.muted,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              phone,
                              style: context.type.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // --------------------------------------------------
                    // DESCRIPTION
                    // --------------------------------------------------
                    if (description.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: context.type.bodyMuted.copyWith(fontSize: 12.5),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    // --------------------------------------------------
                    // TAGS
                    // --------------------------------------------------
                    if (lead.source != null ||
                        lead.assignedTo != null ||
                        lead.createdBy != null) ...[
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: <Widget>[
                          if (lead.assignedTo != null &&
                              lead.assignedTo!.trim().isNotEmpty)
                            AppTag(
                              label: 'Assigned: ${lead.assignedTo!.trim()}',
                              icon: Icons.badge_outlined,
                              isAccent: false,
                            ),
                          if (lead.createdBy != null &&
                              lead.createdBy!.trim().isNotEmpty)
                            AppTag(
                              label: 'By: ${lead.createdBy!.trim()}',
                              icon: Icons.person_outline_rounded,
                              isAccent: false,
                            ),
                        ],
                      ),
                    ],
                    // --------------------------------------------------
                    // CONTACT ACTIONS
                    // ALWAYS BOTTOM RIGHT
                    // --------------------------------------------------
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: LeadContactActions(
                          key: ValueKey<int>(
                            lead.id ?? Random().nextInt(1000000),
                          ),
                          hasQuotation: lead.has_quotation == true,
                          name: displayName,
                          mobile: phone,
                          enquiry: description.isNotEmpty ? description : null,
                          onCall: onCall,
                          leadId: lead.id ?? 0,
                        ),
                      ),
                    ],
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

/// Nothing in this state.
class MyLeadsEmptyState extends StatelessWidget {
  const MyLeadsEmptyState({super.key, required this.hasQuery});

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    final String title = hasQuery ? 'No matching leads' : 'No leads found';
    final String message = hasQuery
        ? 'Nothing here matches that search.'
        : 'Leads you capture or that are assigned to you will appear here.';

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
              child: Icon(
                hasQuery ? Icons.search_off_rounded : Icons.groups_outlined,
                size: 32,
                color: AppColors.red,
              ),
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

/// Red compose button.
class MyLeadsFab extends StatelessWidget {
  const MyLeadsFab({super.key, this.onPressed});

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
