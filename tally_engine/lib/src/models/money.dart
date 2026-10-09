import '../exceptions/validation_exception.dart';

/// An immutable monetary value stored as integer minor units.
///
/// Example: 150 LKR = `Money(minorUnits: 15000, currency: 'LKR')`.
/// Never use [double] for money.
class Money {
  /// Creates a monetary value.
  const Money({
    required this.minorUnits,
    this.currency = 'LKR',
  });

  /// Amount expressed in the smallest indivisible unit of [currency].
  /// For LKR (Sri Lankan Rupee) 1 rupee = 100 minor units.
  final int minorUnits;

  /// ISO 4217 currency code (default: `'LKR'`).
  final String currency;

  // ── Predicates ────────────────────────────────────────────────────────────

  bool get isZero => minorUnits == 0;
  bool get isNegative => minorUnits < 0;
  bool get isPositive => minorUnits > 0;

  // ── Arithmetic ────────────────────────────────────────────────────────────

  /// Returns the sum of this and [other].
  ///
  /// Throws [ValidationException] with code [ValidationErrorCode.currencyMismatch]
  /// if the currencies differ.
  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money(minorUnits: minorUnits + other.minorUnits, currency: currency);
  }

  /// Returns the difference of this and [other].
  ///
  /// Throws [ValidationException] with code [ValidationErrorCode.currencyMismatch]
  /// if the currencies differ.
  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money(minorUnits: minorUnits - other.minorUnits, currency: currency);
  }

  void _assertSameCurrency(Money other) {
    if (currency != other.currency) {
      throw ValidationException(
        code: ValidationErrorCode.currencyMismatch,
        message:
            'Cannot operate on different currencies: $currency vs ${other.currency}.',
      );
    }
  }

  // ── Static helpers ────────────────────────────────────────────────────────

  /// Returns the sum of all [amounts], or zero in [currency] for an empty list.
  ///
  /// [currency] is used only when [amounts] is empty.  When amounts is
  /// non-empty, the currency is inferred from the first element (and all
  /// subsequent elements must share that currency, otherwise + will throw).
  static Money sum(Iterable<Money> amounts, {String currency = 'LKR'}) {
    Money result = Money(minorUnits: 0, currency: currency);
    for (final m in amounts) {
      result = result + m;
    }
    return result;
  }

  // ── copyWith ──────────────────────────────────────────────────────────────

  Money copyWith({int? minorUnits, String? currency}) => Money(
        minorUnits: minorUnits ?? this.minorUnits,
        currency: currency ?? this.currency,
      );

  // ── Equality ──────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money &&
          other.minorUnits == minorUnits &&
          other.currency == currency;

  @override
  int get hashCode => Object.hash(minorUnits, currency);

  @override
  String toString() => 'Money($minorUnits $currency)';
}
