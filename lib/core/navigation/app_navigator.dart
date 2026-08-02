import 'package:flutter/material.dart';

/// The navigator key installed on the app's [MaterialApp].
///
/// Anything that has to navigate from outside the widget tree goes through
/// this: a notification tap arriving from the platform has no `BuildContext`
/// of its own, and the one it would otherwise borrow may not exist yet on a
/// cold start.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// The app's standard push transition.
Route<T> commonRoute<T>(Widget page) =>
    MaterialPageRoute<T>(builder: (BuildContext context) => page);
