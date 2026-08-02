import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_response.dart';
import '../../../../core/presentation/event_transformers.dart';
import '../../../../core/presentation/paginated_list_bloc.dart';
import '../../../../core/presentation/view_state.dart';
import '../../../../core/usecase/use_case.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/lead.dart';
import '../../domain/repositories/lead_repository.dart';

// ------------------------------------------------------------------- Events

/// Narrow the list to one pipeline stage, or clear the filter with null.
class LeadStatusFilterChanged extends ListEvent {
  const LeadStatusFilterChanged(this.status);

  final LeadStatus? status;

  @override
  List<Object?> get props => <Object?>[status];
}

/// A keystroke in the search field. Debounced at registration.
class LeadSearchChanged extends ListEvent {
  const LeadSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => <Object?>[query];
}

/// Remove a lead, updating the list in place on success.
class LeadDeleted extends ListEvent {
  const LeadDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => <Object?>[id];
}

// --------------------------------------------------------------------- Bloc

/// The leads list ViewModel.
///
/// Everything about paging, refreshing, empty detection and the eight
/// [ViewState] transitions is inherited from [PaginatedListBloc]. What is
/// left below is only what is genuinely specific to leads: which endpoint to
/// call, the two filters, and what deleting does. That ratio is the point of
/// the base class — a second list screen costs about this much again.
class LeadListBloc extends PaginatedListBloc<Lead> {
  LeadListBloc(this._repository) : super(pageSize: 20) {
    on<LeadStatusFilterChanged>(_onStatusFilterChanged);
    // Debounced so typing "camera" is one request rather than six.
    on<LeadSearchChanged>(
      _onSearchChanged,
      transformer: debounce<LeadSearchChanged>(
        const Duration(milliseconds: 350),
      ),
    );
    on<LeadDeleted>(_onDeleted);
  }

  final LeadRepository _repository;

  LeadStatus? _status;
  String _query = '';

  LeadStatus? get statusFilter => _status;

  String get query => _query;

  /// The one method the base class needs. The cancel token is the bloc's own,
  /// so closing the screen abandons whatever page is in flight.
  @override
  Future<Result<PaginatedData<Lead>>> fetchPage(
    int page, {
    required bool isRefresh,
  }) => _repository.getLeads(
    params: PageParams(page: page, pageSize: pageSize, query: _query),
    status: _status,
    forceRefresh: isRefresh,
    cancelToken: cancelToken,
  );

  /// Empty means something different once a filter is on, and saying so is
  /// the difference between "add your first lead" and a confused user who
  /// has forty leads and a search box with a typo in it.
  @override
  String? get emptyMessage {
    if (_query.trim().isNotEmpty) {
      return 'No leads match "${_query.trim()}".';
    }
    if (_status != null) {
      return 'No ${_status!.label.toLowerCase()} leads right now.';
    }
    return 'Leads you add will show up here.';
  }

  void _onStatusFilterChanged(
    LeadStatusFilterChanged event,
    Emitter<ViewState<List<Lead>>> emit,
  ) {
    if (_status == event.status) {
      return;
    }
    _status = event.status;
    // A filter change invalidates the current pages, so restart at page one.
    add(const ListLoadRequested(force: true));
  }

  void _onSearchChanged(
    LeadSearchChanged event,
    Emitter<ViewState<List<Lead>>> emit,
  ) {
    if (_query == event.query) {
      return;
    }
    _query = event.query;
    add(const ListLoadRequested(force: true));
  }

  /// Deletes, then drops the row locally.
  ///
  /// Refetching the whole list after a delete would be simpler but throws
  /// away the user's scroll position and every page after the first.
  Future<void> _onDeleted(
    LeadDeleted event,
    Emitter<ViewState<List<Lead>>> emit,
  ) async {
    final Result<void> result = await _repository.deleteLead(event.id);

    result.fold(
      onSuccess: (_) => removeItem(emit, (Lead lead) => lead.id == event.id),
      // The list itself is still valid, so keep it and report the failure
      // over the top of it.
      onFailure: (exception) =>
          emit(ErrorState<List<Lead>>(exception, previousData: items)),
    );
  }
}
