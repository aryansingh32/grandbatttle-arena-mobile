class PaymentQrResponse {
  final int amount;
  final String upiIdQrLink;

  PaymentQrResponse({
    required this.amount,
    required this.upiIdQrLink,
  });

  factory PaymentQrResponse.fromJson(Map<String, dynamic> json) {
    // This is a good place for the robust fromJson factory
    if (json['amount'] == null || json['upiIdQrLink'] == null) {
      throw const FormatException("Missing required fields in PaymentQrResponse");
    }
    return PaymentQrResponse(
      amount: json['amount'],
      upiIdQrLink: json['upiIdQrLink'],
    );
  }
}