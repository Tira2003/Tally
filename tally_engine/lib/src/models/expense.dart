import 'money.dart';
import 'payer.dart';
import 'share.dart';
import 'expense_item.dart';
import '../validation/expense_validator.dart';
import '../validation/validation_result.dart';

/// An immutable record of one shared expense.
///
/// All lists ([payers], [shares], [items]) are wrapped with
/// [List.unmodifiable] to prevent external mutation.
class Expense {
  Expense({
    required this.id,
    required this.tripId,
    required this.title,
    required this.date,
    required this.total,
    required List<Payer> payers,
    required List<Share> shares,
    List<ExpenseItem> items = const [],
    required this.createdBy,
    required this.createdAt,
  })  : payers = List.unmodifiable(payers),
        shares = List.unmodifiable(shares),
        items = List.unmodifiable(items);

  /// Unique identifier.
  final String id;

  /// The trip this expense belongs to.
  final String tripId;

  /// Human-readable title (e.g. "Dinner at Galle Fort").
  final String title;

  /// When the expense occurred.
  final DateTime date;

  /// Total amount of the expense.  Must be > 0.
  final Money total;

  /// Who paid and how much.  Unmodifiable.
  final List<Payer> payers;

  /// Who consumed and how much.  Unmodifiable.
  final List<Share> shares;

  /// Individual line-items from the receipt.  May be empty.  Unmodifiable.
  final List<ExpenseItem> items;

  /// User ID of the person who recorded the expense.
  final String createdBy;

  /// When the expense record was created.
  final DateTime createdAt;

  // ── Validation ────────────────────────────────────────────────────────────

  /// Validates this expense against the two-ledger rules.
  ///
  /// Throws the first [ValidationException] encountered.
  void validate() => ExpenseValidator.validate(this);

  /// Validates this expense and returns ALL errors found.
  ///
  /// Never throws; returns an empty [ValidationResult] when the expense is
  /// valid.
  ValidationResult validateAll() => ExpenseValidator.validateAll(this);

  // ── copyWith ──────────────────────────────────────────────────────────────

  Expense copyWith({
    String? id,
    String? tripId,
    String? title,
    DateTime? date,
    Money? total,
    List<Payer>? payers,
    List<Share>? shares,
    List<ExpenseItem>? items,
    String? createdBy,
    DateTime? createdAt,
  }) =>
      Expense(
        id: id ?? this.id,
        tripId: tripId ?? this.tripId,
        title: title ?? this.title,
        date: date ?? this.date,
        total: total ?? this.total,
        payers: payers ?? this.payers,
        shares: shares ?? this.shares,
        items: items ?? this.items,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
      );

  // ── Equality ──────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Expense) return false;
    if (id != other.id ||
        tripId != other.tripId ||
        title != other.title ||
        date != other.date ||
        total != other.total ||
        createdBy != other.createdBy ||
        createdAt != other.createdAt) {
      return false;
    }
    if (!_listEquals(payers, other.payers)) return false;
    if (!_listEquals(shares, other.shares)) return false;
    if (!_listEquals(items, other.items)) return false;
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        tripId,
        title,
        date,
        total,
        Object.hashAll(payers),
        Object.hashAll(shares),
        Object.hashAll(items),
        createdBy,
        createdAt,
      );

  @override
  String toString() =>
      'Expense(id: $id, title: $title, total: $total, '
      'payers: $payers, shares: $shares)';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
