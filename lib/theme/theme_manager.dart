import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

enum AppThemeType {
  dark,
  light,
  futuristic,
  dynamic,
}

class ThemeManager extends ChangeNotifier {
  AppThemeType _currentTheme = AppThemeType.dark;
  // Timer? _dynamicThemeTimer; // Removed for performance
  Color _dynamicColor = const Color.fromRGBO(9, 11, 14, 1);
  int _colorIndex = 0;
  bool _showFilterGrid = true;

  // Dynamic theme colors (Deep Space to Nebula)
  final List<Color> _dynamicColors = [
    const Color.fromRGBO(9, 11, 14, 1), // Deep Dark
    const Color.fromRGBO(20, 0, 40, 1), // Deep Purple
    const Color.fromRGBO(0, 20, 40, 1), // Deep Blue
    const Color.fromRGBO(0, 30, 20, 1), // Deep Teal
  ];

  ThemeManager() {
    _loadTheme();
  }

  AppThemeType get currentTheme => _currentTheme;
  Color get dynamicBackgroundColor => _dynamicColor;
  bool get showFilterGrid => _showFilterGrid;

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_type') ?? 0;
    _currentTheme = AppThemeType.values[themeIndex];
    _showFilterGrid = prefs.getBool('show_filter_grid') ?? true;
    
    // if (_currentTheme == AppThemeType.dynamic) {
    //   _startDynamicTheme();
    // }
    notifyListeners();
  }

  Future<void> setTheme(AppThemeType theme) async {
    if (_currentTheme == theme) return;
    
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_type', theme.index);

    // if (theme == AppThemeType.dynamic) {
    //   _startDynamicTheme();
    // } else {
    //   _stopDynamicTheme();
    // }
    
    notifyListeners();
  }

  Future<void> toggleFilterGrid(bool value) async {
    _showFilterGrid = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_filter_grid', value);
    notifyListeners();
  }

  // void _startDynamicTheme() {
  //   _stopDynamicTheme();
  //   _dynamicThemeTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
  //     _colorIndex = (_colorIndex + 1) % _dynamicColors.length;
  //     _dynamicColor = _dynamicColors[_colorIndex];
  //     notifyListeners();
  //   });
  // }

  // void _stopDynamicTheme() {
  //   _dynamicThemeTimer?.cancel();
  //   _dynamicThemeTimer = null;
  // }

  @override
  void dispose() {
    // _stopDynamicTheme();
    super.dispose();
  }
}
