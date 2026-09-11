import 'package:flutter/material.dart';
import 'package:nimmys_crm/core/auth/app_permission.dart';
import 'package:nimmys_crm/core/auth/user_role.dart';
import 'package:nimmys_crm/dependency_injection/locator.dart';
import 'package:nimmys_crm/features/approvals/approvals_screen.dart';
import 'package:nimmys_crm/features/authentication/access_denied_screen.dart';
import 'package:nimmys_crm/features/authentication/change_password_screen.dart';
import 'package:nimmys_crm/features/authentication/cubit/session/session_cubit.dart';
import 'package:nimmys_crm/features/authentication/login_screen.dart';
import 'package:nimmys_crm/features/dashboard/dashboard_screen.dart';
import 'package:nimmys_crm/features/duties/create_task_screen.dart';
import 'package:nimmys_crm/features/duties/duty_list_global_screen.dart';
import 'package:nimmys_crm/features/duties/duty_list_screen.dart';
import 'package:nimmys_crm/features/duties/task_detail_screen.dart';
import 'package:nimmys_crm/features/leads/closed_leads_screen.dart';
import 'package:nimmys_crm/features/leads/lead_details_screen.dart';
import 'package:nimmys_crm/features/leads/lead_list_global_screen.dart';
import 'package:nimmys_crm/features/leads/my_lead_list_screen.dart';
import 'package:nimmys_crm/features/leads/my_leads_screen.dart';
import 'package:nimmys_crm/features/leads/new_lead_screen.dart';
import 'package:nimmys_crm/features/leads/todays_follow_up_screen.dart';
import 'package:nimmys_crm/features/preview/screen_catalog_screen.dart';
import 'package:nimmys_crm/features/profile/company_profile_screen.dart';
import 'package:nimmys_crm/features/reports/reports_screen.dart';
import 'package:nimmys_crm/features/splash/splash_screen.dart';
import 'package:nimmys_crm/features/staff/staff_creation_screen.dart';
import 'package:nimmys_crm/features/staff/staff_details_screen.dart';
import 'package:nimmys_crm/features/staff/staff_list_screen.dart';
import 'package:nimmys_crm/routing/app_route_name.dart';
import 'package:nimmys_crm/routing/route_permissions.dart';
import 'package:nimmys_crm/utils/app_global_variables.dart';
import 'package:nimmys_crm/utils/custom_log.dart';
import 'package:go_router/go_router.dart';

class AppRoutes {
  AppRoutes._();

