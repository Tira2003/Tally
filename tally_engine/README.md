# tally_engine

Pure-Dart business logic for the **Tally** trip expense-splitting app.

> **Step 2 scope**: equal split calculation with largest-remainder rounding.
> Builds on Step 1 (models + two-ledger validation) with no changes to existing
> model behaviour.
> Other split modes, settlements, currency conversion, UI, and database code
> are out of scope.

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
│       ├── validation/
│       │   ├── expense_validator.dart # stateless two-ledger validator
│       │   └── validation_result.dart # ValidationResult (all-errors variant)
│       └── engine/
│           ├── rounding.dart          # allocateLargestRemainder helper
│           └── equal_split.dart       # splitEqually function
└── test/
    ├── expense_validation_test.dart   # 43 tests – Step 1
    └── equal_split_test.dart          # 37 tests – Step 2
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

Expected result: **80 tests, 0 failures** (43 Step 1 + 37 Step 2).

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
| `allocateLargestRemainder` uses integer cross-multiplication for remainders | Avoids `double` entirely; deterministic on all Dart platforms |
| `splitEqually` sorts participant ids before calling the helper | Same input set always produces the same output regardless of call-site order |
| Extra remainder cent(s) go to lexicographically earliest id(s) | Deterministic, auditable, and easy to explain to users |

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
5. **Step 2**: `splitEqually` with `total < n` produces some zero-amount shares.
   This is valid per the Step 1 model (`shareAmountNegative` rejects negatives,
   but zero is permitted).
6. **Step 2**: Dart's native `int` is 64-bit on the VM/AOT targets used by
   Flutter and CLI apps.  Monetary totals near 2^53 are handled correctly
   without overflow.

---

## Equal split

```dart
import 'package:tally_engine/tally_engine.dart';

void main() {
  // 100 LKR shared equally among three people.
  final total = Money(minorUnits: 10000, currency: 'LKR'); // 100.00 LKR

  final shares = splitEqually(total, ['carol', 'alice', 'bob']);
  // Returns shares in ascending userId order (alice, bob, carol).
  // 10000 / 3 = 3333.33...
  // Largest-remainder distributes the extra 1 unit to 'alice' (first sorted).
  // Result: alice=3334, bob=3333, carol=3333  (sum=10000 exactly)

  for (final s in shares) {
    print('${s.userId}: ${s.amount.minorUnits} ${s.amount.currency}');
  }
  // alice: 3334 LKR
  // bob:   3333 LKR
  // carol: 3333 LKR

  // Plug directly into an Expense:
  final expense = Expense(
    id: 'exp-1',
    tripId: 'trip-1',
    title: 'Dinner',
    date: DateTime.now(),
    total: total,
    payers: [Payer(userId: 'alice', amount: total)],
    shares: shares, // from splitEqually
    createdBy: 'alice',
    createdAt: DateTime.now(),
  );

  expense.validate(); // passes: sum(shares) == total guaranteed by splitEqually
}
```

### How rounding works

`splitEqually` delegates to `allocateLargestRemainder`, which uses the
**Largest Remainder Method** with pure integer arithmetic (no `double` anywhere):

1. Compute the floor of each exact share: `total * weight ~/ sumOfWeights`.
2. Compute each slot's remainder numerator: `total * weight % sumOfWeights`.
3. Distribute the leftover units one-by-one to slots in descending remainder
   order; ties broken by ascending index (which maps to ascending sorted userId).

This guarantees:
- The returned shares always sum **exactly** to `total`.
- Any two shares differ by **at most 1** minor unit.
- The result is **deterministic** for the same set of participant ids regardless
  of the order they were supplied.
