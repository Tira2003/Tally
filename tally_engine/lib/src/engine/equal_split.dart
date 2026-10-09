import '../exceptions/validation_exception.dart';
import '../models/money.dart';
import '../models/share.dart';
import 'rounding.dart';

/// Splits [total] equally among [participantUserIds] and returns one [Share]
/// per participant in ascending userId order.
///
/// Uses [allocateLargestRemainder] with equal weights. All shares differ
/// by at most 1 minor unit and always sum exactly to [total].
/// Participants with zero shares are valid when total < participant count.
///
/// Throws [ValidationException] when total <= 0, list is empty,
/// any userId is blank, or any userId is duplicated.
List<Share> splitEqually(Money total, List<String> participantUserIds) {
  if (!total.isPositive) {
    throw ValidationException(
      code: ValidationErrorCode.totalNotPositiveForSplit,
      message: 'splitEqually requires a positive total, '
          'got ${total.minorUnits} ${total.currency}.',
    );
  }
  if (participantUserIds.isEmpty) {
    throw const ValidationException(
      code: ValidationErrorCode.participantsEmpty,
      message: 'splitEqually requires at least one participant.',
    );
  }
  for (final id in participantUserIds) {
    if (id.trim().isEmpty) {
      throw ValidationException(
        code: ValidationErrorCode.blankParticipantUserId,
        message: 'All participant userIds must be non-blank, '
            'but found: "${id}".',
      );
    }
  }
  final seen = <String>{};
  for (final id in participantUserIds) {
    if (!seen.add(id)) {
      throw ValidationException(
        code: ValidationErrorCode.duplicateParticipantUserId,
        message: 'Duplicate participant userId: "${id}".',
      );
    }
  }
  final sorted = [...participantUserIds]..sort();
  final n = sorted.length;
  final amounts = allocateLargestRemainder(
    total.minorUnits,
    List<int>.filled(n, 1),
  );
  return [
    for (var i = 0; i < n; i++)
      Share(
        userId: sorted[i],
        amount: Money(minorUnits: amounts[i], currency: total.currency),
      ),
  ];
}
