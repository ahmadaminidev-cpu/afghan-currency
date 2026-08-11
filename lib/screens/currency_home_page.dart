import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/rate_repository.dart';
import '../models/currency_rate.dart';

const _green = Color(0xFF08745B);
const _darkGreen = Color(0xFF0B3D30);
const _muted = Color(0xFF68756F);
const _ratesSurface = Color(0xFFF8FAF8);

class CurrencyHomePage extends StatefulWidget {
  const CurrencyHomePage({super.key, required this.repository});

  final RateRepository repository;

  @override
  State<CurrencyHomePage> createState() => _CurrencyHomePageState();
}

class _CurrencyHomePageState extends State<CurrencyHomePage> {
  int _selectedIndex = 0;
  RateSnapshot? _snapshot;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final snapshot = await widget.repository.fetchRates();
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _isLoading = false;
      });
    } on RateFetchException catch (error) {
      if (!mounted) return;
      setState(() {
        _snapshot = null;
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _snapshot = null;
        _errorMessage =
            'Unable to load live rates. Check your internet connection and try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _selectedIndex == 0
            ? _RatesDashboard(
                key: const ValueKey('rates'),
                snapshot: _snapshot,
                errorMessage: _errorMessage,
                isLoading: _isLoading,
                onRefresh: _refresh,
              )
            : _ConverterPage(
                key: const ValueKey('converter'),
                snapshot: _snapshot,
                errorMessage: _errorMessage,
                isLoading: _isLoading,
                onRetry: _refresh,
              ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE3E9E6))),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.trending_up_rounded),
              selectedIcon: Icon(Icons.trending_up_rounded, color: _green),
              label: 'Rates',
            ),
            NavigationDestination(
              icon: Icon(Icons.swap_horiz_rounded),
              selectedIcon: Icon(Icons.swap_horiz_rounded, color: _green),
              label: 'Convert',
            ),
          ],
        ),
      ),
    );
  }
}

class _RatesDashboard extends StatelessWidget {
  const _RatesDashboard({
    super.key,
    required this.snapshot,
    required this.errorMessage,
    required this.isLoading,
    required this.onRefresh,
  });

  final RateSnapshot? snapshot;
  final String? errorMessage;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final snapshot = this.snapshot;
    final rates = snapshot?.rates ?? const <CurrencyRate>[];

