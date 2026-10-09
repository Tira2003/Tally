import 'money.dart';

/// One line-item on a receipt.
///
/// For Step 1, [ExpenseItem] is a pure data holder; split calculation
/// (distributing [price] among [consumerUserIds]) is deferred to a later step.
class ExpenseItem {
  const ExpenseItem({
    required this.id,
    required this.name,
    required this.price,
    required this.consumerUserIds,
  });

  /// Unique identifier for this line item.
  final String id;

  /// Human-readable name (e.g. "Steak", "Wine").
  final String name;

  /// Price of this item in minor units.  Must be > 0 when validated.
  final Money price;

  /// User IDs of everyone who consumed this item.
  final List<String> consumerUserIds;

  // ── copyWith ──────────────────────────────────────────────────────────────

  ExpenseItem copyWith({
    String? id,
    String? name,
    Money? price,
    List<String>? consumerUserIds,
  }) =>
      ExpenseItem(
        id: id ?? this.id,
        name: name ?? this.name,
        price: price ?? this.price,
        consumerUserIds: consumerUserIds ?? this.consumerUserIds,
      );

  // ── Equality ──────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ExpenseItem) return false;
    if (id != other.id || name != other.name || price != other.price) {
      return false;
    }
    if (consumerUserIds.length != other.consumerUserIds.length) return false;
    for (var i = 0; i < consumerUserIds.length; i++) {
      if (consumerUserIds[i] != other.consumerUserIds[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(id, name, price, Object.hashAll(consumerUserIds));

  @override
  String toString() =>
      'ExpenseItem(id: $id, name: $name, price: $price, consumers: $consumerUserIds)';
}
