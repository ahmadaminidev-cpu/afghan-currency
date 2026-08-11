import 'package:currency_app/data/rate_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('inverts AFN-base API rates into AFN per foreign unit', () async {
    final client = MockClient((request) async {
      expect(request.url.queryParameters['providers'], 'DAB');
      return http.Response(
        '[{"date":"2026-08-10","base":"AFN","quote":"USD","rate":0.0142857143},'
        '{"date":"2026-08-10","base":"AFN","quote":"EUR","rate":0.0125},'
        '{"date":"2026-08-10","base":"AFN","quote":"GBP","rate":0.0111111111},'
        '{"date":"2026-08-10","base":"AFN","quote":"CHF","rate":0.01},'
        '{"date":"2026-08-10","base":"AFN","quote":"AED","rate":0.0526315789},'
        '{"date":"2026-08-10","base":"AFN","quote":"SAR","rate":0.05},'
        '{"date":"2026-08-10","base":"AFN","quote":"PKR","rate":4},'
        '{"date":"2026-08-10","base":"AFN","quote":"INR","rate":2},'
        '{"date":"2026-08-10","base":"AFN","quote":"CNY","rate":0.1},'
        '{"date":"2026-08-10","base":"AFN","quote":"IRR","rate":10000}]',
        200,
      );
    });

    final snapshot = await RemoteRateRepository(client: client).fetchRates();

    expect(snapshot.rates.first.afnPerUnit, closeTo(70, .001));
    expect(snapshot.rates[1].afnPerUnit, closeTo(80, .001));
    expect(snapshot.rates[6].afnPerUnit, closeTo(.25, .001));
    expect(snapshot.source, 'Da Afghanistan Bank reference rates');
  });

  test('returns no rates when the request fails', () async {
    final client = MockClient(
      (request) async => http.Response('Unavailable', 503),
    );

    expect(
      RemoteRateRepository(client: client).fetchRates,
      throwsA(isA<RateFetchException>()),
    );
  });
}
