class CurrencyRate {
  const CurrencyRate({
    required this.code,
    required this.name,
    required this.flag,
    required this.afnPerUnit,
    this.displayUnit = 1,
  });

  final String code;
  final String name;
  final String flag;

  /// The number of Afghanis needed to buy one unit of this currency.
  final double afnPerUnit;

  /// Number of currency units used on rate cards for easier reading.
  final int displayUnit;

  CurrencyRate copyWith({double? afnPerUnit}) {
    return CurrencyRate(
      code: code,
      name: name,
      flag: flag,
      afnPerUnit: afnPerUnit ?? this.afnPerUnit,
      displayUnit: displayUnit,
    );
  }
}

class RateSnapshot {
  const RateSnapshot({
    required this.rates,
    required this.asOf,
    required this.source,
  });

  final List<CurrencyRate> rates;
  final DateTime asOf;
  final String source;
}
