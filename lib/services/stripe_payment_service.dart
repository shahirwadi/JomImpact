import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

import '../config/app_env.dart';
import '../models/marketplace_model.dart';
import '../models/user_model.dart';

class StripePaymentService {
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
        'Stripe is not configured. Add STRIPE_PUBLISHABLE_KEY and STRIPE_BACKEND_URL to env/dev.json, then restart the app.',
      );
    }

    final intent = await _post(<String, dynamic>{
      'action': 'createPaymentIntent',
      'itemId': item.id,
    });
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

    final order = await _post(<String, dynamic>{
      'action': 'finalizeOrder',
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
      order,
    );
  }

  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw StateError('Sign in before paying.');
    final response = await http.post(
      Uri.parse(AppEnv.stripeBackendUrl),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map ? decoded['error'] : null;
      throw StateError(message?.toString() ?? 'Payment server error.');
    }
    return Map<String, dynamic>.from(decoded as Map);
  }

  String? _optional(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
