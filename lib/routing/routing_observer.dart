import 'package:flutter/widgets.dart';

/// App-wide observer. Register on GoRouter:
///   GoRouter(observers: [routeObserver], ...)
final RouteObserver<PageRoute<dynamic>> routeObserver =
    RouteObserver<PageRoute<dynamic>>();