import '../exceptions/validation_exception.dart';

/// Holds all [ValidationException]s found by [ExpenseValidator.validateAll].
///
/// An empty [errors] list means the expense is valid.
class ValidationResult {
  const ValidationResult(this.errors);

  /// All errors found.  Empty when valid.
  final List<ValidationException> errors;

  /// `true` when no errors were found.
  bool get isValid => errors.isEmpty;

  @override
  String toString() => 'ValidationResult(isValid: $isValid, errors: $errors)';
}
