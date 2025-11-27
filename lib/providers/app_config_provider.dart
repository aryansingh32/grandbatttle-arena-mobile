import 'package:flutter/material.dart';
import 'package:grand_battle_arena/services/api_service.dart';

class AppConfigProvider with ChangeNotifier {
  String? _logoUrl;
  bool _isLoading = true;

  String? get logoUrl => _logoUrl;
  bool get isLoading => _isLoading;

  Future<void> fetchConfig() async {
    try {
      final config = await ApiService.getAppConfig();
      if (config.containsKey('logoUrl')) {
        _logoUrl = config['logoUrl'];
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching app config: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
}
