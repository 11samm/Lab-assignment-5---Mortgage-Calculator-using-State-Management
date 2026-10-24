// Samuel Garcia | CECS 453 | Lab assignment 5 - Mortgage Calculator
import 'dart:math';

/// Annual interest is stored as a decimal: 3.5% is 0.035.
class Mortgage {
  Mortgage({this.amount = 100000, this.years = 30, this.rate = 0.035}) {
    if (!amount.isFinite ||
        amount < 0 ||
        years <= 0 ||
        !rate.isFinite ||
        rate < 0) {
      throw ArgumentError('Use a nonnegative amount/rate and positive years.');
    }
  }

  final double amount;
  final int years;
  final double rate;

  double get monthlyPayment {
    final months = years * 12;
    if (rate == 0) return amount / months;
    final monthlyRate = rate / 12;
    return amount * monthlyRate / (1 - pow(1 + monthlyRate, -months));
  }

  // Multiply the unrounded payment; round only for display.
  double get totalPayment => monthlyPayment * years * 12;

  static String money(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
    return '\$$whole.${parts[1]}';
  }
}
