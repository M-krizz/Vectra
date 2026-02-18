import 'package:flutter/foundation.dart';

class WalletService {
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  final ValueNotifier<double> balanceNotifier = ValueNotifier(2540.50);

  double get balance => balanceNotifier.value;

  void addTransaction(double amount) {
    balanceNotifier.value += amount;
  }

  void deductTransaction(double amount) {
    balanceNotifier.value -= amount;
  }
}
