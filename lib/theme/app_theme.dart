import 'package:flutter/material.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Appcolor.primary,
      scaffoldBackgroundColor: Appcolor.primary,
      cardColor: Appcolor.cardsColor,
      canvasColor: Appcolor.primary,
      fontFamily: 'Rubik',
      dividerColor: Appcolor.grey.withOpacity(0.2),
      hintColor: Appcolor.grey,
      disabledColor: Appcolor.grey.withOpacity(0.5),
      appBarTheme: const AppBarTheme(
        backgroundColor: Appcolor.primary,
        iconTheme: IconThemeData(color: Appcolor.white),
        elevation: 0,
        titleTextStyle: TextStyle(color: Appcolor.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      colorScheme: const ColorScheme.dark(
        primary: Appcolor.secondary,
        onPrimary: Colors.black,
        secondary: Appcolor.secondary,
        onSecondary: Colors.black,
        surface: Appcolor.cardsColor,
        onSurface: Appcolor.white,
        background: Appcolor.primary,
        onBackground: Appcolor.white,
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Appcolor.white),
        bodyMedium: TextStyle(color: Appcolor.white),
        bodySmall: TextStyle(color: Appcolor.grey),
      ),
      iconTheme: const IconThemeData(color: Appcolor.white),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.white,
      scaffoldBackgroundColor: const Color(0xFFF5F5F7),
      cardColor: Colors.white,
      canvasColor: const Color(0xFFF5F5F7),
      fontFamily: 'Rubik',
      dividerColor: Colors.grey.withOpacity(0.2),
      hintColor: Colors.grey,
      disabledColor: Colors.grey.withOpacity(0.5),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black87),
        elevation: 0,
        titleTextStyle: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF6200EE), // Modern Purple
        onPrimary: Colors.white,
        secondary: Color(0xFF03DAC6), // Teal
        onSecondary: Colors.black,
        surface: Colors.white,
        onSurface: Colors.black87,
        background: Color(0xFFF5F5F7),
        onBackground: Colors.black87,
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.black87),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black87),
        bodySmall: TextStyle(color: Colors.grey),
      ),
    );
  }

  static ThemeData get futuristicTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF0D0221),
      scaffoldBackgroundColor: const Color(0xFF0D0221),
      cardColor: const Color(0xFF1A1A2E),
      canvasColor: const Color(0xFF0D0221),
      fontFamily: 'Orbitron', // Assuming Orbitron is available or fallback
      dividerColor: const Color(0xFF00FFCC).withOpacity(0.3),
      hintColor: const Color(0xFF00FFCC).withOpacity(0.5),
      disabledColor: const Color(0xFF00FFCC).withOpacity(0.2),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0D0221),
        iconTheme: IconThemeData(color: Color(0xFF00FFCC)), // Neon Cyan
        elevation: 0,
        titleTextStyle: TextStyle(color: Color(0xFF00FFCC), fontSize: 20, fontWeight: FontWeight.bold),
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00FFCC), // Neon Cyan
        onPrimary: Colors.black,
        secondary: Color(0xFFFF0099), // Neon Pink
        onSecondary: Colors.white,
        surface: Color(0xFF1A1A2E),
        onSurface: Color(0xFF00FFCC),
        background: Color(0xFF0D0221),
        onBackground: Color(0xFF00FFCC),
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Color(0xFF00FFCC)),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF00FFCC)),
        bodyMedium: TextStyle(color: Color(0xFF00FFCC)),
        bodySmall: TextStyle(color: Color(0xFF00FFCC)),
      ),
    );
  }

  static ThemeData getDynamicTheme(Color backgroundColor) {
    // Calculate contrasting colors based on background
    final isDark = ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final cardColor = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05);

    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: backgroundColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      canvasColor: backgroundColor,
      fontFamily: 'Rubik',
      dividerColor: secondaryTextColor.withOpacity(0.2),
      hintColor: secondaryTextColor,
      disabledColor: secondaryTextColor.withOpacity(0.5),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        iconTheme: IconThemeData(color: primaryTextColor),
        elevation: 0,
        titleTextStyle: TextStyle(color: primaryTextColor, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: Appcolor.secondary,
              onPrimary: Colors.black,
              secondary: Appcolor.secondary,
              onSecondary: Colors.black,
              surface: cardColor,
              onSurface: primaryTextColor,
              background: backgroundColor,
              onBackground: primaryTextColor,
            )
          : ColorScheme.light(
              primary: Appcolor.secondary,
              onPrimary: Colors.black,
              secondary: Appcolor.secondary,
              onSecondary: Colors.black,
              surface: cardColor,
              onSurface: primaryTextColor,
              background: backgroundColor,
              onBackground: primaryTextColor,
            ),
      iconTheme: IconThemeData(color: primaryTextColor),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: primaryTextColor),
        bodyMedium: TextStyle(color: primaryTextColor),
        bodySmall: TextStyle(color: secondaryTextColor),
      ),
    );
  }
}
