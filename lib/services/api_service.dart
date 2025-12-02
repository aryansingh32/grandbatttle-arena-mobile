import 'dart:convert';
import 'dart:io';
import 'package:grand_battle_arena/components/bannerslider.dart';
import 'package:grand_battle_arena/models/available_amount_model.dart';
import 'package:grand_battle_arena/models/payment_amount_model.dart';
import 'package:http/http.dart' as http;
import 'package:grand_battle_arena/services/firebase_auth_service.dart';
import 'package:grand_battle_arena/models/tournament_model.dart';
import 'package:grand_battle_arena/models/user_model.dart';
import 'package:grand_battle_arena/models/wallet_model.dart';
import 'package:grand_battle_arena/models/transaction_model.dart';
import 'package:grand_battle_arena/models/notification_model.dart';
import 'package:grand_battle_arena/models/deposit_request_model.dart';
import 'package:grand_battle_arena/models/slots_model.dart';
import 'package:grand_battle_arena/models/payment_qr_response.dart';
import 'package:grand_battle_arena/models/wallet_ledger_model.dart';
import 'package:grand_battle_arena/config/api_config.dart';

/// Enhanced API endpoints with notification and payment support
class _ApiEndpoints {
  static const String baseUrl = ApiConfig.baseUrl;
  static const String _api = '/api';

  // Public Endpoints
  static const String publicTournaments = '$_api/public/tournaments';

  // User Management
  static const String users = '$_api/users/me';

  // Tournaments
  static const String tournaments = '$_api/tournaments';
  static String getTournamentCredentials(int tournamentId) => '$tournaments/$tournamentId/credentials';

  // Wallet & Transactions
  static const String wallets = '$_api/wallets';
  static const String transactions = '$_api/transactions';
  static const String deposit = '$transactions/deposit';
  static const String withdraw = '$transactions/withdraw';
  static const String transactionHistory = '$transactions/history';

  // Slots & Bookings
  static const String slots = '$_api/slots';
  static const String bookSlot = '$slots/book';
  static const String myBookings = '$slots/my-bookings';

  // Notifications
  static const String notifications = '$_api/notifications/my';
  static const String notificationStats = '$_api/notifications/stats';

  // Payment QR Code Endpoints
  static const String payments = '$_api/v1/payments';
  static const String paymentQr = '$payments/qr';
  static const String availableAmounts = '$payments/amounts';
  static const String paymentHealth = '$payments/health';

  // Helper methods
  static String getSlotSummary(int tournamentId) => '$slots/$tournamentId/summary';
  static String getTournamentDetail(int tournamentId) => '$tournaments/$tournamentId';
  static String getTournamentByStatus(String status) => '$tournaments/status/$status';
  static String markNotificationRead(int notificationId) => '$_api/notifications/$notificationId/read';
  static String getPaymentQrByAmount(int amount) => '$paymentQr/$amount';
  static String bookNextSlot(int tournamentId) => '$slots/book-next/$tournamentId';
  static String cancelBooking(int slotId) => '$slots/$slotId/cancel';
  static String getWalletLedger(String firebaseUID) => '$wallets/$firebaseUID/ledger';
  static String cancelTransaction(int transactionId) => '$transactions/$transactionId/cancel';

  // App Configuration Endpoints
  static const String appVersion = '$_api/app/version';
  static const String filters = '$_api/filters';
  static const String platformInfo = '$_api/public/info';
  static const String registrationRequirements = '$_api/public/registration/requirements';

  static const String banners = '$_api/banners';
}

/// Enhanced API Service with comprehensive error handling, notification and payment support
class ApiService {
  static const Duration _networkTimeout = Duration(seconds: 12); // CHANGE: keep calls snappy to avoid UI stalls.
  
   
  
  static Future<List<BannerModel>> getActiveBanners() async {
    try {
      final response = await _get(_ApiEndpoints.banners, requireAuth: false);
      final data = _handleResponse(response) as List;
      
      final banners = data
          .map((json) => BannerModel.fromJson(json))
          .where((banner) => banner.isValid)
          .toList();
      
      // Sort by order
      banners.sort((a, b) => a.order.compareTo(b.order));
      
      return banners;
    } catch (e) {
      print('Error fetching banners: $e');
      return [];
    }
  }
  // ===========================================================================
  // Core Network Methods
  // ===========================================================================

