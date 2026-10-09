/// Tally Engine — immutable data models, two-ledger validation, and split
/// calculation.
///
/// This package contains no Flutter dependencies; it is pure Dart 3.
library tally_engine;

// Step 1 – models and validation
export 'src/exceptions/validation_exception.dart';
export 'src/models/money.dart';
export 'src/models/payer.dart';
export 'src/models/share.dart';
export 'src/models/expense_item.dart';
export 'src/models/expense.dart';
export 'src/validation/expense_validator.dart';
export 'src/validation/validation_result.dart';

// Step 2 – equal split calculation
export 'src/engine/rounding.dart';
export 'src/engine/equal_split.dart';
