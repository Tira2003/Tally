import 'money.dart';

/// Records which user consumed from an expense and how much.
class Share {
  const Share({
    required this.userId,
    required this.amount,
  });

  /// Identifier of the user who consumed.
  final String userId;

  /// Amount allocated to this user (must be >= 0 when validated).
  final Money amount;

  // ── copyWith ──────────────────────────────────────────────────────────────

  Share copyWith({String? userId, Money? amount}) => Share(
        userId: userId ?? this.userId,
        amount: amount ?? this.amount,
      );

  // ── Equality ──────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Share &&
          other.userId == userId &&
          other.amount == amount;

  @override
  int get hashCode => Object.hash(userId, amount);

  @override
  String toString() => 'Share(userId: $userId, amount: $amount)';
}
