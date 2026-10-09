import '../exceptions/validation_exception.dart';

/// Splits [totalMinorUnits] proportionally to [weights] using the
/// **Largest Remainder Method** with pure integer arithmetic.
///
/// ## Algorithm
/// 1. Validate inputs (non-empty list, all weights positive).
/// 2. For each slot i compute the floor of its exact share:
///    floor_i = totalMinorUnits * weights[i] ~/ sumOfWeights
/// 3. The remainder (fractional numerator) for slot i:
///    rem_i = totalMinorUnits * weights[i] - floor_i * sumOfWeights
///    Comparing rem numerators is exact - no floating-point needed.
/// 4. leftover = totalMinorUnits - sum(floor_i) extra units are given
///    one at a time to the highest-remainder slots. Ties: ascending index.
///
/// ## Invariant
/// The returned list always sums **exactly** to [totalMinorUnits].
///
/// ## Throws
/// [ValidationException]: weightsEmpty or invalidWeight.
List<int> allocateLargestRemainder(int totalMinorUnits, List<int> weights) {
  if (weights.isEmpty) {
    throw const ValidationException(
      code: ValidationErrorCode.weightsEmpty,
      message: 'Weights list must not be empty.',
    );
  }
  for (var i = 0; i < weights.length; i++) {
    if (weights[i] <= 0) {
      throw ValidationException(
        code: ValidationErrorCode.invalidWeight,
        message: 'All weights must be positive integers, '
            'but weights[${i}] = ${weights[i]}.',
      );
    }
  }
  final n = weights.length;
  var sumOfWeights = 0;
  for (final w in weights) {
    sumOfWeights += w;
  }
  final floors = List<int>.filled(n, 0);
  final remainders = List<int>.filled(n, 0);
  var allocatedSoFar = 0;
  for (var i = 0; i < n; i++) {
    final product = totalMinorUnits * weights[i];
    floors[i] = product ~/ sumOfWeights;
    remainders[i] = product % sumOfWeights;
    allocatedSoFar += floors[i];
  }
  final leftover = totalMinorUnits - allocatedSoFar;
  final indices = List<int>.generate(n, (i) => i)
    ..sort((a, b) {
      final cmp = remainders[b].compareTo(remainders[a]);
      return cmp != 0 ? cmp : a.compareTo(b);
    });
  for (var k = 0; k < leftover; k++) {
    floors[indices[k]] += 1;
  }
  return floors;
}
