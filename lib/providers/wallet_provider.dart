import 'package:flutter/foundation.dart';

class WalletProvider with ChangeNotifier {
  // This is our "mock" coin balance. It starts at100 for testing.
  int _coins = 100;

  // This allows other parts of the app to read the current coin balance.
  // The name of this getter is 'coins'.
  int get coins => _coins;
  int get balance => _coins;
  /// Simulates adding coins to the wallet after a successful payment.
  void addCoins(int amount) {
    _coins += amount;
    print('Added $amount coins. New balance: $_coins');
    // This tells any listening widgets to rebuild and show the new value.
    notifyListeners();
  }

  /// Simulates spending coins to join an event.
  /// Returns 'true' if the purchase was successful, and 'false' if not.
  bool spendCoins(int amount) {
    // Check if the user has enough coins.
    if (_coins >= amount) {
      _coins -= amount;
      print('Spent $amount coins. New balance: $_coins');
      // This tells any listening widgets to rebuild.
      notifyListeners();
      return true; // Purchase successful
    }

    // This part runs if the user does not have enough coins.
    print('Failed to spend $amount coins. Insufficient balance: $_coins');
    return false; // Purchase failed
  }
}
