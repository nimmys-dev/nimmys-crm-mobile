import 'package:nimmys_crm/core/auth/user_role.dart';

/// Every distinct thing a signed-in user may be allowed to do.
///
/// Capabilities, not screens: a permission survives a screen being renamed or
/// split, and one screen can need several. "Own" and "any" are separate
/// permissions wherever the difference matters — an employee editing their own
/// lead and a manager editing anyone's are not the same right.
enum AppPermission {
  /// The org-wide dashboard. Without it the dashboard still renders, limited to
  /// the user's own counters.
  viewDashboardFull,

  viewAllTasks,
  viewOwnTasks,
  createTask,
  editAnyTask,
  editOwnTask,
  deleteTask,
  approveTask,
  viewApprovals,

  viewAllLeads,
  viewOwnLeads,
  createLead,
  editAnyLead,
  editOwnLead,
  deleteLead,

  viewAllFollowUps,
  viewOwnFollowUps,

  viewStaff,
  createStaff,
  editStaff,
  deleteStaff,
}

/// The single source of truth for who can do what.
///
/// Adding a role means adding one entry to [_matrix]; adding a capability means
/// adding one enum value and listing it for the roles that hold it. Nothing
/// outside this file compares a role to a string.
class AppPermissions {
  AppPermissions._();

  /// Admin and manager are deliberately identical: the brief treats a manager
  /// as having full access unless the backend defines something narrower, and
  /// it does not. Split this constant the day it does.
  static const Set<AppPermission> _fullAccess = <AppPermission>{
    AppPermission.viewDashboardFull,
    AppPermission.viewAllTasks,
    AppPermission.viewOwnTasks,
    AppPermission.createTask,
    AppPermission.editAnyTask,
    AppPermission.editOwnTask,
    AppPermission.deleteTask,
    AppPermission.approveTask,
    AppPermission.viewApprovals,
    AppPermission.viewAllLeads,
    AppPermission.viewOwnLeads,
    AppPermission.createLead,
    AppPermission.editAnyLead,
    AppPermission.editOwnLead,
    AppPermission.deleteLead,
    AppPermission.viewAllFollowUps,
    AppPermission.viewOwnFollowUps,
    AppPermission.viewStaff,
    AppPermission.createStaff,
    AppPermission.editStaff,
    AppPermission.deleteStaff,
  };

  /// Own work only: no staff module, no approvals, no deletes, no creating
  /// tasks for other people.
  ///
  /// [AppPermission.createLead] is the one open cell in the brief's matrix
  /// ("if existing permission allows"). Nothing in this project restricts it,
  /// and lead capture is the job an employee does, so it is granted — the
  /// dashboard's "Add Lead" action stays usable. Remove it here if the backend
  /// says otherwise; no other file changes.
  static const Set<AppPermission> _employeeAccess = <AppPermission>{
    AppPermission.viewOwnTasks,
    AppPermission.editOwnTask,
    AppPermission.viewOwnLeads,
    AppPermission.createLead,
    AppPermission.editOwnLead,
    AppPermission.viewOwnFollowUps,
  };

  static const Map<UserRole, Set<AppPermission>> _matrix =
      <UserRole, Set<AppPermission>>{
        UserRole.admin: _fullAccess,
        UserRole.manager: _fullAccess,
        UserRole.employee: _employeeAccess,
        UserRole.unknown: <AppPermission>{},
      };

  static Set<AppPermission> of(UserRole role) =>
      _matrix[role] ?? const <AppPermission>{};

  static bool has(UserRole role, AppPermission permission) =>
      of(role).contains(permission);
}

/// Reads at the call site — `role.canCreateStaff` rather than a string compare.
///
/// These are named for the question a widget actually asks. Anything not
/// covered here can still use [can] directly.
extension UserRoleAccess on UserRole {
  bool can(AppPermission permission) => AppPermissions.has(this, permission);

  bool canAny(Iterable<AppPermission> permissions) => permissions.any(can);

  /// True for admin and manager — the two roles with an org-wide view.
  bool get hasFullDashboard => can(AppPermission.viewDashboardFull);

  bool get canViewTasks => canAny(<AppPermission>[
    AppPermission.viewAllTasks,
    AppPermission.viewOwnTasks,
  ]);
  bool get canCreateTask => can(AppPermission.createTask);
  bool get canDeleteTask => can(AppPermission.deleteTask);
  bool get canApproveTask => can(AppPermission.approveTask);
  bool get canAccessApprovals => can(AppPermission.viewApprovals);

  bool get canViewLeads => canAny(<AppPermission>[
    AppPermission.viewAllLeads,
    AppPermission.viewOwnLeads,
  ]);
  bool get canCreateLead => can(AppPermission.createLead);
  bool get canDeleteLead => can(AppPermission.deleteLead);

  bool get canViewFollowUps => canAny(<AppPermission>[
    AppPermission.viewAllFollowUps,
    AppPermission.viewOwnFollowUps,
  ]);

  bool get canAccessStaff => can(AppPermission.viewStaff);
  bool get canCreateStaff => can(AppPermission.createStaff);
  bool get canEditStaff => can(AppPermission.editStaff);
  bool get canDeleteStaff => can(AppPermission.deleteStaff);
}
