
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyProvider with ChangeNotifier {
  String _currencySymbol = '₹'; // Default value

  String get currencySymbol => _currencySymbol;

  Future<void> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    _currencySymbol = prefs.getString('selectedCurrencySymbol') ?? '₹';
    notifyListeners();
  }

  Future<void> setCurrency(String symbol, String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedCurrencySymbol', symbol);
    await prefs.setString('selectedCurrencyCode', code);
    await prefs.setBool('isCurrencySelected', true);
    _currencySymbol = symbol;
    notifyListeners();
  }
}