  static Future<Map<String, String>> _getHeaders({bool requireAuth = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (requireAuth) {
      final token = await FirebaseAuthService.getIdToken();
      if (token == null) {
        print('⚠️ ApiService: Auth token is null for protected request');
        throw ApiException('Authentication token not available. Please sign in.');
      }
      print('🔐 ApiService: Adding Bearer token to headers');
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<http.Response> _get(String endpoint, {bool requireAuth = true}) async {
    try {
      final uri = Uri.parse('${_ApiEndpoints.baseUrl}$endpoint');
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await http.get(uri, headers: headers).timeout(_networkTimeout);
      return response;
    } on SocketException {
      throw ApiException('No internet connection');
    } on HttpException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } catch (e) {
      throw ApiException('Request failed: $e');
    }
  }

  static Future<http.Response> _post(String endpoint, {
    required Map<String, dynamic> body,
    bool requireAuth = true
  }) async {
    try {
      final uri = Uri.parse('${_ApiEndpoints.baseUrl}$endpoint');
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(body),
      ).timeout(_networkTimeout);
      return response;
    } on SocketException {
      throw ApiException('No internet connection');
    } on HttpException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } catch (e) {
      throw ApiException('Request failed: $e');
    }
  }

  static Future<http.Response> _patch(String endpoint, {
    Map<String, dynamic>? body,
    bool requireAuth = true
  }) async {
    try {
      final uri = Uri.parse('${_ApiEndpoints.baseUrl}$endpoint');
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await http.patch(
        uri,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      ).timeout(_networkTimeout);
      return response;
    } on SocketException {
      throw ApiException('No internet connection');
    } on HttpException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } catch (e) {
      throw ApiException('Request failed: $e');
    }
  }

  static Future<http.Response> _delete(String endpoint, {
    bool requireAuth = true
  }) async {
    try {
      final uri = Uri.parse('${_ApiEndpoints.baseUrl}$endpoint');
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await http.delete(
        uri,
        headers: headers,
      ).timeout(_networkTimeout);
      return response;
    } on SocketException {
      throw ApiException('No internet connection');
    } on HttpException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } catch (e) {
      throw ApiException('Request failed: $e');
    }
  }

  static dynamic _handleResponse(http.Response response) {
    try {
      final decodedBody = response.body.isNotEmpty ? json.decode(response.body) : {};
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decodedBody;
      } else {
        final errorMessage = decodedBody['message'] ?? 
                           decodedBody['error'] ?? 
                           'Unknown error occurred';
        throw ApiException('${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to parse response: $e');
    }
  }


 // ===========================================================================
// Enhanced Notification System Methods
// ===========================================================================

static Future<List<NotificationModel>> getNotifications() async {
  final response = await _get(_ApiEndpoints.notifications);
  final data = _handleResponse(response) as List;
  return data.map((json) => NotificationModel.fromJson(json)).toList();
}

static Future<void> markNotificationAsRead(int notificationId) async {
  await _patch(_ApiEndpoints.markNotificationRead(notificationId));
}

static Future<Map<String, dynamic>> getNotificationStats() async {
  final response = await _get(_ApiEndpoints.notificationStats);
  return _handleResponse(response) as Map<String, dynamic>;
}

// ===========================================================================
// Device Token Management for Enhanced Push Notifications
// ===========================================================================

/// Update device token for push notifications
/// CRITICAL: This endpoint requires Firebase ID token authentication
static Future<void> updateDeviceToken(String deviceToken) async {
  try {
    // FIXED: Use proper endpoint path according to API reference
    await _post('${_ApiEndpoints._api}/users/device-token', body: {
      'deviceToken': deviceToken,
    });
    print('✅ Device token updated successfully');
  } catch (e) {
    print('❌ Failed to update device token: $e');
    // Don't throw here as this shouldn't block app functionality
    // Token will be retried on next app launch
  }
}


