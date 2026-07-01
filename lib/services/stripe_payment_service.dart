import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_stripe/flutter_stripe.dart';

import '../config/app_env.dart';
import '../models/marketplace_model.dart';
import '../models/user_model.dart';

class StripePaymentService {
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  Future<MarketplacePurchaseModel> payForItem({
    required MarketplaceItemModel item,
    required UserModel buyer,
    required String recipientName,
    required String phone,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String postcode,
    String? deliveryInstructions,
  }) async {
    if (!AppEnv.isStripeConfigured) {
      throw StateError(
        'Stripe test mode is not configured. Add STRIPE_PUBLISHABLE_KEY to env/dev.json and restart the app.',
      );
    }

    final intentResult = await _functions
        .httpsCallable('createStripePaymentIntent')
        .call(<String, dynamic>{'itemId': item.id});
    final intent = Map<String, dynamic>.from(intentResult.data as Map);
    final clientSecret = intent['clientSecret'] as String?;
    final paymentIntentId = intent['paymentIntentId'] as String?;
    if (clientSecret == null || paymentIntentId == null) {
      throw StateError('Stripe did not return valid payment details.');
    }

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'JomImpact',
        style: ThemeMode.system,
        billingDetails: BillingDetails(
          name: buyer.name,
          email: buyer.email,
          phone: phone.trim(),
          address: Address(
            line1: addressLine1.trim(),
            line2: _optional(addressLine2),
            city: city.trim(),
            state: state.trim(),
            postalCode: postcode.trim(),
            country: 'MY',
          ),
        ),
      ),
    );
    await Stripe.instance.presentPaymentSheet();

    final finalizeResult = await _functions
        .httpsCallable('finalizeStripeOrder')
        .call(<String, dynamic>{
      'paymentIntentId': paymentIntentId,
      'recipientName': recipientName.trim(),
      'phone': phone.trim(),
      'addressLine1': addressLine1.trim(),
      'addressLine2': _optional(addressLine2),
      'city': city.trim(),
      'state': state.trim(),
      'postcode': postcode.trim(),
      'country': 'Malaysia',
      'deliveryInstructions': _optional(deliveryInstructions),
    });
    return MarketplacePurchaseModel.fromMap(
      Map<String, dynamic>.from(finalizeResult.data as Map),
    );
  }

  String? _optional(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
