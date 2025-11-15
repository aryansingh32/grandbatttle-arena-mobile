import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grand_battle_arena/models/payment_qr_response.dart';

import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
// import 'package:gallery_saver/gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

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

  Future<void> _downloadQrImage() async {
    // 1. Request Permission
    var status = await Permission.storage.request();
    if (status.isGranted) {
      try {
        // 2. Download image using Dio
        var response = await Dio().get(
          _paymentDetails!.upiIdQrLink,
          options: Options(responseType: ResponseType.bytes),
        );
        // 3. Save to gallery
        // await ImageGallerySaver.saveImage(
        //   Uint8List.fromList(response.data),
        //   quality: 100,
        //   name: "battle_arena_qr_${widget.amount}",
        // );
        Fluttertoast.showToast(msg: "QR Code saved to gallery!");
      } catch (e) {
        Fluttertoast.showToast(msg: "Failed to save image. Please try again.");
      }
    } else {
      Fluttertoast.showToast(msg: "Storage permission denied.");
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
            const Text(
              "Scan This QR",
              style: TextStyle(
                color: Appcolor.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildQrCodeCard(),
            const SizedBox(height: 32),
            _buildHowToFindUidLink(),
            const SizedBox(height: 12),
            TextFormField(
              controller: _uidController,
              keyboardType: TextInputType.text,
              style: const TextStyle(color: Appcolor.white),
              decoration: InputDecoration(
                hintText: "Enter Your UID....",
                hintStyle: const TextStyle(color: Appcolor.grey),
                filled: true,
                fillColor: Appcolor.cardsColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the transaction UID';
                }
                if (value.length < 10) { // Basic validation
                   return 'Please enter a valid UID';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitDeposit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Appcolor.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Appcolor.primary))
                    : const Text(
                        "Submit",
                        style: TextStyle(
                            color: Appcolor.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrCodeCard() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(
            _paymentDetails!.upiIdQrLink,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              return progress == null
                  ? child
                  : AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Appcolor.cardsColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(child: CircularProgressIndicator(color: Appcolor.secondary)),
                      ),
                    );
            },
            errorBuilder: (context, error, stackTrace) {
              return AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Appcolor.cardsColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(child: Icon(Icons.error_outline_rounded, color: Colors.red, size: 50)),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 10,
          right: 10,
          child: GestureDetector(
            onTap: _downloadQrImage,
            child: const CircleAvatar(
              backgroundColor: Appcolor.secondary,
              child: Icon(Icons.download, color: Appcolor.primary),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildHowToFindUidLink() {
    return InkWell(
      onTap: () => _showUidHelpDialog(context),
      child: const Text(
        "How To Find UID?",
        style: TextStyle(
          color: Appcolor.secondary,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
          decorationColor: Appcolor.secondary,
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