import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moyasar/moyasar.dart';
import '../../../apis/core/api_response.dart';
import '../../data/models/feeding_checkout.dart';
import 'mock_checkout.dart';

/// SDK callbacks only close the sheet. Funding is confirmed by polling our API.
Future<void> openFeedingPayment(
  FeedingPaymentIntent intent,
  String method,
) async {
  final payload = intent.payload;
  final url = payload.strOrNull('checkout_url');
  if (intent.provider == 'mock') {
    if (url == null) throw StateError('Missing mock checkout URL');
    await launchMockCheckout(url);
    return;
  }
  final key =
      payload.strOrNull('publishable_key') ??
      payload.strOrNull('publishable_api_key');
  if ((intent.provider.isNotEmpty && intent.provider != 'moyasar') ||
      key == null ||
      payload.integer('amount_minor') <= 0 ||
      payload.str('currency').isEmpty) {
    throw ArgumentError(
      'Payment configuration is unavailable. Please try again.',
    );
  }
  final allowed = payload['methods'];
  final providerMethod = switch (method) {
    'card' => 'creditcard',
    'apple_pay' => 'applepay',
    'stc_pay' => 'stcpay',
    _ => '',
  };
  if (allowed is! List ||
      !allowed.any(
        (m) =>
            m == providerMethod ||
            m == method ||
            (m is Map &&
                (m['id'] == method || m['provider_method'] == providerMethod)),
      )) {
    throw ArgumentError('This payment method is unavailable.');
  }
  final apple = payload.object('apple_pay');
  final config = PaymentConfig(
    publishableApiKey: key,
    amount: payload.integer('amount_minor'),
    currency: payload.str('currency'),
    description: payload.str('description', 'Zoovana feeding'),
    metadata: payload.object('metadata'),
    givenID: payload.strOrNull('given_id'),
    creditCard: CreditCardConfig(saveCard: false, manual: false),
    applePay: apple == null
        ? null
        : ApplePayConfig(
            merchantId: apple.str('merchant_id'),
            label: apple.str('label', 'Zoovana'),
            manual: false,
            saveCard: false,
          ),
  );
  if (method == 'apple_pay' &&
      (config.applePay == null || config.applePay!.merchantId.isEmpty)) {
    throw ArgumentError('Apple Pay merchant configuration is unavailable.');
  }
  Object? result;
  await Get.bottomSheet<void>(
    SafeArea(
      child: Material(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Secure payment'.tr)),
                  IconButton(
                    onPressed: Get.back,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              switch (method) {
                'card' => CreditCard(
                  config: config,
                  onPaymentResult: (dynamic r) {
                    result = r;
                    Get.back<void>();
                  },
                ),
                'stc_pay' => STCPay(
                  config: config,
                  onPaymentResult: (dynamic r) {
                    result = r;
                    Get.back<void>();
                  },
                ),
                'apple_pay' => ApplePay(
                  config: config,
                  onPaymentResult: (dynamic r) {
                    result = r;
                    Get.back<void>();
                  },
                ),
                _ => Text('Payment method unavailable'.tr),
              },
            ],
          ),
        ),
      ),
    ),
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
  );
  if (result is! PaymentResponse ||
      (result as PaymentResponse).status != PaymentStatus.paid) {
    // A declined/cancelled SDK result is still reconciled by the caller.
    return;
  }
}
