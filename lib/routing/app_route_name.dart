class AppRouteName{
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
  static const String taskCreate = "/task/create";
  static const String dutyAdd = "/duty/add";
  static const String leadNew = "/lead/new";
  static const String leadDetails = "/lead/details";
  static const String followUpToday = "/followUp/today";

  /// Where the router sends anyone who asks for a route their role does not
  /// carry the permission for.
  static const String accessDenied = "/accessDenied";

}
