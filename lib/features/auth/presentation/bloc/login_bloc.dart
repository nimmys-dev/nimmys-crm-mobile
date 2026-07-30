import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/view_model_bloc.dart';
import '../../../../core/presentation/view_state.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

sealed class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

final class LoginSubmitted extends LoginEvent {
  const LoginSubmitted({required this.email, required this.password});

  final String email;
  final String password;

  /// Password deliberately excluded from [props]: Equatable's `toString`
  /// prints them, and bloc observers log events.
  @override
  List<Object?> get props => <Object?>[email];
}

/// Sign-in ViewModel.
///
/// Ends on [SuccessState], which the login screen listens for to navigate.
/// A wrong password comes back as an [ErrorState] carrying a
/// `UnauthorizedException`, so the screen shows `state.errorOrNull!.userMessage`
/// and never has to know what a 401 is.
class LoginBloc extends ViewModelBloc<LoginEvent, AuthUser> {
  LoginBloc(this._repository) {
    on<LoginSubmitted>(_onSubmitted);
  }

  final AuthRepository _repository;

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<ViewState<AuthUser>> emit,
  ) => submit(
    emit,
    () => _repository.login(email: event.email, password: event.password),
  );
}