static Future<Map<String, String>> getTournamentCredentials(int tournamentId) async {
    try {
      final response = await _get(
        _ApiEndpoints.getTournamentCredentials(tournamentId),
        requireAuth: true, // This is a protected endpoint
      );
      // The response is already a map, so we just need to cast it correctly.
      final data = _handleResponse(response) as Map<String, dynamic>;
      return data.map((key, value) => MapEntry(key, value.toString()));
    } on ApiException {
      // Re-throw API-specific exceptions to be handled by the UI.
      rethrow; 
    } catch (e) {
      // Wrap other errors in a standard exception format.
      throw ApiException('Failed to load tournament credentials: $e');
    }
  }


  // ===========================================================================
  // Payment QR Code API Calls (User Endpoints)
  // ===========================================================================

  /// Get QR code link for a specific amount (GET method)
  /// FIXED: Payment endpoints require auth as per logs
  static Future<PaymentQrResponse> getPaymentQrByAmount(int amount) async {
    try {
      final response = await _get(_ApiEndpoints.getPaymentQrByAmount(amount), requireAuth: true);
      final data = _handleResponse(response);
       print('✅ Data being passed to fromJson: $data'); 
      return PaymentQrResponse.fromJson(data);
    } catch (e) {
      throw PaymentException('Failed to get QR code for ₹$amount: ${e.toString()}');
    }
  }

  /// Get QR code link for a specific amount (POST method - alternative)
  /// FIXED: Payment endpoints require auth as per logs
  static Future<PaymentQrResponse> getPaymentQr(int amount) async {
    try {
      final response = await _post(_ApiEndpoints.paymentQr, 
        body: {'amount': amount},
        requireAuth: true
      );
      final data = _handleResponse(response);
      return PaymentQrResponse.fromJson(data);
    } catch (e) {
      throw PaymentException('Failed to get QR code for ₹$amount: ${e.toString()}');
    }
  }

  /// Get list of all available payment amounts
  /// FIXED: Changed requireAuth to true as this is a protected endpoint
  static Future<List<PaymentAmountModel>> getAvailablePaymentAmounts() async {
    try {
      final response = await _get(_ApiEndpoints.availableAmounts, requireAuth: true);
      final data = _handleResponse(response) as List;
      // Map the list of json objects to a list of AvailableAmount models
      return data.map((json) => PaymentAmountModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching payment amounts: $e');
      // Return default amounts if API fails
      return [
        PaymentAmountModel(amount: 50, coins: 50),
        PaymentAmountModel(amount: 100, coins: 100),
        PaymentAmountModel(amount: 200, coins: 200),
        PaymentAmountModel(amount: 500, coins: 500),
        PaymentAmountModel(amount: 1000, coins: 1000),
      ];
    }
  }

  /// Check payment service health
  static Future<Map<String, dynamic>> checkPaymentServiceHealth() async {
    try {
      final response = await _get(_ApiEndpoints.paymentHealth, requireAuth: false);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw PaymentException('Payment service health check failed: ${e.toString()}');
    }
  }

  /// Get QR code with error handling and fallback
  static Future<String?> getQrCodeWithFallback(int amount) async {
    try {
      // Try primary method first
      final qrResponse = await getPaymentQrByAmount(amount);
      return qrResponse.upiIdQrLink;
    } catch (e) {
      print('Primary QR method failed: $e');
      try {
        // Try alternative method
        final qrResponse = await getPaymentQr(amount);
        return qrResponse.upiIdQrLink;
      } catch (fallbackError) {
        print('Fallback QR method also failed: $fallbackError');
        throw PaymentException('Unable to retrieve QR code for ₹$amount. Please try again later.');
      }
    }
  }

  /// Validate payment amount against available amounts
  static Future<bool> isPaymentAmountAvailable(int amount) async {
    try {
      final availableAmounts = await getAvailablePaymentAmounts();
      return availableAmounts.contains(amount);
    } catch (e) {
      print('Error validating payment amount: $e');
      return false;
    }
  }

  // ===========================================================================
  // Tournament API Calls with Enhanced Features
  // ===========================================================================

  static Future<List<TournamentModel>> getUpcomingTournaments() async {
    final response = await _get(_ApiEndpoints.publicTournaments, requireAuth: false);
    final data = _handleResponse(response) as List;
    return data.map((json) => TournamentModel.fromJson(json)).toList();
  }

  static Future<TournamentModel> getTournamentById(int id) async {
    final response = await _get('${_ApiEndpoints.publicTournaments}/$id', requireAuth: false);
    final data = _handleResponse(response);
    return TournamentModel.fromJson(data);
  }

  static Future<TournamentModel> getTournamentDetails(int id) async {
    final response = await _get(_ApiEndpoints.getTournamentDetail(id));
    final data = _handleResponse(response);
    return TournamentModel.fromJson(data);
  }

  static Future<List<TournamentModel>> getAllTournaments() async {
    final response = await _get(_ApiEndpoints.tournaments);
    final data = _handleResponse(response) as List;
    return data.map((json) => TournamentModel.fromJson(json)).toList();
  }

  /// Get tournaments by status (UPCOMING, ONGOING, COMPLETED, CANCELLED)
  static Future<List<TournamentModel>> getTournamentsByStatus(String status) async {
    final response = await _get(_ApiEndpoints.getTournamentByStatus(status));
    final data = _handleResponse(response) as List;
    return data.map((json) => TournamentModel.fromJson(json)).toList();
  }

  // ===========================================================================
  // User Management with Enhanced Error Handling
  // ===========================================================================

  /// Register/Update Current User
  /// FIXED: Now includes firebaseUserUID as per API reference
  static Future<UserModel> registerUser(String userName, String email, {String? firebaseUserUID}) async {
    // Get Firebase UID if not provided
    final uid = firebaseUserUID ?? FirebaseAuthService.getCurrentUserUID();
    if (uid == null) {
      throw ApiException('Firebase user UID is required for registration');
    }

    final response = await _post(_ApiEndpoints.users, body: {
      'firebaseUserUID': uid,
      'userName': userName,
      'email': email,
    });
    final data = _handleResponse(response);
    return UserModel.fromJson(data);
  }

  static Future<UserModel> getUserProfile() async {
    final response = await _get(_ApiEndpoints.users);
    final data = _handleResponse(response);
    return UserModel.fromJson(data);
  }

  // ===========================================================================
  // Enhanced Booking System
  // ===========================================================================

  static Future<List<SlotsModel>> getTournamentSlotSummary(int tournamentId) async {
    final response = await _get(_ApiEndpoints.getSlotSummary(tournamentId));
    final data = _handleResponse(response) as Map<String, dynamic>;
    final rawSlots = data['slots'];
    if (rawSlots is! List) {
      print('⚠️ Slot summary response missing slots array for tournament $tournamentId');
      return [];
    }
    return rawSlots.map((json) => SlotsModel.fromJson(json)).toList();
  }

  static Future<SlotsModel> bookSlot(int tournamentId, String playerName, int slotNumber) async {
    final response = await _post(_ApiEndpoints.bookSlot, body: {
      'tournamentId': tournamentId,
      'playerName': playerName,
      'slotNumber': slotNumber,
    });
    final data = _handleResponse(response);
    return SlotsModel.fromJson(data);
  }

  static Future<List<SlotsModel>> getMyBookings() async {
    final response = await _get(_ApiEndpoints.myBookings);
    final data = _handleResponse(response) as List;
    return data.map((json) => SlotsModel.fromJson(json)).toList();
  }

  static Future<List<SlotsModel>> bookTeam({
    required int tournamentId,
    required List<Map<String, dynamic>> players,
  }) async {
    final response = await _post('${_ApiEndpoints.slots}/book-team', body: {
      'tournamentId': tournamentId,
      'players': players,
    });
    final data = _handleResponse(response) as List;
    return data.map((json) => SlotsModel.fromJson(json)).toList();
  }

  /// Book next available slot
  static Future<SlotsModel> bookNextAvailableSlot(int tournamentId, String playerName) async {
    final response = await _post(_ApiEndpoints.bookNextSlot(tournamentId), body: {
      'playerName': playerName,
    });
    final data = _handleResponse(response);
    return SlotsModel.fromJson(data);
  }

  /// Cancel my booking
  static Future<void> cancelBooking(int slotId) async {
    final response = await _delete(_ApiEndpoints.cancelBooking(slotId));
    // 204 No Content - just verify success
    if (response.statusCode != 204) {
      throw ApiException('Failed to cancel booking: ${response.statusCode}');
    }
  }

  // ===========================================================================
  // Enhanced Notification System
  // ===========================================================================

  // static Future<List<NotificationModel>> getNotifications() async {
  //   final response = await _get(_ApiEndpoints.notifications);
  //   final data = _handleResponse(response) as List;
  //   return data.map((json) => NotificationModel.fromJson(json)).toList();
  // }

  // static Future<void> markNotificationAsRead(int notificationId) async {
  //   await _patch(_ApiEndpoints.markNotificationRead(notificationId));
  // }

  // static Future<Map<String, dynamic>> getNotificationStats() async {
  //   final response = await _get(_ApiEndpoints.notificationStats);
  //   return _handleResponse(response) as Map<String, dynamic>;
  // }

  // ===========================================================================
  // Wallet & Transaction Methods
  // ===========================================================================

  static Future<WalletModel> getWallet(String firebaseUID) async {
    final response = await _get('${_ApiEndpoints.wallets}/$firebaseUID');
    final data = _handleResponse(response);
    return WalletModel.fromJson(data);
  }

  /// Get wallet ledger (transaction history)
  static Future<List<WalletLedgerModel>> getWalletLedger(String firebaseUID) async {
    final response = await _get(_ApiEndpoints.getWalletLedger(firebaseUID));
    final data = _handleResponse(response) as List;
    return data.map((json) => WalletLedgerModel.fromJson(json)).toList();
  }

  static Future<TransactionModel> createDepositRequest(String transactionUID, int amount) async {
    final depositRequest = DepositRequestModel(
      transactionUID: transactionUID,
      amount: amount,
    );
    final response = await _post(_ApiEndpoints.deposit, body: depositRequest.toJson());
    final data = _handleResponse(response);
    return TransactionModel.fromJson(data);
  }

  /// Create withdrawal request with UPI ID
  /// FIXED: Sends exact UPI ID as transactionUID (not hashed)
  static Future<TransactionModel> createWithdrawalRequest(int amount, {String? upiId}) async {
    final body = <String, dynamic>{
      'amount': amount,
    };
    
    // CRITICAL FIX: Send exact UPI ID as transactionUID if provided
    // Backend should receive the exact UPI ID, not a hash
    if (upiId != null && upiId.isNotEmpty) {
      body['transactionUID'] = upiId; // Send exact UPI ID
    }
    
    final response = await _post(_ApiEndpoints.withdraw, body: body);
    final data = _handleResponse(response);
    return TransactionModel.fromJson(data);
  }

  static Future<List<TransactionModel>> getTransactionHistory() async {
    final response = await _get(_ApiEndpoints.transactionHistory);
    final data = _handleResponse(response) as List;
    return data.map((json) => TransactionModel.fromJson(json)).toList();
  }

  /// Cancel pending transaction
  static Future<void> cancelTransaction(int transactionId) async {
    final response = await _delete(_ApiEndpoints.cancelTransaction(transactionId));
    // 204 No Content - just verify success
    if (response.statusCode != 204) {
      throw ApiException('Failed to cancel transaction: ${response.statusCode}');
    }
  }

  // ===========================================================================
  // Device Token Management for Push Notifications
  // ===========================================================================

  // static Future<void> updateDeviceToken(String deviceToken) async {
  //   try {
  //     await _post('${_ApiEndpoints.users}/device-token', body: {
  //       'deviceToken': deviceToken,
  //     });
  //   } catch (e) {
  //     print('Failed to update device token: $e');
  //     // Don't throw here as this shouldn't block app functionality
  //   }
  // }

  // ===========================================================================
  // Enhanced Payment Integration Utilities
  // ===========================================================================

  /// Get QR code for tournament registration fee
  static Future<String?> getTournamentPaymentQr(TournamentModel tournament) async {
    if (tournament.entryFee == null || tournament.entryFee! <= 0) {
      throw PaymentException('Tournament has no entry fee');
    }
    
    try {
      return await getQrCodeWithFallback(tournament.entryFee!);
    } catch (e) {
      throw PaymentException('Unable to get payment QR for tournament "${tournament.title}": ${e.toString()}');
    }
  }

  /// Validate if tournament entry fee is available for payment
  static Future<bool> canPayTournamentFee(TournamentModel tournament) async {
    if (tournament.entryFee == null || tournament.entryFee! <= 0) {
      return false;
    }
    
    return await isPaymentAmountAvailable(tournament.entryFee!);
  }

  // ===========================================================================
  // Utility Methods
  // ===========================================================================

  static Future<bool> checkTournamentCredentials(int tournamentId) async {
    try {
      final tournament = await getTournamentDetails(tournamentId);
      return tournament.gameId != null && tournament.gamePassword != null;
    } catch (e) {
      print('Error checking tournament credentials: $e');
      return false;
    }
  }

  static Future<Duration> getTimeUntilTournament(int tournamentId) async {
    try {
      final tournament = await getTournamentDetails(tournamentId);
      final now = DateTime.now();
      return tournament.startTime.difference(now);
    } catch (e) {
      print('Error getting tournament time: $e');
      return Duration.zero;
    }
  }

  /// Check if payment service is available
  static Future<bool> isPaymentServiceAvailable() async {
    try {
      final health = await checkPaymentServiceHealth();
      return health['status'] == 'UP';
    } catch (e) {
      print('Payment service health check failed: $e');
      return false;
    }
  }

  // ===========================================================================
  // App Configuration Endpoints
  // ===========================================================================

  /// Get app version information
  static Future<Map<String, dynamic>> getAppVersion() async {
    final response = await _get(_ApiEndpoints.appVersion, requireAuth: false);
    return _handleResponse(response) as Map<String, dynamic>;
  }

  /// Get filters (games, teamSizes, maps, timeSlots)
  static Future<Map<String, dynamic>> getFilters() async {
    final response = await _get(_ApiEndpoints.filters, requireAuth: false);
    return _handleResponse(response) as Map<String, dynamic>;
  }

  /// Get platform info
  static Future<Map<String, dynamic>> getPlatformInfo() async {
    final response = await _get(_ApiEndpoints.platformInfo, requireAuth: false);
    return _handleResponse(response) as Map<String, dynamic>;
  }

  /// Get registration requirements
  static Future<Map<String, dynamic>> getRegistrationRequirements() async {
    final response = await _get(_ApiEndpoints.registrationRequirements, requireAuth: false);
    return _handleResponse(response) as Map<String, dynamic>;
  }

  // --- App Config ---
  static Future<Map<String, dynamic>> getAppConfig() async {
    try {
      final response = await _get('/config/logo', requireAuth: false);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      // Return empty map on error to allow app to proceed with defaults
      print('Failed to load app config: $e');
      return {};
    }
  }
}

