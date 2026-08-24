import 'package:flutter/material.dart';
import 'package:nimmys_crm/utils/app_colors.dart';

class AppThemeStyle {
  AppThemeStyle._();

  // Overall App Theme
  static ThemeData appTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.scaffoldBackgroundColor,
        primary: AppColors.primaryColor,
        secondary: AppColors.secondaryColor,
        surfaceTint: Colors.transparent,
        brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.scaffoldBackgroundColor,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    useMaterial3: true,
    appBarTheme:  const AppBarTheme(
        shadowColor: AppColors.shadowColor,
        backgroundColor: AppColors.appBarBackgroundColor,
        surfaceTintColor: Colors.white,
    ),
  );


  // Time Picker Theme
  static TimePickerThemeData timePickerTheme = TimePickerThemeData(
    hourMinuteColor: AppColors.secondaryColor, // Hour & Minute background
    hourMinuteTextColor: Colors.white, // Hour & Minute text color
    dialHandColor: AppColors.secondaryColor, // Dial hand color
    dialBackgroundColor: Colors.white, // Dial background color
    dayPeriodColor: WidgetStateColor.resolveWith((states) =>
    states.contains(WidgetState.selected)
        ? AppColors.secondaryColor // Selected AM/PM Background
        : Colors.white), // Unselected AM/PM Background
    dayPeriodTextColor: WidgetStateColor.resolveWith((states) =>
    states.contains(WidgetState.selected)
        ? Colors.white // Selected AM/PM Text Color
        : Colors.black), // Unselected AM/PM Text Color
  );


}