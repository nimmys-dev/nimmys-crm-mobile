import 'package:equatable/equatable.dart';
import 'package:nimmys_crm/core/auth/user_role.dart';
import 'package:nimmys_crm/core/reset_cubit_state.dart';
import 'package:nimmys_crm/features/authentication/repository/user_information_repository.dart';
import 'package:nimmys_crm/utils/custom_log.dart';
part 'session_state.dart';

/// Holds the signed-in user's role for the length of the session.
///
/// The role itself is not stored here — it lives in secure storage, written by
/// `AuthRepository.saveUserInfoFromLogin` straight from `loginResponse.user.role`.
/// This cubit is the in-memory copy every permission check reads, so widgets and
/// the router guard can ask synchronously instead of awaiting the keychain on
/// every rebuild.
class SessionCubit extends BaseCubit<SessionState> {
  final UserInformationRepository _repository;
  SessionCubit(this._repository) : super(const SessionState());

  /// Reads the stored role into memory. Called at splash before the first
  /// route decision, and again after login once the new session is written.
  Future<void> loadSession() async {
    final String? storedRole = await _repository.getUserRole();
    final UserRole role = UserRole.fromApi(storedRole);
    CustomLog.info(this, "Session role loaded : ${role.name} (stored : $storedRole)");
    emit(SessionState(role: role, isLoaded: true));
  }

  /// Called on sign-out. Drops back to [UserRole.unknown], which carries no
  /// permissions — so a signed-out app fails closed if anything still asks.
  void clearSession() {
    emit(const SessionState());
  }
}
