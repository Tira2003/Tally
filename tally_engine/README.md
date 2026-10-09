# tally_engine

Pure-Dart business logic for the **Tally** trip expense-splitting app.

> **Step 1 scope**: immutable data models + two-ledger validation only.
> UI, database, split calculation, settlements, and currency conversion
> are out of scope for this package version.

---

## Package layout

```
tally_engine/
├── lib/
│   ├── tally_engine.dart              # public barrel export
│   └── src/
│       ├── exceptions/
│       │   └── validation_exception.dart   # ValidationException + ValidationErrorCode
│       ├── models/
│       │   ├── money.dart             # Money (integer minor units)
│       │   ├── payer.dart             # Payer
│       │   ├── share.dart             # Share
│       │   ├── expense_item.dart      # ExpenseItem
│       │   └── expense.dart           # Expense
│       └── validation/
│           ├── expense_validator.dart # stateless two-ledger validator
│           └── validation_result.dart # ValidationResult (all-errors variant)
└── test/
    └── expense_validation_test.dart   # 43 tests across 11 groups
```

---

## Two-ledger rule

Payers and Shares are **independent** ledgers.  Each must sum to the expense
total on its own:

```
sum(payers.amount) == total
sum(shares.amount) == total
```

A person may appear in **payers only**, **shares only**, or **both**.
The two ledgers are never compared person-by-person.

---

## Running the tests

```bash
cd tally_engine
dart pub get
dart test
```

For verbose output:

```bash
dart test --reporter expanded
```

Expected result: **43 tests, 0 failures**.

---

## Key design decisions

| Decision | Rationale |
|---|---|
| Money stored as `int` minor units | Eliminates floating-point rounding errors |
| `List.unmodifiable` in Expense constructor | Prevents external mutation of shared lists |
| `validate()` throws first error; `validateAll()` collects all | `validate()` is fast-path for persistence; `validateAll()` drives UI hints |
| `ValidationErrorCode` enum | Allows callers to `switch` without string-matching |
| No Flutter imports | Keeps the engine testable with `dart test` alone; compatible with any Dart target |
| Default currency `"LKR"` | Matches the app's primary market |

---

## Assumptions

1. **Zero-amount shares are allowed** (a person might be listed but consuming
   nothing, e.g. a promotional freebie).  Zero-amount *payers* are rejected
   because a payer must have contributed something.
2. `Money.sum` with an empty iterable returns `Money(minorUnits: 0, currency: currency)`,
   using the explicit `currency` parameter (default `'LKR'`).
3. When items are present, item prices must sum **exactly** to `total`.
   Adjustment/rounding logic is deferred to a later step.
4. `validate()` checks rules in the exact order stated in the spec and throws
   on the first failure.  `validateAll()` collects every error it can find in
   a single pass.
