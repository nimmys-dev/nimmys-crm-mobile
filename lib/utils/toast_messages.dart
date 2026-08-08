import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:nimmys_crm/utils/app_colors.dart';
import 'package:nimmys_crm/utils/app_global_variables.dart';
import 'package:nimmys_crm/utils/app_text_style.dart';
import 'package:nimmys_crm/utils/extensions/widget_extensions.dart';


class ToastMessages{
  ToastMessages._();

  static const Duration _duration =  Duration(milliseconds: 3000);
  static const List<BoxShadow> _boxShadows = [
    BoxShadow(
      color: Colors.black26,
      blurRadius:  10.0, // soften the shadow
      spreadRadius:  3.0, //extend the shadow
    )
  ];


  // Show
  //
  // Every toast goes out one frame from now, and this is load-bearing.
  //
  // A Flushbar is a route — `show()` does `Navigator.push(flushbarRoute)`.
  // Shown synchronously beside a `pop()` or a `go()`, the toast is the top of
  // the stack by the time the navigation runs, so the pop removes the *toast*
  // and leaves the screen it was aimed at in place. The toast's own dismissal
  // timer then fires against a stack that has moved underneath it, which
  // surfaces as `'scope != null'` in `ModalRoute.willPop` and a red screen.
  //
  // Deferring the push past the current frame puts it after whatever
  // navigation the caller did in the same turn. That makes "toast, then leave
  // the screen" safe to write in the obvious order at every call site — which
  // is what login, logout, session expiry and staff creation all do.
  static void _show(Flushbar<dynamic> flushbar) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Null between teardown and the next frame — a toast fired as the app
      // shuts down has nowhere to go, and is not worth crashing over.
      final NavigatorState? navigator = navigatorKey.currentState;
      if (navigator == null || !navigator.mounted) {
        return;
      }
      flushbar.show(navigator.context);
    });
  }


  // Error Msg
  static void internetError({required String message}) {
    _show(Flushbar(
      messageText: Text(message, style: AppTextStyle.body),
      messageColor: Colors.white,
      flushbarPosition: FlushbarPosition.TOP ,
      backgroundColor: AppColors.scaffoldBackgroundColor,
      isDismissible: false,
      boxShadows: _boxShadows,
      duration: _duration,
      icon: const Icon(Icons.wifi_off_rounded, size : 25,  color: AppColors.secondaryColor).paddingAll(10).paddingLeft(10),
    ));
  }

  // success Msg
  static void success({required String message}) {
    _show(Flushbar(
      messageText: Text(message, style: AppTextStyle.body),
      flushbarPosition: FlushbarPosition.TOP ,
      backgroundColor:   AppColors.scaffoldBackgroundColor,
      isDismissible: false,
      boxShadows: _boxShadows,
      duration: _duration,
      icon: const Icon(Icons.check_circle_rounded, size : 25, color: Colors.green).paddingAll(10).paddingLeft(5),
    ));
  }

  // Error Msg
  static void error({required String message}) {
    _show(Flushbar(
      messageText: Text(message, style: AppTextStyle.body),
      flushbarPosition: FlushbarPosition.TOP ,
      backgroundColor:  AppColors.scaffoldBackgroundColor,
      isDismissible: false,
      boxShadows: _boxShadows,
      duration: _duration,
      icon: const Icon(Icons.error, size : 25, color:  Colors.red).paddingAll(10).paddingLeft(5),
    ));
  }

  // Error Msg
  static void alert({required String message}) {
    _show(Flushbar(
      messageText: Text(message, style: AppTextStyle.body),
      flushbarPosition: FlushbarPosition.TOP ,
      backgroundColor:  AppColors.scaffoldBackgroundColor,
      isDismissible: false,
      boxShadows: _boxShadows,
      duration: _duration,
      icon: const Icon(Icons.error, size : 25, color:  Colors.orange).paddingAll(10).paddingLeft(5),
    ));
  }

  // Custom toast
  static void custom({required String message}) {
    _show(Flushbar(
      messageText: Text(message, style: AppTextStyle.body),
      flushbarPosition: FlushbarPosition.TOP ,
      backgroundColor:  AppColors.scaffoldBackgroundColor,
      isDismissible: false,
      boxShadows: _boxShadows,
      duration: _duration,
      icon: const Icon(Icons.warning_rounded, size : 25, color:  AppColors.secondaryColor).paddingAll(10).paddingLeft(5),
    ));
  }


}
