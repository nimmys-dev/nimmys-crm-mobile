import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/presentation/paginated_list_bloc.dart';
import '../../../../core/presentation/view_state.dart';
import '../../../../core/presentation/widgets/paged_list_view.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/lead.dart';
import '../bloc/lead_list_bloc.dart';

/// A complete list screen, end to end, in about a hundred lines.
///
/// Worth reading as the summary of the whole architecture: the screen owns no
/// loading flags, no `try`/`catch`, no "is this the last page" arithmetic and
/// no error strings. It provides a bloc, describes one row, and says what
/// refresh and load-more mean. Everything else is inherited.
class LeadListScreen extends StatelessWidget {
  const LeadListScreen({super.key});

  static Route<void> route() => MaterialPageRoute<void>(
    builder: (BuildContext context) => const LeadListScreen(),
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LeadListBloc>(
      // `sl` appears here and nowhere deeper — this is the composition root
      // for the screen. The bloc itself took its repository by constructor.
      create: (BuildContext context) =>
          sl<LeadListBloc>()..add(const ListLoadRequested()),
      child: const _LeadListView(),
    );
  }
}

class _LeadListView extends StatelessWidget {
  const _LeadListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.canvas,
      appBar: AppBar(title: const Text('Leads')),
      body: Column(
        children: <Widget>[
          const _SearchField(),
          const _StatusFilterBar(),
          Expanded(
            child: BlocBuilder<LeadListBloc, ViewState<List<Lead>>>(
              builder: (BuildContext context, ViewState<List<Lead>> state) {
                return PagedListView<Lead>(
                  state: state,
                  onRefresh: () => _refresh(context),
                  onLoadMore: () => context.read<LeadListBloc>().add(
                    const ListLoadMoreRequested(),
                  ),
                  onRetry: () => context.read<LeadListBloc>().add(
                    const ListLoadRequested(force: true),
                  ),
                  emptyTitle: 'No leads',
                  emptyIcon: Icons.person_search_outlined,
                  itemBuilder: (BuildContext context, Lead lead, int index) =>
                      _LeadTile(lead: lead),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// `RefreshIndicator` keeps spinning until the future it was given
  /// completes, so this waits for the bloc to settle rather than returning
  /// immediately after dispatching.
  Future<void> _refresh(BuildContext context) {
    final LeadListBloc bloc = context.read<LeadListBloc>()
      ..add(const ListRefreshRequested());
    return bloc.stream.firstWhere(
      (ViewState<List<Lead>> state) => !state.isBusy,
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search leads',
          prefixIcon: Icon(Icons.search_rounded),
        ),
        // Fires on every keystroke; the bloc debounces before it reaches the
        // network, so this stays as simple as it looks.
        onChanged: (String value) =>
            context.read<LeadListBloc>().add(LeadSearchChanged(value)),
      ),
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar();

  @override
  Widget build(BuildContext context) {
    final LeadStatus? selected = context.select<LeadListBloc, LeadStatus?>(
      (LeadListBloc bloc) => bloc.statusFilter,
    );

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: <Widget>[
          for (final LeadStatus? status in <LeadStatus?>[
            null,
            ...LeadStatus.values,
          ])
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: ChoiceChip(
                label: Text(status?.label ?? 'All'),
                selected: selected == status,
                onSelected: (bool _) => context.read<LeadListBloc>().add(
                  LeadStatusFilterChanged(status),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LeadTile extends StatelessWidget {
  const _LeadTile({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final bool due = lead.isFollowUpDue();

    return ListTile(
      title: Text(lead.name, style: context.type.cardTitle),
      subtitle: Text(
        <String>[
          lead.mobile,
          if (lead.requiredItems != null) lead.requiredItems!,
        ].join(' · '),
        style: context.type.bodyMuted,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        lead.status.label,
        style: context.type.caption.copyWith(
          color: due ? AppColors.red : context.palette.muted,
        ),
      ),
    );
  }
}
