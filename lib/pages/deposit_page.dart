import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grand_battle_arena/models/payment_qr_response.dart';

import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gal/gal.dart'; // Modern alternative to image_gallery_saver
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'package:grand_battle_arena/services/api_service.dart'; // Your ApiService
import 'package:grand_battle_arena/theme/appcolor.dart';      // Your app's color theme
import 'package:grand_battle_arena/models/transaction_model.dart'; // Your TransactionModel

// // A simple response model based on your backend DTO
// class PaymentQrResponse {
//   final int amount;
//   final String upiIdQrLink;

//   PaymentQrResponse({required this.amount, required this.upiIdQrLink});

//   factory PaymentQrResponse.fromJson(Map<String, dynamic> json) {
//     return PaymentQrResponse(
//       amount: json['amount'],
//       upiIdQrLink: json['upiIdQrLink'],
//     );
//   }
// }

class PaymentPage extends StatefulWidget {
  final int amount;
  const PaymentPage({super.key, required this.amount});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _uidController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  PaymentQrResponse? _paymentDetails;

  @override
  void initState() {
    super.initState();
    _fetchQrCode();
  }

  @override
  void dispose() {
    _uidController.dispose();
    super.dispose();
  }

  Future<void> _fetchQrCode() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiService.getPaymentQrByAmount(widget.amount);
      print(response.upiIdQrLink);
      if (mounted) {
        setState(() {
          _paymentDetails = response as PaymentQrResponse?;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
           print('❌ Image.network Error: $_error');

        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Download QR code image to gallery
  /// FIXED: Using modern 'gal' package instead of image_gallery_saver
  Future<void> _downloadQrImage() async {
    if (_paymentDetails == null || _paymentDetails!.upiIdQrLink.isEmpty) {
      Fluttertoast.showToast(msg: "QR code not available");
      return;
    }

    try {
      // Request photo library permission (gal package handles this automatically)
      // But we'll request it explicitly for better UX
      PermissionStatus status;
      if (Platform.isAndroid) {
        // For Android 13+ (API 33+), use photos permission
        if (await _isAndroid13OrAbove()) {
          status = await Permission.photos.request();
        } else {
          // For Android 12 and below
          status = await Permission.storage.request();
        }
      } else {
        // iOS
        status = await Permission.photos.request();
      }

      if (!status.isGranted) {
        Fluttertoast.showToast(
          msg: "Photo library permission is required to save QR code",
          toastLength: Toast.LENGTH_LONG,
        );
        return;
      }

      // Show loading
      Fluttertoast.showToast(msg: "Downloading QR code...", toastLength: Toast.LENGTH_SHORT);

      // Download image using Dio
      var response = await Dio().get(
        _paymentDetails!.upiIdQrLink,
        options: Options(responseType: ResponseType.bytes),
      );

      // Request access to photo library (gal package)
      await Gal.requestAccess();

      // Get temporary directory to save the image
      final tempDir = await getTemporaryDirectory();
      final fileName = "battle_arena_qr_${widget.amount}_${DateTime.now().millisecondsSinceEpoch}.png";
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(response.data);

      // Save to gallery using gal package (uses file path)
      await Gal.putImage(file.path);

      Fluttertoast.showToast(
        msg: "QR Code saved to gallery!",
        backgroundColor: Colors.green,
        toastLength: Toast.LENGTH_LONG,
      );
    } catch (e) {
      print('Error downloading QR code: $e');
      Fluttertoast.showToast(
        msg: "Failed to save image: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    }
  }

  /// Check if Android version is 13 or above (API 33+)
  Future<bool> _isAndroid13OrAbove() async {
    if (!Platform.isAndroid) return false;
    try {
      // Android 13 is API level 33
      return Platform.version.contains('33') || 
             Platform.version.contains('34') || 
             Platform.version.contains('35');
    } catch (e) {
      // Default to false if we can't determine
      return false;
    }
  }

  Future<void> _submitDeposit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final uid = _uidController.text.trim();
      final TransactionModel transaction = await ApiService.createDepositRequest(uid, widget.amount);

      Fluttertoast.showToast(
          msg: "Deposit request for ₹${transaction.amount} received! It will be reviewed shortly.",
          toastLength: Toast.LENGTH_LONG,
      );

      // Navigate back on success
      if (mounted) Navigator.pop(context, true);

    } catch (e) {
      Fluttertoast.showToast(
        msg: e.toString(),
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolor.primary,
      appBar: AppBar(
        title: Text("Pay ₹${widget.amount}"),
        backgroundColor: Appcolor.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Appcolor.white),
      ),
      // body:_buildPaymentForm(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Appcolor.secondary))
          : _error != null
              ? _buildErrorState()
              : _buildPaymentForm(),
    );
  }

  Widget _buildPaymentForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Improved header with icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Appcolor.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    color: Appcolor.secondary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Scan QR Code",
                  style: TextStyle(
                    color: Appcolor.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Amount: ₹${widget.amount}",
              style: const TextStyle(
                color: Appcolor.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            _buildQrCodeCard(),
            const SizedBox(height: 24),
            // Improved UID input section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Appcolor.cardsColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Appcolor.secondary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.receipt_long,
                        color: Appcolor.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Transaction UID",
                        style: TextStyle(
                          color: Appcolor.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _uidController,
                    keyboardType: TextInputType.text,
                    style: const TextStyle(
                      color: Appcolor.white,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: "Enter transaction UID from payment receipt",
                      hintStyle: TextStyle(
                        color: Appcolor.grey.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Appcolor.primary.withOpacity(0.5),
                      prefixIcon: const Icon(
                        Icons.confirmation_number,
                        color: Appcolor.secondary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Appcolor.secondary.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Appcolor.secondary.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Appcolor.secondary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter the transaction UID';
                      }
                      if (value.length < 10) {
                        return 'Please enter a valid UID (min 10 characters)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildHowToFindUidLink(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Improved submit button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitDeposit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Appcolor.secondary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadowColor: Appcolor.secondary.withOpacity(0.3),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Appcolor.primary,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Appcolor.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Submit Deposit Request",
                            style: TextStyle(
                              color: Appcolor.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            // Info text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Appcolor.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Appcolor.secondary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Appcolor.secondary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Your deposit will be reviewed and credited within 24 hours",
                      style: TextStyle(
                        color: Appcolor.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrCodeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Appcolor.cardsColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Appcolor.secondary.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Appcolor.secondary.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // QR Code with improved styling
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Image.network(
                    _paymentDetails!.upiIdQrLink,
                    fit: BoxFit.contain,
                    width: 250,
                    height: 250,
                    loadingBuilder: (context, child, progress) {
                      return progress == null
                          ? child
                          : Container(
                              width: 250,
                              height: 250,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Appcolor.secondary,
                                ),
                              ),
                            );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.error_outline_rounded,
                            color: Colors.red,
                            size: 50,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Amount display
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Appcolor.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/icons/dollar.png',
                      width: 20,
                      height: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₹${widget.amount}',
                      style: const TextStyle(
                        color: Appcolor.secondary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Download button with better positioning
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: _downloadQrImage,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Appcolor.secondary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Appcolor.secondary.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.download_rounded,
                  color: Appcolor.primary,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToFindUidLink() {
    return InkWell(
      onTap: () => _showUidHelpDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Appcolor.secondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Appcolor.secondary.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.help_outline,
              color: Appcolor.secondary,
              size: 18,
            ),
            const SizedBox(width: 6),
            const Text(
              "How to find Transaction UID?",
              style: TextStyle(
                color: Appcolor.secondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

   Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          const SizedBox(height: 16),
          
          Text(
            'Failed to load QR Code',
            style: const TextStyle(color: Appcolor.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchQrCode,
            style: ElevatedButton.styleFrom(backgroundColor: Appcolor.secondary),
            child: const Text('Retry', style: TextStyle(color: Appcolor.primary)),
          ),
        ],
      ),
    );
  }

  void _showUidHelpDialog(BuildContext context) {
    // IMPORTANT: Replace 'QLo44T2b_cQ' with your actual YouTube video ID
    const String youtubeVideoId = 'QLo44T2b_cQ';

    final YoutubePlayerController controller = YoutubePlayerController(
      initialVideoId: youtubeVideoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
      ),
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: StatefulBuilder(
          builder: (context, setState) {
            int currentPage = 0;
            PageController pageController = PageController();

            return Container(
              height: 450,
              decoration: BoxDecoration(
                color: Appcolor.primary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Appcolor.grey),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: pageController,
                      onPageChanged: (index) {
                        setState(() {
                          currentPage = index;
                        });
                      },
                      children: [
                        // Slide 1: Image Tutorial
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Find UID/Ref No. in Payment Details", style: TextStyle(color: Appcolor.white, fontSize: 16)),
                              const SizedBox(height: 15),
                              // IMPORTANT: Ensure you have this image in your assets folder
                              Image.asset('assets/images/how_to_find_uid.jpg'),
                              const SizedBox(height: 10),
                              const Text("Swipe for video tutorial ->", style: TextStyle(color: Appcolor.grey)),
                            ],
                          ),
                        ),
                        // Slide 2: Video Tutorial
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: YoutubePlayer(
                            controller: controller,
                            showVideoProgressIndicator: true,
                            progressIndicatorColor: Appcolor.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Page Indicators
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(2, (index) =>
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: currentPage == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: currentPage == index ? Appcolor.secondary : Appcolor.grey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        )
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    ).whenComplete(() {
      controller.dispose(); // Important to dispose the controller
    });
  }
}