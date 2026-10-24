// Samuel Garcia | CECS 453 | Lab assignment 5 - Mortgage Calculator
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mortgage_app/main.dart';
import 'package:mortgage_app/mortgage.dart';
import 'package:mortgage_app/mortgage_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('default payment pays off the mortgage in 360 months', () {
    final mortgage = Mortgage();
    var balance = 100000.0;
    for (var month = 0; month < 360; month++) {
      balance = balance * (1 + 0.035 / 12) - mortgage.monthlyPayment;
    }
    expect(balance, closeTo(0, 0.000001));
    expect(mortgage.monthlyPayment, closeTo(449.0446878, 0.000001));
    expect(Mortgage.money(mortgage.totalPayment), r'$161,656.09');
  });

  test('zero interest and principal work; invalid models are rejected', () {
    expect(Mortgage(amount: 12000, years: 10, rate: 0).monthlyPayment, 100);
    expect(Mortgage(amount: 0).monthlyPayment, 0);
    expect(() => Mortgage(amount: double.nan), throwsArgumentError);
    expect(() => Mortgage(years: 0), throwsArgumentError);
  });

  test('saved inputs survive a new provider instance', () async {
    final first = await MortgageProvider.load();
    var notifications = 0;
    first.addListener(() => notifications++);
    await first.save(Mortgage(amount: 250000, years: 15, rate: 0.0425));
    final reopened = await MortgageProvider.load();
    expect(reopened.mortgage.amount, 250000);
    expect(reopened.mortgage.years, 15);
    expect(reopened.mortgage.rate, 0.0425);
    expect(notifications, 1);
    first.dispose();
    reopened.dispose();
  });

  test('damaged and unsupported saved inputs use defaults', () async {
    for (final saved in [
      'invalid',
      '{"amount":1,"years":20,"rate":0.035}',
      '{"amount":1,"years":30,"rate":0.036}',
    ]) {
      SharedPreferences.setMockInitialValues({
        MortgageProvider.storageKey: saved,
      });
      final provider = await MortgageProvider.load();
      expect(provider.mortgage.amount, 100000);
      expect(provider.mortgage.years, 30);
      expect(provider.mortgage.rate, 0.035);
      provider.dispose();
    }
  });

  testWidgets('terms require confirmation', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MortgageApp(provider: await MortgageProvider.load()),
    );
    expect(find.text(r'$449.04'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, false);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agree'));
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, true);
  });

  testWidgets('Done saves edits; Back discards edits', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MortgageApp(provider: await MortgageProvider.load()),
    );
    await tester.tap(find.text('Modify Data'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '200000');
    await tester.tap(find.text('15'));
    await tester.tap(find.text('4.00%'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text(r'$200,000.00'), findsOneWidget);
    expect(find.text('4.00%'), findsOneWidget);
    expect(find.text(r'$1,479.38'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      MortgageApp(provider: await MortgageProvider.load()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modify Data'));
    await tester.pumpAndSettle();
    expect(find.text('4.00%'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      '200000.00',
    );
    await tester.enterText(find.byType(TextFormField), '999');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(r'$200,000.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('validates amounts and offers both rate endpoints', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MortgageApp(provider: await MortgageProvider.load()),
    );
    await tester.tap(find.text('Modify Data'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '-10');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid amount of zero or more.'), findsOneWidget);
    final rates = find.byType(ListView).last;
    await tester.drag(rates, const Offset(0, 2000));
    await tester.pumpAndSettle();
    expect(find.text('2.00%'), findsOneWidget);
    await tester.drag(rates, const Offset(0, -5000));
    await tester.pumpAndSettle();
    expect(find.text('15.00%'), findsOneWidget);
    await tester.tap(find.text('15.00%'));
    await tester.enterText(find.byType(TextFormField), '0');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('15.00%'), findsOneWidget);
    expect(find.text(r'$0.00'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}
