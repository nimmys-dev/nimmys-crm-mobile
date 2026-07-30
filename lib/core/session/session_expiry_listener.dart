import 'dart:async';

import 'package:flutter/material.dart';

import 'session_manager.dart';

/// Reacts once, app-wide, when a session ends.
///
/// A forced logout can be discovered by whichever request happens to be in
/// flight — a dashboard tile, a background refresh, a list the user is not
/// even looking at. Handling it at each call site means every repository has
/// to know about navigation, and a screen with four parallel requests shows
/// four "signed out" messages.
///
/// Listening in one place above the navigator solves both: the reaction is
/// written once, and [SessionManager.signOut] is idempotent so only the first
/// of those four failures gets here.
class SessionExpiryListener extends StatefulWidget {
  const SessionExpiryListener({
    super.key,
    required this.sessionManager,
    required this.child,
    this.onSessionEnded,
  });

  final SessionManager sessionManager;

  final Widget child;

  /// Where to send the user. Wire this to the login route once a router
  /// exists; until then the message alone is the visible behaviour.
  final void Function(BuildContext context, SessionEndReason reason)?
  onSessionEnded;

  @override
  State<SessionExpiryListener> createState() => _SessionExpiryListenerState();
}

class _SessionExpiryListenerState extends State<SessionExpiryListener> {
  StreamSubscription<SessionEndReason>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.sessionManager.onEnded.listen(_handle);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _handle(SessionEndReason reason) {
    if (!mounted) {
      return;
    }

    // A deliberate sign-out needs no explanation; only tell the user when
    // something happened *to* them.
    if (reason != SessionEndReason.userInitiated) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(switch (reason) {
            SessionEndReason.expired =>
              'Your session has expired. Please sign in again.',
            SessionEndReason.revoked =>
              'You were signed out. Please sign in again.',
            SessionEndReason.userInitiated => 'Signed out.',
          }),
        ),
      );
    }

    widget.onSessionEnded?.call(context, reason);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
