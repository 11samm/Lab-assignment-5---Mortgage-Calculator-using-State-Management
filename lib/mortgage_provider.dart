// Samuel Garcia | CECS 453 | Lab assignment 5 - Mortgage Calculator
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mortgage.dart';

/// One shared model for both screens; saved before reporting a successful edit.
class MortgageProvider extends ChangeNotifier {
  MortgageProvider._(this._preferences, this._mortgage);

  static const storageKey = 'mortgage_terms';
  final SharedPreferences _preferences;
  Mortgage _mortgage;

  Mortgage get mortgage => _mortgage;

  static Future<MortgageProvider> load() async {
    final preferences = await SharedPreferences.getInstance();
    var mortgage = Mortgage();
    // An absent or damaged record starts with the assignment defaults.
    try {
      final saved = preferences.getString(storageKey);
      if (saved != null) {
        final data = jsonDecode(saved) as Map<String, dynamic>;
        final amount = (data['amount'] as num).toDouble();
        final years = data['years'] as int;
        final rate = (data['rate'] as num).toDouble();
        final rateStep = (rate * 100 - 2) / 0.25;
        if (amount.isFinite &&
            amount >= 0 &&
            amount <= 1e12 &&
            [10, 15, 30].contains(years) &&
            rate.isFinite &&
            rate >= 0.02 &&
            rate <= 0.15 &&
            (rateStep - rateStep.round()).abs() < 0.000001) {
          mortgage = Mortgage(amount: amount, years: years, rate: rate);
        }
      }
    } catch (_) {
      // Invalid stored data should not prevent the app from opening.
    }
    return MortgageProvider._(preferences, mortgage);
  }

  Future<void> save(Mortgage mortgage) async {
    // One record keeps the three loan inputs together.
    final saved = await _preferences.setString(
      storageKey,
      jsonEncode({
        'amount': mortgage.amount,
        'years': mortgage.years,
        'rate': mortgage.rate,
      }),
    );
    if (!saved) throw StateError('Unable to save mortgage terms.');
    _mortgage = mortgage;
    notifyListeners();
  }
}
