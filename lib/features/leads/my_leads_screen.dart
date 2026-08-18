import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nimmys_crm/features/leads/cubit/leads/leads_cubit.dart';
import 'package:nimmys_crm/features/leads/model/lead_list_model.dart';
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
import '../../shared/widgets/app_gradient_header.dart';
import '../../shared/widgets/app_search_field.dart';
import '../../shared/widgets/app_section_card.dart';
import 'widgets/lead_contact_actions.dart';

/// Leads List screen — displays leads retrieved from `GET /api/leads` with
/// server-side pagination.
class MyLeadsScreen extends StatefulWidget {
  const MyLeadsScreen({super.key});

  @override
  State<MyLeadsScreen> createState() => _MyLeadsScreenState();
}

class _MyLeadsScreenState extends State<MyLeadsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LeadsCubit>().getLeads();
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
        context.read<LeadsCubit>().getLeads(search: value);
      }
    });
  }

  Future<void> _onRefresh() async {
    await context.read<LeadsCubit>().refreshLeads();
  }

  Future<void> _openCreateLead() async {
    final dynamic result = await context.push(AppRouteName.leadNew);
    if (result == true && mounted) {
      await context.read<LeadsCubit>().getLeads(refresh: true);
    }
  }

  void _onLeadsStateChanged(BuildContext context, LeadsState state) {
    final UIState<LeadListResponse>? uiState = state.leadListUIState;
    if (uiState?.status != Status.ERROR || state.leadList.isNotEmpty) {
      return;
    }
    ToastMessages.error(
      message:
          uiState?.errorType?.getText(context) ?? 'Failed to load leads',
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
            const AppGradientHeader(
              title: 'My Leads',
              eyebrow: 'LEAD MANAGEMENT',
              leading: AppBackButton(),
              actions: <Widget>[AppAvatar(initials: 'AB')],
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
              child: BlocConsumer<LeadsCubit, LeadsState>(
                listenWhen: (LeadsState previous, LeadsState current) =>
                    previous.leadListUIState?.status !=
                    current.leadListUIState?.status,
                listener: _onLeadsStateChanged,
                builder: (BuildContext context, LeadsState state) {
                  return _MyLeadsBody(
                    state: state,
                    onRefresh: _onRefresh,
                    onRetry: _onRefresh,
                    onPreviousPage: () {
                      final LeadPagination? pagination = state.leadPagination;
                      if (pagination != null && pagination.hasPreviousPage) {
                        context
                            .read<LeadsCubit>()
                            .goToLeadsPage(pagination.previousPage);
                      }
                    },
                    onNextPage: () {
                      final LeadPagination? pagination = state.leadPagination;
                      if (pagination != null && pagination.hasNextPage) {
                        context
                            .read<LeadsCubit>()
                            .goToLeadsPage(pagination.nextPage);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: MyLeadsFab(
          onPressed: _openCreateLead,
        ),
      ),
    );
  }
}

/// Picks between the list and its loading / error / empty stand-ins.
class _MyLeadsBody extends StatelessWidget {
  const _MyLeadsBody({
    required this.state,
    required this.onRefresh,
    required this.onRetry,
    required this.onPreviousPage,
    required this.onNextPage,
  });

  final LeadsState state;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onRetry;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;

  @override
  Widget build(BuildContext context) {
    final List<LeadItemData> leads = state.leadList;
    final Status? status = state.leadListUIState?.status;
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
                state.leadListUIState?.errorType?.getText(context) ??
                    'Something went wrong. Please try again.',
                style: context.type.bodyMuted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              AppOutlineButton(
                label: 'Retry',
                icon: Icons.refresh_rounded,
                onPressed: () => onRetry(),
              ),
            ],
          ),
        ),
      );
    }

    if (leads.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: AppColors.red,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: MyLeadsEmptyState(
                hasQuery: state.leadSearchQuery.isNotEmpty,
              ),
            ),
          ],
        ),
      );
    }

    final LeadPagination? pagination = state.leadPagination;
    final int currentPage = pagination?.currentPage ?? 1;
    final int perPage = pagination?.perPage ?? 10;
    final int from = pagination?.from ?? ((currentPage - 1) * perPage + 1);
    final int to = pagination?.to ?? (from + leads.length - 1);
    final int total = pagination?.total ?? leads.length;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.red,
      child: ListView.builder(
        padding: const EdgeInsets.only(
          left: AppSpacing.gutter,
          right: AppSpacing.gutter,
          bottom: AppSpacing.xl + 40,
        ),
        itemCount: leads.length + 2, // 1 for count header, 1 for pagination footer
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return MyLeadsCount(
              from: from,
              to: to,
              total: total,
              isLoading: isLoading,
            );
          }

          if (index == leads.length + 1) {
            if (pagination == null) return const SizedBox.shrink();
            return MyLeadsPaginationBar(
              pagination: pagination,
              isLoading: isLoading,
              onPreviousPage: onPreviousPage,
              onNextPage: onNextPage,
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
            : 'Showing $from–$to of $total leads');

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
  const MyLeadTile({
    super.key,
    required this.lead,
    this.onTap,
    this.onCall,
  });

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
              AppInitialBubble(letter: displayName, size: 42, isAccent: false),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
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
                            lead.reference!.trim().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: context.palette.redWash,
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                            ),
                            child: Text(
                              lead.reference!.trim(),
                              style: context.type.caption.copyWith(
                                color: AppColors.red,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
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
                    if (description.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: context.type.bodyMuted.copyWith(fontSize: 12.5),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        if (lead.source != null &&
                            lead.source!.trim().isNotEmpty)
                          AppTag(
                            label: lead.source!.trim().toUpperCase(),
                            icon: Icons.campaign_outlined,
                            isAccent: false,
                          ),
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
                ),
              ),
              if (phone.isNotEmpty) ...<Widget>[
                const SizedBox(width: AppSpacing.xs),
                LeadContactActions(
                  name: displayName,
                  mobile: phone,
                  enquiry: description.isNotEmpty ? description : null,
                  onCall: onCall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Server-side pagination controls (Previous, Page X of Y, Next, Total records).
class MyLeadsPaginationBar extends StatelessWidget {
  const MyLeadsPaginationBar({
    super.key,
    required this.pagination,
    required this.onPreviousPage,
    required this.onNextPage,
    this.isLoading = false,
  });

  final LeadPagination pagination;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final int current = pagination.currentPage ?? 1;
    final int last = pagination.lastPage ?? 1;
    final int total = pagination.total ?? 0;
    final bool canGoPrev = pagination.hasPreviousPage && !isLoading;
    final bool canGoNext = pagination.hasNextPage && !isLoading;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: context.palette.line),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            // Previous Button
            InkWell(
              onTap: canGoPrev ? onPreviousPage : null,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: canGoPrev
                      ? context.palette.redWash
                      : context.palette.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: canGoPrev
                        ? context.palette.redBorder
                        : context.palette.line,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.chevron_left_rounded,
                      size: 18,
                      color: canGoPrev ? AppColors.red : context.palette.faint,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Prev',
                      style: context.type.caption.copyWith(
                        color:
                            canGoPrev ? AppColors.red : context.palette.faint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Page Indicator
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Page $current of $last',
                  style: context.type.body.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$total total records',
                  style: context.type.caption.copyWith(fontSize: 11),
                ),
              ],
            ),

            // Next Button
            InkWell(
              onTap: canGoNext ? onNextPage : null,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: canGoNext
                      ? context.palette.redWash
                      : context.palette.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: canGoNext
                        ? context.palette.redBorder
                        : context.palette.line,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Next',
                      style: context.type.caption.copyWith(
                        color:
                            canGoNext ? AppColors.red : context.palette.faint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: canGoNext ? AppColors.red : context.palette.faint,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nothing in this state.
class MyLeadsEmptyState extends StatelessWidget {
  const MyLeadsEmptyState({
    super.key,
    required this.hasQuery,
  });

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
