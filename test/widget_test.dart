import 'package:currency_app/data/rate_repository.dart';
import 'package:currency_app/main.dart';
import 'package:currency_app/models/currency_rate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final snapshot = RateSnapshot(
    rates: const [
      CurrencyRate(
        code: 'USD',
        name: 'US Dollar',
        flag: '🇺🇸',
        afnPerUnit: 70,
      ),
      CurrencyRate(code: 'EUR', name: 'Euro', flag: '🇪🇺', afnPerUnit: 80),
      CurrencyRate(
        code: 'GBP',
        name: 'British Pound',
        flag: '🇬🇧',
        afnPerUnit: 90,
      ),
      CurrencyRate(
        code: 'AED',
        name: 'UAE Dirham',
        flag: '🇦🇪',
        afnPerUnit: 19,
      ),
      CurrencyRate(
        code: 'PKR',
        name: 'Pakistani Rupee',
        flag: '🇵🇰',
        afnPerUnit: .25,
      ),
    ],
    asOf: DateTime(2026, 8, 10),
    source: 'Test rates',
  );

  testWidgets('shows AFN rates on the dashboard', (tester) async {
    await tester.pumpWidget(CurrencyApp(repository: _FakeRepository(snapshot)));
    await tester.pumpAndSettle();

    expect(find.text('Exchange rates'), findsOneWidget);
    expect(find.text('70.00'), findsOneWidget);
    expect(find.text('US Dollar'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Euro'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Euro'), findsOneWidget);
  });

  testWidgets('converts USD to AFN and swaps the currencies', (tester) async {
    await tester.pumpWidget(CurrencyApp(repository: _FakeRepository(snapshot)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Convert').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('conversion_result')), findsOneWidget);
    expect(find.text('70.00'), findsOneWidget);

    await tester.tap(find.byKey(const Key('amount_field')));
    await tester.enterText(find.byKey(const Key('amount_field')), '2');
    await tester.pump();
    expect(find.text('140.00'), findsOneWidget);

    await tester.tap(find.byKey(const Key('swap_currencies')));
    await tester.pump();
    expect(find.text('0.029'), findsOneWidget);
  });
}

class _FakeRepository implements RateRepository {
  const _FakeRepository(this.snapshot);

  final RateSnapshot snapshot;

  @override
  Future<RateSnapshot> fetchRates() async => snapshot;
}
