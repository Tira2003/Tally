/// Typed error codes for every constraint the engine enforces.
enum ValidationErrorCode {
  /// The expense total is not positive.
  totalNotPositive,

  /// The payers list is empty.
  payersEmpty,

  /// The shares list is empty.
  sharesEmpty,

  /// At least one payer amount is not positive.
  payerAmountNotPositive,

  /// At least one share amount is negative.
  shareAmountNegative,

  /// A userId appears more than once in the payers list.
  duplicatePayerUserId,

  /// A userId appears more than once in the shares list.
  duplicateShareUserId,

  /// An amount currency differs from the expense total currency.
  currencyMismatch,

  /// The sum of payer amounts does not equal the expense total.
  payersDoNotSumToTotal,

  /// The sum of share amounts does not equal the expense total.
  sharesDoNotSumToTotal,

  /// At least one item price is not positive.
  itemPriceNotPositive,

  /// The sum of item prices does not equal the expense total.
  itemsDoNotSumToTotal,

  // ── Equal-split / rounding error codes ──────────────────────────────────

  /// The participant list passed to a split function is empty.
  participantsEmpty,

  /// A participant userId is blank (empty or only whitespace).
  blankParticipantUserId,

  /// A userId appears more than once in the participants list.
  duplicateParticipantUserId,

  /// The total passed to a split function is not positive.
  totalNotPositiveForSplit,

  /// A weight passed to [allocateLargestRemainder] is not positive.
  invalidWeight,

  /// The weights list passed to [allocateLargestRemainder] is empty.
  weightsEmpty,
}

/// Thrown when an [Expense] fails validation.
///
/// Each instance carries a human-readable [message] and a
/// machine-readable [code] that callers can switch on.
class ValidationException implements Exception {
  const ValidationException({
    required this.code,
    required this.message,
  });

  /// Machine-readable error code.
  final ValidationErrorCode code;

  /// Human-readable description of the failure.
  final String message;

  @override
  String toString() => 'ValidationException(${code.name}): $message';
}
