import 'dart:math';
import 'package:test/test.dart';
import 'package:tally_engine/tally_engine.dart';

// Helpers
Money lkr(int minorUnits) => Money(minorUnits: minorUnits, currency: 'LKR');
Money usd(int minorUnits) => Money(minorUnits: minorUnits, currency: 'USD');
final _now = DateTime(2024, 6, 1);

Expense _expenseWithEqualShares({
  required Money total,
  required List<String> participants,
  String payerUserId = 'payer-1',
}) {
  final shares = splitEqually(total, participants);
  return Expense(
    id: 'exp-split',
    tripId: 'trip-1',
    title: 'Split Expense',
    date: _now,
    total: total,
    payers: [Payer(userId: payerUserId, amount: total)],
    shares: shares,
    createdBy: payerUserId,
    createdAt: _now,
  );
}

void main() {
  // Test 1: 9000 among 3 -> 3000 each
  group('Test 1 - 9000 among 3 -> 3000 each', () {
    test('each share is exactly 3000', () {
      final shares = splitEqually(lkr(9000), ['alice', 'bob', 'carol']);
      final amounts = shares.map((s) => s.amount.minorUnits).toList();
      expect(amounts, [3000, 3000, 3000]);
    });
  });

  // Test 2: 10000 among 3 -> 3334, 3333, 3333
  group('Test 2 - 10000 among 3: extra unit to first sorted id', () {
    test('alice=3334, bob=3333, carol=3333, sum=10000', () {
      final shares = splitEqually(lkr(10000), ['carol', 'alice', 'bob']);
      expect(shares[0].userId, 'alice');
      expect(shares[0].amount.minorUnits, 3334);
      expect(shares[1].amount.minorUnits, 3333);
      expect(shares[2].amount.minorUnits, 3333);
      expect(shares.fold<int>(0, (s, sh) => s + sh.amount.minorUnits), 10000);
    });
  });

  // Test 3: 10000 among 4 -> 2500 each
  group('Test 3 - 10000 among 4 -> 2500 each', () {
    test('each share is exactly 2500', () {
      final shares = splitEqually(lkr(10000), ['a', 'b', 'c', 'd']);
      expect(shares.map((s) => s.amount.minorUnits).toList(), [2500, 2500, 2500, 2500]);
    });
  });

  // Test 4: 1 among 3 -> 1, 0, 0
  group('Test 4 - 1 among 3 -> 1, 0, 0', () {
    test('first sorted id gets 1, others get 0, sum=1', () {
      final shares = splitEqually(lkr(1), ['c', 'a', 'b']);
      expect(shares[0].userId, 'a');
      expect(shares[0].amount.minorUnits, 1);
      expect(shares[1].amount.minorUnits, 0);
      expect(shares[2].amount.minorUnits, 0);
      expect(shares.fold<int>(0, (s, sh) => s + sh.amount.minorUnits), 1);
    });
  });

  // Test 5: 2 among 3 -> 1, 1, 0
  group('Test 5 - 2 among 3 -> 1, 1, 0', () {
    test('first two sorted ids get 1, third gets 0, sum=2', () {
      final shares = splitEqually(lkr(2), ['c', 'a', 'b']);
      expect(shares[0].amount.minorUnits, 1);
      expect(shares[1].amount.minorUnits, 1);
      expect(shares[2].amount.minorUnits, 0);
      expect(shares.fold<int>(0, (s, sh) => s + sh.amount.minorUnits), 2);
    });
  });

  // Test 6: single participant gets full total
  group('Test 6 - single participant gets full total', () {
    test('one share equals total', () {
      final shares = splitEqually(lkr(9999), ['solo']);
      expect(shares.length, 1);
      expect(shares[0].userId, 'solo');
      expect(shares[0].amount.minorUnits, 9999);
    });
  });

  // Test 7: order independence
  group('Test 7 - order independence', () {
    test('[c,a,b] and [a,b,c] give identical results', () {
      final r1 = splitEqually(lkr(10000), ['c', 'a', 'b']);
      final r2 = splitEqually(lkr(10000), ['a', 'b', 'c']);
      for (var i = 0; i < r1.length; i++) {
        expect(r1[i].userId, r2[i].userId);
        expect(r1[i].amount, r2[i].amount);
      }
    });
    test('multiple permutations give same result', () {
      final ref = splitEqually(lkr(13337), ['delta', 'alpha', 'gamma', 'beta', 'epsilon']);
      final perms = [
        ['alpha', 'beta', 'gamma', 'delta', 'epsilon'],
        ['epsilon', 'delta', 'gamma', 'beta', 'alpha'],
        ['gamma', 'alpha', 'epsilon', 'delta', 'beta'],
      ];
      for (final perm in perms) {
        final result = splitEqually(lkr(13337), perm);
        for (var i = 0; i < ref.length; i++) {
          expect(result[i].userId, ref[i].userId);
          expect(result[i].amount, ref[i].amount);
        }
      }
    });
  });

  // Test 8: determinism over 100 calls
  group('Test 8 - determinism: 100 calls give identical results', () {
    test('all 100 results are equal', () {
      final first = splitEqually(lkr(10007), ['x', 'y', 'z']);
      for (var i = 0; i < 99; i++) {
        final result = splitEqually(lkr(10007), ['x', 'y', 'z']);
        expect(result, equals(first), reason: 'Mismatch on call ${i + 2}');
      }
    });
  });

  // Test 9: max difference is at most 1
  group('Test 9 - max difference between any two shares is <= 1', () {
    final cases = [
      (total: 10000, n: 3),
      (total: 10001, n: 4),
      (total: 7, n: 4),
      (total: 1, n: 5),
    ];
    for (final c in cases) {
      test('total=${c.total} n=${c.n}', () {
        final ids = List<String>.generate(c.n, (i) => 'u${i}');
        final shares = splitEqually(lkr(c.total), ids);
        final amounts = shares.map((s) => s.amount.minorUnits).toList();
        final maxAmt = amounts.reduce((a, b) => a > b ? a : b);
        final minAmt = amounts.reduce((a, b) => a < b ? a : b);
        expect(maxAmt - minAmt, lessThanOrEqualTo(1));
      });
    }
  });

  // Test 10: property test 1000 random combos
  group('Test 10 - property: 1000 random combos always sum to total', () {
    test('sum invariant and max-diff <= 1 for all combos', () {
      final rng = Random(42);
      for (var iter = 0; iter < 1000; iter++) {
        final total = rng.nextInt(1000000) + 1;
        final n = rng.nextInt(50) + 1;
        final ids = List<String>.generate(n, (i) => 'u${i}');
        final shares = splitEqually(lkr(total), ids);
        final sum = shares.fold<int>(0, (s, sh) => s + sh.amount.minorUnits);
        expect(sum, total,
            reason: 'iter=${iter} total=${total} n=${n}: sum=${sum}');
        if (n > 1) {
          final amounts = shares.map((s) => s.amount.minorUnits).toList();
          final maxAmt = amounts.reduce((a, b) => a > b ? a : b);
          final minAmt = amounts.reduce((a, b) => a < b ? a : b);
          expect(maxAmt - minAmt, lessThanOrEqualTo(1));
        }
      }
    });
  });

  // Test 11: large values near int safe range
  group('Test 11 - large values near int safe range', () {
    test('no overflow, sum is exact', () {
      const bigTotal = 9007199254740992; // 2^53
      final shares = splitEqually(
        Money(minorUnits: bigTotal, currency: 'LKR'),
        ['alice', 'bob', 'carol'],
      );
      final sum = shares.fold<int>(0, (s, sh) => s + sh.amount.minorUnits);
      expect(sum, bigTotal);
    });
  });

  // Test 12: currency preserved
  group('Test 12 - currency propagation', () {
    test('LKR total produces LKR shares', () {
      for (final s in splitEqually(lkr(9000), ['a', 'b', 'c'])) {
        expect(s.amount.currency, 'LKR');
      }
    });
    test('USD total produces USD shares', () {
      for (final s in splitEqually(usd(10000), ['a', 'b'])) {
        expect(s.amount.currency, 'USD');
      }
    });
  });

  // Test 13: validation errors
  group('Test 13 - validation errors from splitEqually', () {
    test('zero total -> totalNotPositiveForSplit', () {
      expect(
        () => splitEqually(lkr(0), ['alice']),
        throwsA(isA<ValidationException>().having(
          (e) => e.code, 'code', ValidationErrorCode.totalNotPositiveForSplit)),
      );
    });
    test('negative total -> totalNotPositiveForSplit', () {
      expect(
        () => splitEqually(lkr(-100), ['alice']),
        throwsA(isA<ValidationException>().having(
          (e) => e.code, 'code', ValidationErrorCode.totalNotPositiveForSplit)),
      );
    });
    test('empty participant list -> participantsEmpty', () {
      expect(
        () => splitEqually(lkr(1000), []),
        throwsA(isA<ValidationException>().having(
          (e) => e.code, 'code', ValidationErrorCode.participantsEmpty)),
      );
    });
    test('duplicate userId -> duplicateParticipantUserId', () {
      expect(
        () => splitEqually(lkr(1000), ['alice', 'bob', 'alice']),
        throwsA(isA<ValidationException>().having(
          (e) => e.code, 'code', ValidationErrorCode.duplicateParticipantUserId)),
      );
    });
    test('blank userId (empty string) -> blankParticipantUserId', () {
      expect(
        () => splitEqually(lkr(1000), ['alice', '']),
        throwsA(isA<ValidationException>().having(
          (e) => e.code, 'code', ValidationErrorCode.blankParticipantUserId)),
      );
    });
    test('blank userId (whitespace) -> blankParticipantUserId', () {
      expect(
        () => splitEqually(lkr(1000), ['alice', '   ']),
        throwsA(isA<ValidationException>().having(
          (e) => e.code, 'code', ValidationErrorCode.blankParticipantUserId)),
      );
    });
  });

  // Test 14: allocateLargestRemainder direct tests
  group('Test 14 - allocateLargestRemainder', () {
    test('[1,1,1] total=100 -> [34,33,33]', () {
      final result = allocateLargestRemainder(100, [1, 1, 1]);
      expect(result, [34, 33, 33]);
      expect(result.fold(0, (a, b) => a + b), 100);
    });
    test('[2,1] total=100 -> [67,33]', () {
      final result = allocateLargestRemainder(100, [2, 1]);
      expect(result, [67, 33]);
      expect(result.fold(0, (a, b) => a + b), 100);
    });
    test('[1,1] total=1 -> [1,0]', () {
      final result = allocateLargestRemainder(1, [1, 1]);
      expect(result, [1, 0]);
      expect(result.fold(0, (a, b) => a + b), 1);
    });
    test('sum invariant on 500 random weight combinations', () {
      final rng = Random(7);
      for (var i = 0; i < 500; i++) {
        final total = rng.nextInt(100000) + 1;
        final n = rng.nextInt(20) + 1;
        final weights = List<int>.generate(n, (_) => rng.nextInt(10) + 1);
        final result = allocateLargestRemainder(total, weights);
        expect(result.fold(0, (a, b) => a + b), total);
      }
    });
    test('empty weights -> weightsEmpty', () {
      expect(
        () => allocateLargestRemainder(100, []),
        throwsA(isA<ValidationException>().having(
          (e) => e.code, 'code', ValidationErrorCode.weightsEmpty)),
      );
    });
    test('zero weight -> invalidWeight', () {
      expect(
        () => allocateLargestRemainder(100, [1, 0, 1]),
        throwsA(isA<ValidationException>().having(
          (e) => e.code, 'code', ValidationErrorCode.invalidWeight)),
      );
    });
    test('negative weight -> invalidWeight', () {
      expect(
        () => allocateLargestRemainder(100, [1, -2]),
        throwsA(isA<ValidationException>().having(
          (e) => e.code, 'code', ValidationErrorCode.invalidWeight)),
      );
    });
  });

  // Test 15: integration with Expense.validate()
  group('Test 15 - integration with Expense.validate()', () {
    test('9000 among 3 -> expense validates', () {
      final e = _expenseWithEqualShares(total: lkr(9000), participants: ['alice', 'bob', 'carol']);
      expect(() => e.validate(), returnsNormally);
      expect(e.validateAll().isValid, isTrue);
    });
    test('10000 among 3 -> expense validates', () {
      expect(
        () => _expenseWithEqualShares(total: lkr(10000), participants: ['alice', 'bob', 'carol']).validate(),
        returnsNormally);
    });
    test('10000 among 4 -> expense validates', () {
      expect(
        () => _expenseWithEqualShares(total: lkr(10000), participants: ['a', 'b', 'c', 'd']).validate(),
        returnsNormally);
    });
    test('1 among 3 -> expense validates', () {
      expect(
        () => _expenseWithEqualShares(total: lkr(1), participants: ['alice', 'bob', 'carol']).validate(),
        returnsNormally);
    });
    test('2 among 3 -> expense validates', () {
      expect(
        () => _expenseWithEqualShares(total: lkr(2), participants: ['alice', 'bob', 'carol']).validate(),
        returnsNormally);
    });
    test('single participant -> expense validates', () {
      expect(
        () => _expenseWithEqualShares(total: lkr(9999), participants: ['solo']).validate(),
        returnsNormally);
    });
    test('dinner-style: 8000 among 4 -> 2000 each, validates', () {
      final shares = splitEqually(usd(8000), ['alex', 'sam', 'jordan', 'maya']);
      expect(shares.map((s) => s.amount.minorUnits).toSet(), {2000});
      final expense = Expense(
        id: 'dinner', tripId: 'trip-1', title: 'Dinner',
        date: _now, total: usd(8000),
        payers: [Payer(userId: 'alex', amount: usd(8000))],
        shares: shares, createdBy: 'alex', createdAt: _now,
      );
      expect(() => expense.validate(), returnsNormally);
      expect(expense.validateAll().isValid, isTrue);
    });
  });
}
