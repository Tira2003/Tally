import '../exceptions/validation_exception.dart';
import '../models/expense.dart';
import '../models/money.dart';
import 'validation_result.dart';

/// Stateless validator that enforces the two-ledger rule and related
/// constraints on an [Expense].
///
/// The two ledgers (payers and shares) are each verified to sum to
/// [Expense.total] INDEPENDENTLY.  They are never compared person by person.
abstract final class ExpenseValidator {
  // ── Public API ─────────────────────────────────────────────────────────────

  /// Validates [expense] and throws the FIRST [ValidationException] found.
  ///
  /// Checks are applied in the order specified by the two-ledger rule.
  static void validate(Expense expense) {
    final err = _check(expense, stopOnFirst: true);
    if (err.isNotEmpty) throw err.first;
  }

  /// Validates [expense] and returns ALL [ValidationException]s found.
  ///
  /// Never throws; returns an empty [ValidationResult] when valid.
  static ValidationResult validateAll(Expense expense) {
    final errs = _check(expense, stopOnFirst: false);
    return ValidationResult(List.unmodifiable(errs));
  }

  // ── Core checker ──────────────────────────────────────────────────────────

  static List<ValidationException> _check(
    Expense expense, {
    required bool stopOnFirst,
  }) {
    final errors = <ValidationException>[];

    void add(ValidationException e) {
      errors.add(e);
    }

    bool done() => stopOnFirst && errors.isNotEmpty;

    // 1. total > 0
    if (!expense.total.isPositive) {
      add(ValidationException(
        code: ValidationErrorCode.totalNotPositive,
        message:
            'Expense total must be greater than zero, '
            'got ${expense.total.minorUnits} ${expense.total.currency}.',
      ));
    }
    if (done()) return errors;

    // 2. payers not empty
    if (expense.payers.isEmpty) {
      add(ValidationException(
        code: ValidationErrorCode.payersEmpty,
        message: 'Payers list must not be empty.',
      ));
    }
    if (done()) return errors;

    // 3. shares not empty
    if (expense.shares.isEmpty) {
      add(ValidationException(
        code: ValidationErrorCode.sharesEmpty,
        message: 'Shares list must not be empty.',
      ));
    }
    if (done()) return errors;

    // 4a. every payer amount > 0
    for (final p in expense.payers) {
      if (!p.amount.isPositive) {
        add(ValidationException(
          code: ValidationErrorCode.payerAmountNotPositive,
          message:
              'Payer "${p.userId}" has a non-positive amount: '
              '${p.amount.minorUnits} ${p.amount.currency}.',
        ));
        if (done()) return errors;
      }
    }

    // 4b. every share amount >= 0
    for (final s in expense.shares) {
      if (s.amount.isNegative) {
        add(ValidationException(
          code: ValidationErrorCode.shareAmountNegative,
          message:
              'Share for "${s.userId}" has a negative amount: '
              '${s.amount.minorUnits} ${s.amount.currency}.',
        ));
        if (done()) return errors;
      }
    }

    // 5. no duplicate userId within payers
    {
      final seen = <String>{};
      for (final p in expense.payers) {
        if (!seen.add(p.userId)) {
          add(ValidationException(
            code: ValidationErrorCode.duplicatePayerUserId,
            message:
                'Duplicate payer userId "${p.userId}".',
          ));
          if (done()) return errors;
        }
      }
    }

    // 5b. no duplicate userId within shares
    {
      final seen = <String>{};
      for (final s in expense.shares) {
        if (!seen.add(s.userId)) {
          add(ValidationException(
            code: ValidationErrorCode.duplicateShareUserId,
            message:
                'Duplicate share userId "${s.userId}".',
          ));
          if (done()) return errors;
        }
      }
    }

    // 6. all amounts use the same currency as total
    final expectedCurrency = expense.total.currency;
    for (final p in expense.payers) {
      if (p.amount.currency != expectedCurrency) {
        add(ValidationException(
          code: ValidationErrorCode.currencyMismatch,
          message:
              'Payer "${p.userId}" currency "${p.amount.currency}" does not '
              'match expense currency "$expectedCurrency".',
        ));
        if (done()) return errors;
      }
    }
    for (final s in expense.shares) {
      if (s.amount.currency != expectedCurrency) {
        add(ValidationException(
          code: ValidationErrorCode.currencyMismatch,
          message:
              'Share "${s.userId}" currency "${s.amount.currency}" does not '
              'match expense currency "$expectedCurrency".',
        ));
        if (done()) return errors;
      }
    }

    // 7. sum(payers) == total
    final payerSum = Money.sum(
      expense.payers.map((p) => p.amount),
      currency: expectedCurrency,
    );
    if (payerSum != expense.total) {
      add(ValidationException(
        code: ValidationErrorCode.payersDoNotSumToTotal,
        message:
            'Payers sum ${payerSum.minorUnits} $expectedCurrency does not '
            'equal total ${expense.total.minorUnits} $expectedCurrency.',
      ));
      if (done()) return errors;
    }

    // 8. sum(shares) == total
    final shareSum = Money.sum(
      expense.shares.map((s) => s.amount),
      currency: expectedCurrency,
    );
    if (shareSum != expense.total) {
      add(ValidationException(
        code: ValidationErrorCode.sharesDoNotSumToTotal,
        message:
            'Shares sum ${shareSum.minorUnits} $expectedCurrency does not '
            'equal total ${expense.total.minorUnits} $expectedCurrency.',
      ));
      if (done()) return errors;
    }

    // 9. item checks (only when items is non-empty)
    if (expense.items.isNotEmpty) {
      for (final item in expense.items) {
        if (!item.price.isPositive) {
          add(ValidationException(
            code: ValidationErrorCode.itemPriceNotPositive,
            message:
                'Item "${item.name}" has a non-positive price: '
                '${item.price.minorUnits} ${item.price.currency}.',
          ));
          if (done()) return errors;
        }
      }

      final itemSum = Money.sum(
        expense.items.map((i) => i.price),
        currency: expectedCurrency,
      );
      if (itemSum != expense.total) {
        add(ValidationException(
          code: ValidationErrorCode.itemsDoNotSumToTotal,
          message:
              'Item prices sum ${itemSum.minorUnits} $expectedCurrency does '
              'not equal total ${expense.total.minorUnits} $expectedCurrency.',
        ));
      }
    }

    return errors;
  }
}
