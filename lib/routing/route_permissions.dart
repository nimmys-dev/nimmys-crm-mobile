import 'package:nimmys_crm/core/auth/app_permission.dart';
import 'package:nimmys_crm/routing/app_route_name.dart';

/// Which permission each route demands.
///
/// The whole point of keeping this as data rather than `if` statements in the
/// router: a new guarded screen is one line here, and the list of what is
/// protected can be read in one place instead of inferred from a redirect.
///
/// Routes absent from [_required] are open to any signed-in user — splash,
/// sign-in, the dashboard and the access-denied screen itself. Leaving them out
/// is deliberate, not an oversight: the dashboard adapts to the role rather
/// than being withheld from it.
class RoutePermissions {
  RoutePermissions._();

  static const Map<String, AppPermission> _required = <String, AppPermission>{
    AppRouteName.staffList: AppPermission.viewStaff,
    AppRouteName.staffCreate: AppPermission.createStaff,
    AppRouteName.taskCreate: AppPermission.createTask,
    // Adding a recurring duty is creating work for someone else, which is the
    // same right as creating a task.
    AppRouteName.dutyAdd: AppPermission.createTask,
    AppRouteName.leadNew: AppPermission.createLead,
    // "Own" is the floor, and admin/manager hold it too — the narrowing to
    // *whose* leads these are is the backend's call, not the router's.
    AppRouteName.leadDetails: AppPermission.viewOwnLeads,
    AppRouteName.followUpToday: AppPermission.viewOwnFollowUps,
    // Both are reached from dashboard components that are already role-gated —
    // the "Approval Pending" counter and the Report card. Guarding the routes
    // too keeps the tile and its destination from ever disagreeing.
    AppRouteName.approvals: AppPermission.viewApprovals,
    AppRouteName.reports: AppPermission.viewDashboardFull,
  };

  /// The permission [location] needs, or null when the route is open.
  static AppPermission? requiredFor(String location) => _required[location];

  /// Every guarded route, for tests and for anything that wants to reason about
  /// the protected surface as a whole.
  static Map<String, AppPermission> get all =>
      Map<String, AppPermission>.unmodifiable(_required);
}
