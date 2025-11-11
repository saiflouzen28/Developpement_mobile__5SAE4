// lib/services/stripe_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class StripeService {
  // IMPORTANT: Your Stripe Secret Key - ONLY use test keys during development
  // In production, this should NEVER be in your mobile app - use a backend server instead
  static const String _stripeSecretKey = '';

  /// Creates a PaymentIntent on Stripe servers
  static Future<Map<String, dynamic>?> _createPaymentIntent({
    required String amount,
    required String currency,
  }) async {
    try {
      final url = Uri.parse('https://api.stripe.com/v1/payment_intents');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': amount,
          'currency': currency,
          'payment_method_types[]': 'card',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Payment Intent created: ${data['id']}');
        return data;
      } else {
        print('❌ Failed to create Payment Intent');
        print('Status: ${response.statusCode}');
        print('Body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error creating payment intent: $e');
      return null;
    }
  }

  /// Main payment handler - call this from your UI
  static Future<bool> handlePayment(
      BuildContext context, {
        required String userEmail,
        required String amount, // Amount in cents (e.g., '500' = $5.00)
        required String currency,
      }) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

      // Step 1: Create Payment Intent
      final paymentIntentData = await _createPaymentIntent(
        amount: amount,
        currency: currency,
      );

      // Remove loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (paymentIntentData == null) {
        _showError(context, '❌ Could not initialize payment. Please try again.');
        return false;
      }

      final clientSecret = paymentIntentData['client_secret'] as String?;
      if (clientSecret == null) {
        _showError(context, '❌ Invalid payment response. Please try again.');
        return false;
      }

      // Step 2: Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'E-Learning Events',
          billingDetails: BillingDetails(
            email: userEmail,
          ),
          style: ThemeMode.system,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF6366F1),
            ),
          ),
        ),
      );

      print('✅ Payment Sheet initialized');

      // Step 3: Present Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      print('✅ Payment successful!');

      if (context.mounted) {
        _showSuccess(context, '✅ Payment successful!');
      }

      return true;

    } on StripeException catch (e) {
      print('❌ Stripe Exception: ${e.error.code}');

      if (e.error.code == FailureCode.Canceled) {
        print('Payment canceled by user');
        if (context.mounted) {
          _showError(context, 'Payment canceled');
        }
      } else {
        print('Payment failed: ${e.error.message}');
        if (context.mounted) {
          _showError(context, 'Payment failed: ${e.error.localizedMessage ?? "Unknown error"}');
        }
      }
      return false;

    } catch (e) {
      print('❌ Unexpected error: $e');
      if (context.mounted) {
        _showError(context, 'An unexpected error occurred. Please try again.');
      }
      return false;
    }
  }

  static void _showError(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void _showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
