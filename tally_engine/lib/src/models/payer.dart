import 'money.dart';

/// Records which user put money in and how much they paid.
class Payer {
  const Payer({
    required this.userId,
    required this.amount,
  });

  /// Identifier of the user who paid.
  final String userId;

  /// Amount the user contributed (must be > 0 when validated).
  final Money amount;

  // ── copyWith ──────────────────────────────────────────────────────────────

  Payer copyWith({String? userId, Money? amount}) => Payer(
        userId: userId ?? this.userId,
        amount: amount ?? this.amount,
      );

  // ── Equality ──────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Payer &&
          other.userId == userId &&
          other.amount == amount;

  @override
  int get hashCode => Object.hash(userId, amount);

  @override
  String toString() => 'Payer(userId: $userId, amount: $amount)';
}
