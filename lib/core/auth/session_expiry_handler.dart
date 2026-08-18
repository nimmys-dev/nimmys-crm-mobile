import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/data/network/api_urls.dart';
import 'package:nimmys_crm/dependency_injection/locator.dart';
import 'package:nimmys_crm/features/authentication/cubit/login/login_cubit.dart';
import 'package:nimmys_crm/features/authentication/cubit/session/session_cubit.dart';
import 'package:nimmys_crm/features/authentication/repository/auth_repository.dart';
import 'package:nimmys_crm/features/leads/cubit/leads/leads_cubit.dart';
import 'package:nimmys_crm/features/profile/cubit/profile/profile_cubit.dart';
import 'package:nimmys_crm/features/staff/cubit/staff/staff_cubit.dart';
import 'package:nimmys_crm/routing/app_route_name.dart';
import 'package:nimmys_crm/utils/app_global_variables.dart';
import 'package:nimmys_crm/utils/app_string.dart';
import 'package:nimmys_crm/utils/custom_log.dart';
import 'package:nimmys_crm/utils/toast_messages.dart';

/// Ends the local session the moment the API stops accepting the token.
///
/// Wired into `ApiService._handleHttpError`, so it covers every call in the app
/// — there is no per-screen handling to remember and nothing to add when a new
/// feature lands.
///
/// WHICH failures end a session is deliberately narrow, see [endsSession]:
/// signing a user out on *any* non-2xx would mean a duplicate-email 422 on
/// Staff Creation, a 404, or a transient 500 all throwing them back to the
/// login screen mid-task with their form data gone. Those are request failures,
/// not session failures. The list below is the single place to widen it.
class SessionExpiryHandler {
  SessionExpiryHandler._();

  /// Guards against the stampede: a screen firing three calls at once gets
  /// three 401s, and without this each one would sign out, toast and navigate.
  static bool _isEndingSession = false;

  /// The failures that mean "this token is no longer good".
  ///
  /// 403 is excluded on purpose — it means the role is not allowed to do this
  /// one thing, and signing the user out would be wrong: their session is fine.
  static bool endsSession(ErrorType error) =>
      error is UnauthenticatedError ||
      error is InvalidTokenError ||
      error is TokenExpiredError;

  /// Endpoints where an auth failure is a normal answer rather than an expiry.
  ///
  /// Login 401s on a wrong password, and logout 401s when revoking a token the
  /// server has already dropped — [AuthService.logout] treats that as success.
  /// Reacting to either would fight the flow the user is already in.
  static final Set<String> _exemptPaths = <String>{
    Uri.parse(ApiUrls.login).path,
    Uri.parse(ApiUrls.logout).path,
  };

  /// Called by [ApiService] for every failed request. Does nothing unless the
  /// failure actually ends the session, so callers need no conditions of their
  /// own.
  static void notify(ErrorType error, {String? requestPath}) {
    if (!endsSession(error)) {
      return;
    }
    if (requestPath != null && _exemptPaths.contains(requestPath)) {
      CustomLog.info(
        SessionExpiryHandler,
        "Auth failure on $requestPath is expected there — not ending the session",
      );
      return;
    }
    // Deliberately not awaited: this is fired from inside error handling that
    // still has a Result to return to its caller.
    unawaited(_endSession());
  }

  static Future<void> _endSession() async {
    if (_isEndingSession) {
      return;
    }
    _isEndingSession = true;
    try {
      final AuthRepository authRepository = locator<AuthRepository>();

      // No stored token means there was no session to end — an unauthenticated
      // call made before sign-in, which is not an expiry.
      if (!await authRepository.isLoggedIn()) {
        return;
      }

      CustomLog.info(
        SessionExpiryHandler,
        "Token rejected by the API — ending the local session",
      );

      // Local clear only. `logout()` would call the API with the very token the
      // server has just refused, which fails and achieves nothing.
      await authRepository.signOut();

      // Same set the manual sign-out clears, so an expiry and a deliberate
      // logout leave the app in exactly the same state.
      locator<SessionCubit>().clearSession();
      locator<ProfileCubit>().resetProfileState();
      locator<StaffCubit>().resetStaffState();
      locator<LeadsCubit>().resetLeadsState();
      locator<LoginCubit>().resetLoginState();

      _announceAndRedirect();
    } catch (e) {
      CustomLog.error(SessionExpiryHandler, "Failed to end the session", e);
    } finally {
      _isEndingSession = false;
    }
  }

  /// Tells the user why they are back at the login screen, then takes them
  /// there. Both steps are skipped if the app has no navigator yet — that only
  /// happens before the first frame, where there is no session to end anyway.
  static void _announceAndRedirect() {
    final BuildContext? context = navigatorKey.currentContext;
    if (navigatorKey.currentState == null || context == null) {
      return;
    }

    ToastMessages.alert(message: AppString.errorType.sessionEnded);
    // `go`, not `push`: the expired screens behind this must not be reachable
    // with a back gesture.
    GoRouter.of(context).go(AppRouteName.signIn);
  }
}
