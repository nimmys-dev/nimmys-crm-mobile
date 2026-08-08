part of 'session_cubit.dart';

class SessionState extends Equatable {
  final UserRole role;

  /// False until the stored role has been read once. Lets the router tell
  /// "no permissions yet" apart from "genuinely not allowed".
  final bool isLoaded;

  const SessionState({
    this.role = UserRole.unknown,
    this.isLoaded = false,
  });

  SessionState copyWith({
    UserRole? role,
    bool? isLoaded,
  }) {
    return SessionState(
      role: role ?? this.role,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  @override
  List<Object?> get props => [role, isLoaded];
}
