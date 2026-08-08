class AppRouteName {
  AppRouteName._();

  static const String intro = "/intro";
  static const String signIn = "/signIn";
  static const String splash = "/splash";
  static const String home = "/home";
  static const String notFound = "/notFound";
  static const String genericSuccess = "/genericSuccess";

  // Feature screens.
  //
  // These exist as named routes so `RoutePermissions` has something to guard:
  // a screen reached only by `Navigator.push` cannot be permission-checked
  // centrally, because there is no name to check. Every caller navigates by
  // name, so the guard runs whichever way the screen is reached.
  static const String staffList = "/staff";
  static const String staffCreate = "/staff/create";
  static const String staffDetails = "/staff/details";
  static const String staffEdit = "/staff/edit";
  static const String taskCreate = "/task/create";
  static const String dutyAdd = "/duty/add";
  static const String duties = "/duties";
  static const String leadNew = "/lead/new";
  static const String leads = "/leads";
  static const String approvals = "/approvals";
  static const String reports = "/reports";
  static const String leadDetails = "/lead/details";
  static const String followUpToday = "/followUp/today";

  /// Where the router sends anyone who asks for a route their role does not
  /// carry the permission for.
  static const String accessDenied = "/accessDenied";

  /// [duties] opened on one of its tabs — `/duties?filter=overdue`.
  ///
  /// Built here rather than at the call sites so the query key lives next to
  /// the path it belongs to. [filter] is a `DutyFilter.wireValue`; an
  /// unrecognised one simply opens the default tab.
  static String dutiesFiltered(String filter) => "$duties?filter=$filter";

  /// [staffDetails] / [staffEdit] for a specific staff member — e.g.
  /// `/staff/details?id=15`. Both routes need the id to know which record to
  /// fetch, and query params keep that consistent with [dutiesFiltered] rather
  /// than introducing GoRouter path parameters for the first time in this app.
  static String staffDetailsFor(int id) => "$staffDetails?id=$id";
  static String staffEditFor(int id) => "$staffEdit?id=$id";
}
