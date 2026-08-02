import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/view_model_bloc.dart';
import '../../../../core/presentation/view_state.dart';
import '../../domain/entities/lead.dart';
import '../../domain/repositories/lead_repository.dart';

// ------------------------------------------------------------------- Events

sealed class LeadFormEvent extends Equatable {
  const LeadFormEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Load an existing lead into the form. Omitted when creating.
final class LeadFormStarted extends LeadFormEvent {
  const LeadFormStarted(this.leadId);

  final String leadId;

  @override
  List<Object?> get props => <Object?>[leadId];
}

final class LeadFormSubmitted extends LeadFormEvent {
  const LeadFormSubmitted(this.draft);

  final LeadDraft draft;

  @override
  List<Object?> get props => <Object?>[draft];
}

// --------------------------------------------------------------------- Bloc

/// Create-or-edit ViewModel for a single lead.
///
/// Shows the other half of the state machine from `LeadListBloc`: a form ends
/// on [SuccessState] rather than [LoadedState], because the screen's reaction
/// to a successful save is to pop and show a snackbar, not to rebuild.
///
/// The pairing that makes this work in a widget:
///
/// ```dart
/// BlocConsumer<LeadFormBloc, ViewState<Lead>>(
///   listenWhen: (_, ViewState<Lead> s) => s is SuccessState<Lead>,
///   listener: (BuildContext context, ViewState<Lead> state) =>
///       Navigator.of(context).pop(state.dataOrNull),
///   builder: (BuildContext context, ViewState<Lead> state) => TextFormField(
///     // A 422 arrives already split by field, so this is the whole of
///     // server-side validation display.
///     decoration: InputDecoration(
///       errorText: state.fieldErrors['mobile']?.first,
///     ),
///   ),
/// )
/// ```
class LeadFormBloc extends ViewModelBloc<LeadFormEvent, Lead> {
  LeadFormBloc(this._repository, {String? leadId}) : _leadId = leadId, super() {
    on<LeadFormStarted>(_onStarted);
    on<LeadFormSubmitted>(_onSubmitted);
  }

  final LeadRepository _repository;

  /// Null when creating, set when editing — the only thing that decides
  /// whether submit POSTs or PUTs.
  final String? _leadId;

  bool get isEditing => _leadId != null;

  Future<void> _onStarted(
    LeadFormStarted event,
    Emitter<ViewState<Lead>> emit,
  ) => loadData(
    emit,
    () => _repository.getLead(event.leadId, cancelToken: cancelToken),
  );

  Future<void> _onSubmitted(
    LeadFormSubmitted event,
    Emitter<ViewState<Lead>> emit,
  ) {
    final String? id = _leadId;
    return submit(
      emit,
      () => id == null
          ? _repository.createLead(event.draft)
          : _repository.updateLead(id, event.draft),
      successMessage: id == null ? 'Lead created.' : 'Lead updated.',
    );
  }
}