    final Widget body;
    if (!isLoading && snapshot == null) {
      body = _RateLoadError(
        key: const ValueKey('rates_error'),
        message:
            errorMessage ??
            'Live rates are unavailable. Please connect to the internet and try again.',
        onRetry: onRefresh,
      );
    } else if (snapshot == null) {
      body = const _RatesLoadingView(key: ValueKey('rates_loading'));
    } else {
      body = RefreshIndicator(
        key: const ValueKey('rates_list'),
        color: _green,
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 10),
              sliver: SliverToBoxAdapter(child: _RatesColumnHeader()),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList.separated(
                itemCount: rates.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 1,
                  indent: 54,
                  color: Color(0xFFE1E8E4),
                ),
                itemBuilder: (context, index) => _RateTile(rate: rates[index]),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(24, 22, 24, 34),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Official reference rates. Cash-market prices may differ.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted, fontSize: 11, height: 1.4),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF083D34), Color(0xFF0B5B4C)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _Header(
                snapshot: snapshot,
                isLoading: isLoading,
                onRefresh: onRefresh,
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: ColoredBox(
                    color: _ratesSurface,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: body,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.snapshot,
    required this.isLoading,
    required this.onRefresh,
  });

  final RateSnapshot? snapshot;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 12, 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Exchange rates',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      height: 1.08,
                      letterSpacing: -.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: 15,
                        color: Color(0xFF84E1C4),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          snapshot == null
                              ? 'Official Da Afghanistan Bank rates'
                              : 'Da Afghanistan Bank  ·  ${formatDate(snapshot!.asOf)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFC7E4DA),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Refresh rates',
              onPressed: isLoading ? null : onRefresh,
              style: IconButton.styleFrom(
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white60,
              ),
              icon: isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatesColumnHeader extends StatelessWidget {
  const _RatesColumnHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Text(
            'CURRENCY',
            style: TextStyle(
              color: _muted,
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          'VALUE IN AFN',
          style: TextStyle(
            color: _muted,
            fontSize: 10,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _RatesLoadingView extends StatelessWidget {
  const _RatesLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        children: [_RatesColumnHeader(), SizedBox(height: 10), _ListSkeleton()],
      ),
    );
  }
}

class _RateLoadError extends StatelessWidget {
  const _RateLoadError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 44, 28, 100),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 54, color: _muted),
          const SizedBox(height: 18),
          const Text(
            'Internet connection required',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 9),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, height: 1.45),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            key: const Key('retry_rates'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _RateTile extends StatelessWidget {
  const _RateTile({required this.rate});

  final CurrencyRate rate;

  @override
  Widget build(BuildContext context) {
    final value = formatRate(rate.afnPerUnit * rate.displayUnit);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Semantics(
        label:
            '${formatUnit(rate.displayUnit)} ${rate.name} equals $value Afghanis',
        child: Row(
          children: [
            Container(
              width: 42,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE9F2EE),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(rate.flag, style: const TextStyle(fontSize: 21)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rate.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    rate.code,
                    style: const TextStyle(
                      color: _green,
                      fontSize: 11,
                      letterSpacing: .7,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 112,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            value,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.3,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'AFN',
                        style: TextStyle(
                          color: _green,
                          fontSize: 9,
                          letterSpacing: .5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${formatUnit(rate.displayUnit)} ${rate.code}',
                    style: const TextStyle(color: _muted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConverterPage extends StatefulWidget {
  const _ConverterPage({
    super.key,
    required this.snapshot,
    required this.errorMessage,
    required this.isLoading,
    required this.onRetry,
  });

  final RateSnapshot? snapshot;
  final String? errorMessage;
  final bool isLoading;
  final Future<void> Function() onRetry;

  @override
  State<_ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<_ConverterPage> {
  final _amountController = TextEditingController(text: '1');
  String _fromCode = 'USD';
  String _toCode = 'AFN';

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  List<CurrencyRate> get _currencies => [
    const CurrencyRate(
      code: 'AFN',
      name: 'Afghan Afghani',
      flag: '🇦🇫',
      afnPerUnit: 1,
    ),
    ...?widget.snapshot?.rates,
  ];

  CurrencyRate? _find(String code) {
    for (final currency in _currencies) {
      if (currency.code == code) return currency;
    }
    return null;
  }

  double get _result {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    final from = _find(_fromCode);
    final to = _find(_toCode);
    if (from == null || to == null || to.afnPerUnit == 0) return 0;
    return amount * from.afnPerUnit / to.afnPerUnit;
  }

  void _swap() {
    setState(() {
      final oldFrom = _fromCode;
      _fromCode = _toCode;
      _toCode = oldFrom;
    });
  }

  Future<void> _pickCurrency({required bool isFrom}) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CurrencyPicker(
        currencies: _currencies,
        selectedCode: isFrom ? _fromCode : _toCode,
        title: isFrom ? 'Send currency' : 'Receive currency',
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (isFrom) {
        _fromCode = selected;
      } else {
        _toCode = selected;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final from = _find(_fromCode);
    final to = _find(_toCode);

    final Widget body;
    if (!widget.isLoading && widget.snapshot == null) {
      body = _RateLoadError(
        key: const ValueKey('converter_error'),
        message:
            widget.errorMessage ??
            'Live rates are unavailable. Please connect to the internet and try again.',
        onRetry: widget.onRetry,
      );
    } else if (widget.snapshot == null || from == null || to == null) {
      body = const Center(
        key: ValueKey('converter_loading'),
        child: CircularProgressIndicator(color: _green),
      );
    } else {
      body = SingleChildScrollView(
        key: const ValueKey('converter_form'),
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 30),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'YOU SEND',
              style: TextStyle(
                color: _muted,
                fontSize: 10,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('amount_field'),
                    controller: _amountController,
                    onChanged: (_) => setState(() {}),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    cursorColor: _green,
                    style: const TextStyle(
                      color: _darkGreen,
                      fontSize: 31,
                      height: 1.05,
                      letterSpacing: -.6,
                      fontWeight: FontWeight.w800,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                    decoration: const InputDecoration(
                      hintText: '0',
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                _CurrencyButton(
                  key: const Key('currency_from'),
                  currency: from,
                  onTap: () => _pickCurrency(isFrom: true),
                ),
              ],
            ),
            SizedBox(
              height: 58,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Divider(color: Color(0xFFDCE5E1)),
                  Material(
                    color: _darkGreen,
                    shape: const CircleBorder(),
                    elevation: 0,
                    child: InkWell(
                      key: const Key('swap_currencies'),
                      onTap: _swap,
                      customBorder: const CircleBorder(),
                      child: const SizedBox.square(
                        dimension: 40,
                        child: Icon(
                          Icons.swap_vert_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              'YOU RECEIVE',
              style: TextStyle(
                color: _green,
                fontSize: 10,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatAmount(_result),
                      key: const Key('conversion_result'),
                      style: const TextStyle(
                        color: _green,
                        fontSize: 31,
                        height: 1.05,
                        letterSpacing: -.6,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                _CurrencyButton(
                  key: const Key('currency_to'),
                  currency: to,
                  onTap: () => _pickCurrency(isFrom: false),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(height: 1, color: Color(0xFFDCE5E1)),
            const SizedBox(height: 14),
            Row(
              children: [
                const SizedBox.square(
                  dimension: 7,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    '1 ${from.code} = ${formatRate(from.afnPerUnit / to.afnPerUnit)} ${to.code}',
                    style: const TextStyle(
                      color: _darkGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Text(
                  'LIVE RATE',
                  style: TextStyle(
                    color: _green,
                    fontSize: 9,
                    letterSpacing: .7,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const SizedBox(
              width: double.infinity,
              child: Text(
                'Reference conversion only. Cash-market prices may differ.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 11, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF083D34), Color(0xFF0B5B4C)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _ConverterHeader(
                snapshot: widget.snapshot,
                isLoading: widget.isLoading,
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: ColoredBox(
                    color: _ratesSurface,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      layoutBuilder: (currentChild, previousChildren) {
                        final children = <Widget>[...previousChildren];
                        if (currentChild != null) children.add(currentChild);
                        return Stack(
                          alignment: Alignment.topCenter,
                          children: children,
                        );
                      },
                      child: body,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConverterHeader extends StatelessWidget {
  const _ConverterHeader({required this.snapshot, required this.isLoading});

  final RateSnapshot? snapshot;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Convert',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                height: 1.08,
                letterSpacing: -.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Icon(
                  isLoading ? Icons.sync_rounded : Icons.verified_rounded,
                  size: 15,
                  color: const Color(0xFF84E1C4),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    isLoading
                        ? 'Loading live rates…'
                        : snapshot == null
                        ? 'Live rates unavailable'
                        : 'Da Afghanistan Bank  ·  ${formatDate(snapshot!.asOf)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFC7E4DA),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyButton extends StatelessWidget {
  const _CurrencyButton({
    super.key,
    required this.currency,
    required this.onTap,
  });

  final CurrencyRate currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE7F1ED),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 7, 7, 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(currency.flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 7),
              Text(
                currency.code,
                style: const TextStyle(
                  color: _darkGreen,
                  fontSize: 12,
                  letterSpacing: .4,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 17,
                color: _muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrencyPicker extends StatelessWidget {
  const _CurrencyPicker({
    required this.currencies,
    required this.selectedCode,
    required this.title,
  });

  final List<CurrencyRate> currencies;
  final String selectedCode;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .76,
      ),
      decoration: const BoxDecoration(
        color: _ratesSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 9),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD5DEDA),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 14, 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _darkGreen,
                          fontSize: 23,
                          letterSpacing: -.3,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Choose a currency',
                        style: TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: _muted,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE1E8E4)),
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              itemCount: currencies.length,
              separatorBuilder: (_, _) => const Divider(
                height: 1,
                indent: 66,
                color: Color(0xFFE4EAE7),
              ),
              itemBuilder: (context, index) {
                final currency = currencies[index];
                final selected = currency.code == selectedCode;
                return Material(
                  color: selected
                      ? const Color(0xFFE5F2ED)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                  child: InkWell(
                    key: Key('pick_${currency.code}'),
                    onTap: () => Navigator.pop(context, currency.code),
                    borderRadius: BorderRadius.circular(15),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white70
                                  : const Color(0xFFEAF2EE),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Text(
                              currency.flag,
                              style: const TextStyle(fontSize: 21),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currency.code,
                                  style: const TextStyle(
                                    color: _darkGreen,
                                    fontSize: 14,
                                    letterSpacing: .5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currency.name,
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (selected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: _green,
                              size: 21,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        7,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFE5EAE7),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 116,
                      height: 13,
                      color: const Color(0xFFE5EAE7),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      width: 38,
                      height: 10,
                      color: const Color(0xFFEDF0EE),
                    ),
                  ],
                ),
              ),
              Container(width: 70, height: 14, color: const Color(0xFFE5EAE7)),
            ],
          ),
        ),
      ),
    );
  }
}

String formatRate(double value) {
  if (value >= 100) return value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
  if (value >= 1) return value.toStringAsFixed(2);
  return value.toStringAsFixed(3);
}

String formatUnit(int value) => switch (value) {
  1000 => '1,000',
  100000 => '100,000',
  _ => value.toString(),
};

String formatAmount(double value) {
  final decimals = value.abs() >= 100
      ? 2
      : value.abs() >= 1
      ? 2
      : 3;
  final fixed = value.toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final digits = parts.first;
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return '${buffer.toString()}.${parts.last}';
}

String formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
