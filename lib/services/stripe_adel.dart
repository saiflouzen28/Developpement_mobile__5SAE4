import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class StripeAdelService {
  static const String _secretKey =
      'sk_test_51SFxjBLDDekZ5pn6zBZibuZMIlv4AYyWpUg5gTkdlM82NtwsUPwIuIJ6cCds1EEZaIZsx07OvhqO2VuvC60sBxwh005IWUybu4';
  static const String _publishableKey =
      'pk_test_51SFxjBLDDekZ5pn6q5hAX2z9XdUag96TFklwzCdaZ68kma54erkUiBzmfNbHVM3nOBbrEHHDUte0BxTP72rZpQ4B00ApXxvsMl';

  static void init() {
    Stripe.publishableKey = _publishableKey;
  }

  static Future<bool> openPaymentSheet({
    required BuildContext context,
    required double amount,
  }) async {
    try {
      // 1️⃣ Crée le PaymentIntent
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': (amount * 100).toInt().toString(),
          'currency': 'usd', // ⚠️ pas TND
          'payment_method_types[]': 'card',
        },
      );

      final data = json.decode(response.body);
      final clientSecret = data['client_secret'];

      if (clientSecret == null) throw 'Erreur de création du paiement';

      // 2️⃣ Initialise la feuille de paiement Stripe
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'E-learning App',
        ),
      );

      // 3️⃣ Affiche la vraie PaymentSheet Stripe
      await Stripe.instance.presentPaymentSheet();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Paiement réussi !')),
      );

      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur Stripe : $e')),
      );
      return false;
    }
  }
}