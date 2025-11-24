import 'package:flutter/foundation.dart';

/// CHANGE: simple notifier so widgets can refresh bookings immediately after a registration succeeds.
class BookingRefreshNotifier extends ChangeNotifier {
  int _tick = 0;
  int get tick => _tick;

  void ping() {
    _tick++;
    notifyListeners();
  }
}

