import 'package:budget_app/core/money/money.dart';

/// Converts [Money] to/from display text. The one money display boundary.
///
/// Every other layer (controllers, widgets, repositories) passes [Money]; only
/// this class produces or consumes user-facing currency strings. Pure Dart —
/// no Flutter, no Drift, no `intl`.
class CurrencyFormatter {
  const CurrencyFormatter._();

  /// Formats [amount] for display.
  ///
  /// `Money(1234560)` → `"$1,234.56"`; `Money(-50000)` → `"-$50.00"`;
  /// `Money.zero()` → `"$0.00"`.
  ///
  /// [symbol] is the currency symbol; [decimalDigits] the fraction digits to
  /// render. Defaults are US-dollar style; a later task can feed a
  /// `Budget.currencyCode` / `Budget.currencyDecimalDigits` in.
  ///
  /// Rounding is half-up on the dropped milliunit digits.
  static String format(
    Money amount, {
    String symbol = r'$',
    int decimalDigits = 2,
  }) {
    assert(
      decimalDigits >= 0 && decimalDigits <= 3,
      'decimalDigits must be in 0..3 (Money has 3-digit milliunit precision)',
    );
    final negative = amount.milliunits < 0;
    final absMilli = negative ? -amount.milliunits : amount.milliunits;

    // Scale the integer milliunits down to `decimalDigits` precision with
    // half-up rounding. `decimalDigits == 2` divides by 10; `0` divides by
    // 1000; `3` divides by 1.
    final divisor = _pow10(3 - decimalDigits);
    final scaled =
        divisor == 1 ? absMilli : (absMilli + divisor ~/ 2) ~/ divisor;

    final unitScale = _pow10(decimalDigits);
    final wholePart = scaled ~/ unitScale;
    final fractionPart = scaled % unitScale;

    final buffer = StringBuffer();
    if (negative) buffer.write('-');
    buffer
      ..write(symbol)
      ..write(_groupThousands(wholePart));
    if (decimalDigits > 0) {
      buffer
        ..write('.')
        ..write(fractionPart.toString().padLeft(decimalDigits, '0'));
    }
    return buffer.toString();
  }

  /// Parses user input into [Money]; returns null when [input] is not a valid
  /// number.
  ///
  /// Accepts an optional leading sign, the currency [symbol], grouping
  /// commas, internal whitespace, and surrounding whitespace — e.g.
  /// `"1,234.56"`, `"-50"`, `"$12"`, `" 7.5 "`. An empty or blank string
  /// returns null. More fraction digits than [decimalDigits] returns null.
  ///
  /// Round-trips with [format] for values expressible in [decimalDigits].
  static Money? tryParse(
    String input, {
    String symbol = r'$',
    int decimalDigits = 2,
  }) {
    assert(
      decimalDigits >= 0 && decimalDigits <= 3,
      'decimalDigits must be in 0..3 (Money has 3-digit milliunit precision)',
    );
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // Pull off an optional leading sign before stripping the symbol so that
    // forms like "-$50" and "$-50" both parse.
    var body = trimmed;
    var negative = false;
    if (body.startsWith('-') || body.startsWith('+')) {
      negative = body.startsWith('-');
      body = body.substring(1).trimLeft();
    }
    if (body.startsWith(symbol)) {
      body = body.substring(symbol.length).trimLeft();
    }
    if (body.startsWith('-') || body.startsWith('+')) {
      // A second sign (e.g. "$-50") flips negativity once more.
      if (body.startsWith('-')) negative = !negative;
      body = body.substring(1).trimLeft();
    }

    // Strip grouping commas and any remaining internal whitespace.
    body = body.replaceAll(',', '').replaceAll(' ', '');
    if (body.isEmpty) return null;

    final dotIndex = body.indexOf('.');
    final String wholeText;
    final String fractionText;
    if (dotIndex < 0) {
      wholeText = body;
      fractionText = '';
    } else {
      if (body.indexOf('.', dotIndex + 1) >= 0) return null;
      wholeText = body.substring(0, dotIndex);
      fractionText = body.substring(dotIndex + 1);
    }
    if (wholeText.isEmpty && fractionText.isEmpty) return null;
    if (!_isDigits(wholeText) || !_isDigits(fractionText)) return null;
    if (fractionText.length > decimalDigits) return null;

    final whole = wholeText.isEmpty ? 0 : int.parse(wholeText);
    final paddedFraction = fractionText.padRight(decimalDigits, '0');
    final fraction = paddedFraction.isEmpty ? 0 : int.parse(paddedFraction);

    // milliunits = whole * 1000 + fraction * (1000 / 10^decimalDigits).
    final fractionScale = _pow10(3 - decimalDigits);
    final magnitude = whole * 1000 + fraction * fractionScale;
    return Money(negative ? -magnitude : magnitude);
  }

  static int _pow10(int exponent) {
    var result = 1;
    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }

  static bool _isDigits(String s) {
    for (var i = 0; i < s.length; i++) {
      final c = s.codeUnitAt(i);
      if (c < 0x30 || c > 0x39) return false;
    }
    return true;
  }

  static String _groupThousands(int value) {
    final digits = value.toString();
    if (digits.length <= 3) return digits;
    final buffer = StringBuffer();
    final firstGroup = digits.length % 3;
    if (firstGroup != 0) {
      buffer.write(digits.substring(0, firstGroup));
      if (digits.length > firstGroup) buffer.write(',');
    }
    for (var i = firstGroup; i < digits.length; i += 3) {
      buffer.write(digits.substring(i, i + 3));
      if (i + 3 < digits.length) buffer.write(',');
    }
    return buffer.toString();
  }
}