  /// Single permission gate for the whole app.
  ///
  /// Runs on every navigation, so hiding a nav item and guarding a route are
  /// two independent defences rather than the same one: an employee who
  /// reaches `/staff/create` by any means — a deep link, a stale route, a
  /// hard-coded `context.go` — is turned away here, not by the absence of a
  /// button.
  ///
  /// The role comes from the [SessionCubit] singleton rather than a
  /// `BuildContext` lookup: redirects run outside the widget tree's normal
  /// lifecycle, and the locator holds the same instance MultiBlocWrapper
  /// provides. It is read fresh on every call, so a sign-in or sign-out during
  /// the session takes effect on the very next navigation.
  ///
  /// This is a UI guard only. The API enforces its own authorization, and a 401
  /// or 403 from the server is still handled on its own terms — see
  /// `ApiService._handleHttpError`.
  static String? _permissionGuard(BuildContext context, GoRouterState state) {
    final AppPermission? required = RoutePermissions.requiredFor(
      state.matchedLocation,
    );
    if (required == null) {
      return null;
    }

    final UserRole role = locator<SessionCubit>().state.role;
    if (role.can(required)) {
      return null;
    }

    CustomLog.info(
      AppRoutes,
      "Route blocked : ${state.matchedLocation} needs ${required.name}, role is ${role.name}",
    );
    return AppRouteName.accessDenied;
  }

  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: AppRouteName.splash,
    navigatorKey: navigatorKey,
    redirect: _permissionGuard,
    observers: <NavigatorObserver>[routeObserver],
    routes: <RouteBase>[
      // Splash
      // Decides between home and signIn once the session check completes.
      GoRoute(
        path: AppRouteName.splash,
        builder: (BuildContext context, GoRouterState state) {
          return const SplashScreen();
        },
      ),

      // Sign In
      GoRoute(
        path: AppRouteName.signIn,
        builder: (BuildContext context, GoRouterState state) {
          // `go` replaces the login entry: once the token is stored, backing
          // into the form would show a screen the user is already past.
          return LoginScreen(onSignedIn: () => context.go(AppRouteName.home));
        },
      ),

      // Home
      GoRoute(
        path: AppRouteName.home,
        builder: (BuildContext context, GoRouterState state) {
          return const DashboardScreen();
        },
      ),

      // Access Denied
      // Intentionally unguarded — guarding the screen that explains a failed
      // permission check would redirect it to itself.
      GoRoute(
        path: AppRouteName.accessDenied,
        builder: (BuildContext context, GoRouterState state) {
          return const AccessDeniedScreen();
        },
      ),
      GoRoute(
        path: AppRouteName.changePassword,
        builder: (BuildContext context, GoRouterState state) =>
            const ChangePasswordScreen(),
      ),

      // Staff
      //
      // `/staff/create` is declared before `/staff` would shadow it — GoRouter
      // matches on the full path, so the order is presentational, but keeping
      // the list first mirrors how the screens are reached.
      GoRoute(
        path: AppRouteName.staffList,
        builder: (BuildContext context, GoRouterState state) {
          return const StaffListScreen();
        },
      ),
      GoRoute(
        path: AppRouteName.staffCreate,
        builder: (BuildContext context, GoRouterState state) {
          return const StaffCreationScreen();
        },
      ),
      GoRoute(
        path: AppRouteName.staffDetails,
        builder: (BuildContext context, GoRouterState state) {
          final int? id = int.tryParse(state.uri.queryParameters['id'] ?? '');
          // No id means there is nothing to look up — fall back to the list
          // rather than build a details screen with nothing to show.
          return id == null
              ? const StaffListScreen()
              : StaffDetailsScreen(staffId: id);
        },
      ),
      GoRoute(
        path: AppRouteName.staffEdit,
        builder: (BuildContext context, GoRouterState state) {
          final int? id = int.tryParse(state.uri.queryParameters['id'] ?? '');
          return id == null
              ? const StaffListScreen()
              : StaffCreationScreen(staffId: id);
        },
      ),

      // Duties / Tasks
      //
      // One list screen for today / overdue / upcoming, opened on the tab named
      // by `?filter=` — see DutyFilter. Three routes onto three near-identical
      // screens would be three copies to keep in step.
      GoRoute(
        path: AppRouteName.duties,
        builder: (BuildContext context, GoRouterState state) {
          final String? taskStatus = state.uri.queryParameters['taskStatus'];
          final String? scope = state.uri.queryParameters['scope'];
          return DutyListScreen(taskStatus: taskStatus, scope: scope);
        },
      ),

      GoRoute(
        path: AppRouteName.taskCreate,
        builder: (BuildContext context, GoRouterState state) {
          return const CreateTaskScreen();
        },
      ),
      GoRoute(
        path: AppRouteName.dutyAdd,
        builder: (BuildContext context, GoRouterState state) {
          return const CreateTaskScreen();
        },
      ),

      // Leads
      GoRoute(
        path: AppRouteName.leads,
        builder: (context, state) {
          final bool? isAppHeaderRequired = bool.tryParse(
            state.uri.queryParameters['isAppHeaderRequired'] ?? '',
          );
          final String? status = state.uri.queryParameters['status'];
          final String? scope = state.uri.queryParameters['scope'];
          return MyLeadsScreen(
            isAppHeaderRequired: isAppHeaderRequired ?? true,
            status: status, // pass null if missing
            scope: scope,
          );
        },
      ),
      GoRoute(
        path: AppRouteName.leadNew,
        builder: (BuildContext context, GoRouterState state) {
          return const NewLeadScreen();
        },
      ),
      GoRoute(
        path: AppRouteName.leadDetails,
        builder: (BuildContext context, GoRouterState state) {
          final int? id = int.tryParse(state.uri.queryParameters['id'] ?? '');
          return LeadDetailsScreen(leadId: id);
        },
      ),
      GoRoute(
        path: AppRouteName.followUpToday,
        builder: (BuildContext context, GoRouterState state) {
          return const TodaysFollowUpScreen();
        },
      ),

      // Approvals
      GoRoute(
        path: AppRouteName.approvals,
        builder: (BuildContext context, GoRouterState state) {
          final String? scope = state.uri.queryParameters['scope'];
          return ApprovalsScreen(scope: scope.toString());
        },
      ),

      // Reports
      GoRoute(
        path: AppRouteName.reports,
        builder: (BuildContext context, GoRouterState state) {
          final bool? isAppHeaderRequired = bool.tryParse(
            state.uri.queryParameters['isAppHeaderRequired'] ?? '',
          );
          return ReportsScreen(
            isAppHeaderRequired: isAppHeaderRequired ?? false,
          );
        },
      ),

      // Default Screen
      // Still the design catalog — every screen in the app reachable in one tap.
      GoRoute(
        path: AppRouteName.notFound,
        builder: (BuildContext context, GoRouterState state) {
          return const ScreenCatalogScreen();
        },
      ),
      GoRoute(
        path: AppRouteName.companyDetails,
        builder: (BuildContext context, GoRouterState state) {
          return const CompanyProfileScreen();
        },
      ),
      GoRoute(
        path: AppRouteName.taskDetails,
        builder: (BuildContext context, GoRouterState state) {
          final String? idParam = state.uri.queryParameters['id'];
          final int? id = int.tryParse(idParam ?? '');

          if (id == null) {
            return const Scaffold(body: Center(child: Text('Invalid task ID')));
          }

          return TaskDetailsScreen(taskId: id);
        },
      ),
      GoRoute(
        path: AppRouteName.closedLeads,
        builder: (BuildContext context, GoRouterState state) {
          return ClosedLeadsScreen();
        },
      ),
      GoRoute(
        path: AppRouteName.viewAllLeads,
        builder: (BuildContext context, GoRouterState state) {
          return LeadListGlobalScreen();
        },
      ),
      GoRoute(
        path: AppRouteName.viewAllDuties,
        builder: (BuildContext context, GoRouterState state) {
          return DutyListGlobalScreen();
        },
      ),
      GoRoute(
        path: AppRouteName.viewMyLeads,
        builder: (BuildContext context, GoRouterState state) {
          return MyLeadListScreen();
        },
      ),
    ],
  );
}

/// App-wide observer. Register on GoRouter:
///   GoRouter(observers: [routeObserver], ...)
final RouteObserver<PageRoute<dynamic>> routeObserver =
    RouteObserver<PageRoute<dynamic>>();
