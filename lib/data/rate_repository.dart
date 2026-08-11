import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/currency_rate.dart';

abstract interface class RateRepository {
  Future<RateSnapshot> fetchRates();
}

class RateFetchException implements Exception {
  const RateFetchException([
    this.message =
        'Unable to load live rates. Check your internet connection and try again.',
  ]);

  final String message;

  @override
  String toString() => message;
}

class RemoteRateRepository implements RateRepository {
  RemoteRateRepository({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static const _endpoint =
      'https://api.frankfurter.dev/v2/rates?base=AFN&quotes=USD,EUR,GBP,CHF,AED,SAR,PKR,INR,CNY,IRR&providers=DAB';

  @override
  Future<RateSnapshot> fetchRates() async {
    try {
      final response = await _client
          .get(
            Uri.parse(_endpoint),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        throw const RateFetchException();
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) throw const RateFetchException();

      final quoteRates = <String, double>{};
      DateTime? publishedDate;
      for (final entry in decoded) {
        if (entry is! Map<String, dynamic>) continue;
        final quote = entry['quote'];
        final rate = entry['rate'];
        if (quote is String && rate is num && rate > 0) {
          // The endpoint returns foreign-currency units per AFN. The app shows
          // the inverse: AFN per one unit of the foreign currency.
          quoteRates[quote] = 1 / rate.toDouble();
        }
        publishedDate ??= DateTime.tryParse(entry['date']?.toString() ?? '');
      }

      final rates = _currencyMetadata.entries
          .where((entry) => quoteRates.containsKey(entry.key))
          .map((entry) {
            final metadata = entry.value;
            return CurrencyRate(
              code: entry.key,
              name: metadata.name,
              flag: metadata.flag,
              afnPerUnit: quoteRates[entry.key]!,
              displayUnit: metadata.displayUnit,
            );
          })
          .toList(growable: false);

      if (rates.length != _currencyMetadata.length || publishedDate == null) {
        throw const RateFetchException(
          'The live rate service returned incomplete data. Please try again.',
        );
      }

      return RateSnapshot(
        rates: rates,
        asOf: publishedDate,
        source: 'Da Afghanistan Bank reference rates',
      );
    } on RateFetchException {
      rethrow;
    } catch (_) {
      throw const RateFetchException();
    }
  }

  // These are display labels only. Every numeric rate is supplied by DAB.
  static const Map<String, ({String name, String flag, int displayUnit})>
  _currencyMetadata = {
    'USD': (name: 'US Dollar', flag: '🇺🇸', displayUnit: 1),
    'EUR': (name: 'Euro', flag: '🇪🇺', displayUnit: 1),
    'GBP': (name: 'British Pound', flag: '🇬🇧', displayUnit: 1),
    'CHF': (name: 'Swiss Franc', flag: '🇨🇭', displayUnit: 1),
    'AED': (name: 'UAE Dirham', flag: '🇦🇪', displayUnit: 1),
    'SAR': (name: 'Saudi Riyal', flag: '🇸🇦', displayUnit: 1),
    'PKR': (name: 'Pakistani Rupee', flag: '🇵🇰', displayUnit: 1000),
    'INR': (name: 'Indian Rupee', flag: '🇮🇳', displayUnit: 1000),
    'CNY': (name: 'Chinese Yuan', flag: '🇨🇳', displayUnit: 1),
    'IRR': (name: 'Iranian Rial', flag: '🇮🇷', displayUnit: 100000),
  };
}