// ===========================================================================
// Payment Models and Exceptions
// ===========================================================================

/// Response model for payment QR code
// class PaymentQrResponse {
//   final int amount;
//   final String upiIdQrLink;

//   PaymentQrResponse({
//     required this.amount,
//     required this.upiIdQrLink,
//   });

//   factory PaymentQrResponse.fromJson(Map<String, dynamic> json) {
//     return PaymentQrResponse(
//       amount: json['amount'] as int,
//       upiIdQrLink: json['upiIdQrLink'] as String,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'amount': amount,
//       'upiIdQrLink': upiIdQrLink,
//     };
//   }

//   @override
//   String toString() {
//     return 'PaymentQrResponse(amount: ₹$amount, upiLink: ${upiIdQrLink.length > 50 ? '${upiIdQrLink.substring(0, 50)}...' : upiIdQrLink})';
//   }
// }

/// Custom exception class for API errors
class ApiException implements Exception {
  final String message;
  
  ApiException(this.message);
  
  @override
  String toString() => 'ApiException: $message';
}

/// Custom exception class for payment-related errors
class PaymentException implements Exception {
  final String message;
  
  PaymentException(this.message);
  
  @override
  String toString() => 'PaymentException: $message';
}   // int left=0;
        // int right=arr.length-1;
        // while(left<right){
        //     while(arr[left]==0 && left<right  ) left++;
        //     while(arr[right]==1 & left<right)right--;
        //     if(left<right){
        //         int t = arr[right];
        //         arr[right]=arr[left];
        //         arr[left]=t;
        //         left++;
        //         right--;
        //     }
        // }   // int left=0;
        // int right=arr.length-1;
        // while(left<right){
        //     while(arr[left]==0 && left<right  ) left++;
        //     while(arr[right]==1 & left<right)right--;
        //     if(left<right){
        //         int t = arr[right];
        //         arr[right]=arr[left];
        //         arr[left]=t;
        //         left++;
        //         right--;
        //     }
        // }
        
        