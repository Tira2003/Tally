import 'package:test/test.dart';
import 'package:tally_engine/tally_engine.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

Money lkr(int minorUnits) => Money(minorUnits: minorUnits, currency: 'LKR');
Money usd(int minorUnits) => Money(minorUnits: minorUnits, currency: 'USD');

final _now = DateTime(2024, 6, 1);

/// Builds a minimal valid [Expense] with one payer and one share, both
/// equalling [total].  Callers may override individual fields.
Expense _base({
  String id = 'exp-1',
  String tripId = 'trip-1',
  String title = 'Dinner',
  DateTime? date,
  Money? total,
  List<Payer>? payers,
  List<Share>? shares,
  List<ExpenseItem>? items,
}) {
  final t = total ?? lkr(10000); // 100.00 LKR
  return Expense(
    id: id,
    tripId: tripId,
    title: title,
    date: date ?? _now,
    total: t,
    payers: payers ?? [Payer(userId: 'alice', amount: t)],
    shares: shares ?? [Share(userId: 'alice', amount: t)],
    items: items ?? const [],
    createdBy: 'alice',
    createdAt: _now,
  );
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ── 1. Valid expense: one payer, equal shares ──────────────────────────────
  group('Test 1 – valid single-payer equal-share expense', () {
    test('passes validation without throwing', () {
      final expense = _base();
      expect(() => expense.validate(), returnsNormally);
      expect(expense.validateAll().isValid, isTrue);
    });
  });

  // ── 2. Valid pooled: 3 uneven payers (30+50+20=100), 2 consumers ──────────
  group('Test 2 – valid pooled expense with uneven payers', () {
    test('3 payers summing to total passes', () {
      final expense = _base(
        total: lkr(10000),
        payers: [
          Payer(userId: 'alice', amount: lkr(3000)),
          Payer(userId: 'bob', amount: lkr(5000)),
          Payer(userId: 'carol', amount: lkr(2000)),
        ],
        shares: [
          Share(userId: 'alice', amount: lkr(5000)),
          Share(userId: 'bob', amount: lkr(5000)),
        ],
      );
      expect(() => expense.validate(), returnsNormally);
    });
  });

  // ── 3. Creditor / debtor asymmetry ────────────────────────────────────────
  group('Test 3 – payer who does not consume; consumer who did not pay', () {
    test('passes validation', () {
      // Carol pays but does not consume.
      // Dave consumes but does not pay.
      final expense = _base(
        total: lkr(10000),
        payers: [
          Payer(userId: 'carol', amount: lkr(10000)),
        ],
        shares: [
          Share(userId: 'dave', amount: lkr(10000)),
        ],
      );
      expect(() => expense.validate(), returnsNormally);
    });
  });

  // ── 4. Payers do not sum to total ─────────────────────────────────────────
  group('Test 4 – payers sum mismatch', () {
    test('payers sum too LOW → payersDoNotSumToTotal', () {
      final expense = _base(
        total: lkr(10000),
        payers: [Payer(userId: 'alice', amount: lkr(9000))], // short by 1000
        shares: [Share(userId: 'alice', amount: lkr(10000))],
      );
      expect(
        () => expense.validate(),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'code',
            ValidationErrorCode.payersDoNotSumToTotal,
          ),
        ),
      );
    });

    test('payers sum too HIGH → payersDoNotSumToTotal', () {
      final expense = _base(
        total: lkr(10000),
        payers: [Payer(userId: 'alice', amount: lkr(11000))], // over by 1000
        shares: [Share(userId: 'alice', amount: lkr(10000))],
      );
      expect(
        () => expense.validate(),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'code',
            ValidationErrorCode.payersDoNotSumToTotal,
          ),
        ),
      );
    });
  });

  // ── 5. Shares do not sum to total ─────────────────────────────────────────
  group('Test 5 – shares sum mismatch', () {
    test('shares sum too LOW → sharesDoNotSumToTotal', () {
      final expense = _base(
        total: lkr(10000),
        payers: [Payer(userId: 'alice', amount: lkr(10000))],
        shares: [Share(userId: 'alice', amount: lkr(8000))], // short by 2000
      );
      expect(
        () => expense.validate(),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'code',
            ValidationErrorCode.sharesDoNotSumToTotal,
          ),
        ),
      );
    });

    test('shares sum too HIGH → sharesDoNotSumToTotal', () {
      final expense = _base(
        total: lkr(10000),
        payers: [Payer(userId: 'alice', amount: lkr(10000))],
        shares: [Share(userId: 'alice', amount: lkr(12000))], // over by 2000
      );
      expect(
        () => expense.validate(),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'code',
            ValidationErrorCode.sharesDoNotSumToTotal,
          ),
        ),
      );
    });
  });

  // ── 6. Independence of the two ledgers ────────────────────────────────────
  group('Test 6 – ledgers are independent', () {
    test('payers valid, shares invalid → sharesDoNotSumToTotal (not payers error)', () {
      final expense = _base(
        total: lkr(10000),
        payers: [Payer(userId: 'alice', amount: lkr(10000))], // ✓
        shares: [Share(userId: 'alice', amount: lkr(9000))],  // ✗
      );
      expect(
        () => expense.validate(),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'code',
            ValidationErrorCode.sharesDoNotSumToTotal,
          ),
        ),
      );
    });

    test('shares valid, payers invalid → payersDoNotSumToTotal (not shares error)', () {
      final expense = _base(
        total: lkr(10000),
        payers: [Payer(userId: 'alice', amount: lkr(9000))],  // ✗
        shares: [Share(userId: 'alice', amount: lkr(10000))], // ✓
      );
      expect(
        () => expense.validate(),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'code',
            ValidationErrorCode.payersDoNotSumToTotal,
          ),
        ),
      );
    });
  });

  // ── 7. Edge-case failures ─────────────────────────────────────────────────
  group('Test 7 – individual constraint failures', () {
    test('empty payers → payersEmpty', () {
      final expense = _base(payers: []);
      expect(
        () => expense.validate(),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'code',
            ValidationErrorCode.payersEmpty,
          ),
        ),
      );
    });

    test('empty shares → sharesEmpty', () {
      final expense = _base(shares: []);
      expect(
        () => expense.validate(),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'code',
            ValidationErrorCode.sharesEmpty,
          ),
        ),
      );
    });

    test('zero total → totalNotPositive', () {
      final expense = _base(
        total: lkr(0),
        payers: [Payer(userId: 'alice', amount: lkr(0))],
        shares: [Share(userId: 'alice', amount: lkr(0))],
      );
      expect(
        () => expense.validate(),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'code',
            ValidationErrorCode.totalNotPositive,
          ),
        ),
      );
    });

    test('negative total → totalNotPositive', () {
      final expense = _base(
        total: lkr(-100),
        payers: [Payer(userId: 'alice', amount: lkr(100))],
        shares: [Share(userId: 'alice', amount: lkr(100))],
      );
      expect(
        () => expense.validate(),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'code',
            ValidationErrorCode.totalNotPositive,
          ),
        ),
      );
    });

    test('negative share amount → shareAmountNegative', () {
      final expense = _base(
        total: lkr(10000),
        payers: [Payer(userId: 'alice', amount: lkr(10000))],
        shares: [
          Share(userId: 'alice', amount: lkr(11000)),
          Share(userId: 'bob', amount: lkr(-1000)),
        ],
      );
      expect(
        () => expense.validate(),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'code',
            ValidationErrorCode.shareAmountNegative,
          ),
        ),
      );
    });

    test('duplicate userId in payers → duplicatePayerUserId', () {
      final expense = _base(
        total: lkr(10000),
        payers: [
          Payer(userId: 'alice', amount: lkr(5000)),
          Payer(userId: 'alice', amount: lkr(5000)), // duplicate
        ],
        shares: [Share(userId: 'alice', amount: lkr(10000))],
      );
      expect(
        () => expense.validate(),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'code',
            ValidationErrorCode.duplicatePayerUserId,
          ),
        ),
      );
    });

    test('duplicate userId in shares → duplicateShareUserId', () {
      final expense = _base(
        total: lkr(10000),
        payers: [Payer(userId: 'alice', amount: lkr(10000))],
        shares: [
          Share(userId: 'alice', amount: lkr(5000)),
          Share(userId: 'alice', amount: lkr(5000)), // duplicate
        ],
      );
      expect(
        () => expense.validate(),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'code',
            ValidationErrorCode.duplicateShareUserId,
          ),
        ),
      );
    });
  });

  // ── 8. Mixed currencies ───────────────────────────────────────────────────
  group('Test 8 – mixed currency', () {
    test('payer with different currency → currencyMismatch', () {
      final expense = _base(
        total: lkr(10000),
        payers: [Payer(userId: 'alice', amount: usd(10000))], // USD vs LKR
        shares: [Share(userId: 'alice', amount: lkr(10000))],
      );
      expect(
        () => expense.validate(),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'code',
            ValidationErrorCode.currencyMismatch,
          ),
        ),
      );
    });

    test('share with different currency → currencyMismatch', () {
      final expense = _base(
        total: lkr(10000),
        payers: [Payer(userId: 'alice', amount: lkr(10000))],
        shares: [Share(userId: 'alice', amount: usd(10000))], // USD vs LKR
      );
      expect(
        () => expense.validate(),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'code',
            ValidationErrorCode.currencyMismatch,
          ),
        ),
      );
    });

    test('Money.sum with mixed currencies throws', () {
      expect(
        () => Money.sum([lkr(100), usd(100)]),
        throwsA(isA<ValidationException>()),
      );
    });

    test('Money + with different currencies throws', () {
      expect(() => lkr(100) + usd(50), throwsA(isA<ValidationException>()));
    });

    test('Money - with different currencies throws', () {
      expect(() => lkr(100) - usd(50), throwsA(isA<ValidationException>()));
    });
  });

  // ── 9. Itemized expense ───────────────────────────────────────────────────
  group('Test 9 – itemized expense', () {
    test('item prices sum correctly → passes', () {
      final expense = _base(
        total: lkr(15000),
        payers: [Payer(userId: 'alice', amount: lkr(15000))],
        shares: [Share(userId: 'alice', amount: lkr(15000))],
        items: [
          ExpenseItem(
            id: 'i1',
            name: 'Steak',
            price: lkr(10000),
            consumerUserIds: ['alice'],
          ),
          ExpenseItem(
            id: 'i2',
            name: 'Wine',
            price: lkr(5000),
            consumerUserIds: ['alice'],
          ),
        ],
      );
      expect(() => expense.validate(), returnsNormally);
    });

    test('item prices do not sum to total → itemsDoNotSumToTotal', () {
      final expense = _base(
        total: lkr(15000),
        payers: [Payer(userId: 'alice', amount: lkr(15000))],
        shares: [Share(userId: 'alice', amount: lkr(15000))],
        items: [
          ExpenseItem(
            id: 'i1',
            name: 'Steak',
            price: lkr(10000),
            consumerUserIds: ['alice'],
          ),
          ExpenseItem(
            id: 'i2',
            name: 'Wine',
            price: lkr(4000), // only 14000 instead of 15000
            consumerUserIds: ['alice'],
          ),
        ],
      );
      expect(
        () => expense.validate(),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'code',
            ValidationErrorCode.itemsDoNotSumToTotal,
          ),
        ),
      );
    });

    test('item with zero price → itemPriceNotPositive', () {
      final expense = _base(
        total: lkr(10000),
        payers: [Payer(userId: 'alice', amount: lkr(10000))],
        shares: [Share(userId: 'alice', amount: lkr(10000))],
        items: [
          ExpenseItem(
            id: 'i1',
            name: 'Steak',
            price: lkr(10000),
            consumerUserIds: ['alice'],
          ),
          ExpenseItem(
            id: 'i2',
            name: 'Freebie',
            price: lkr(0), // zero not allowed
            consumerUserIds: ['alice'],
          ),
        ],
      );
      expect(
        () => expense.validate(),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'code',
            ValidationErrorCode.itemPriceNotPositive,
          ),
        ),
      );
    });
  });

  // ── 10. Worked $80 dinner example ─────────────────────────────────────────
  group('Test 10 – \$80 dinner worked example (minor units × 100)', () {
    // Total: 8000 minor units (i.e. $80.00)
    // Payers: Alex 3000, Sam 3000, Jordan 2000
    // Shares: Maya 4450, Devon 1450, Alex 1050, Sam 1050
    // Items: Steak 4000→Maya; Salad 1000→Devon;
    //        Appetizer 1800→Maya,Devon,Alex,Sam; Wine 1200→Alex,Sam
    //
    // Payer sum:  3000+3000+2000 = 8000 ✓
    // Share sum:  4450+1450+1050+1050 = 8000 ✓
    // Item sum:   4000+1000+1800+1200 = 8000 ✓

    test('passes full validation', () {
      final expense = Expense(
        id: 'dinner-80',
        tripId: 'trip-nyc',
        title: '\$80 Dinner',
        date: _now,
        total: usd(8000),
        payers: [
          Payer(userId: 'alex', amount: usd(3000)),
          Payer(userId: 'sam', amount: usd(3000)),
          Payer(userId: 'jordan', amount: usd(2000)),
        ],
        shares: [
          Share(userId: 'maya', amount: usd(4450)),
          Share(userId: 'devon', amount: usd(1450)),
          Share(userId: 'alex', amount: usd(1050)),
          Share(userId: 'sam', amount: usd(1050)),
        ],
        items: [
          ExpenseItem(
            id: 'steak',
            name: 'Steak',
            price: usd(4000),
            consumerUserIds: ['maya'],
          ),
          ExpenseItem(
            id: 'salad',
            name: 'Salad',
            price: usd(1000),
            consumerUserIds: ['devon'],
          ),
          ExpenseItem(
            id: 'appetizer',
            name: 'Appetizer',
            price: usd(1800),
            consumerUserIds: ['maya', 'devon', 'alex', 'sam'],
          ),
          ExpenseItem(
            id: 'wine',
            name: 'Wine',
            price: usd(1200),
            consumerUserIds: ['alex', 'sam'],
          ),
        ],
        createdBy: 'alex',
        createdAt: _now,
      );

      expect(() => expense.validate(), returnsNormally);
      expect(expense.validateAll().isValid, isTrue);
    });

    test('payer sum is actually 8000', () {
      final amounts = [usd(3000), usd(3000), usd(2000)];
      expect(Money.sum(amounts, currency: 'USD'), equals(usd(8000)));
    });

    test('share sum is actually 8000', () {
      final amounts = [usd(4450), usd(1450), usd(1050), usd(1050)];
      expect(Money.sum(amounts, currency: 'USD'), equals(usd(8000)));
    });

    test('item sum is actually 8000', () {
      final amounts = [usd(4000), usd(1000), usd(1800), usd(1200)];
      expect(Money.sum(amounts, currency: 'USD'), equals(usd(8000)));
    });
  });

  // ── 11. copyWith and equality ─────────────────────────────────────────────
  group('Test 11 – copyWith, equality, and list immutability', () {
    test('two expenses with same data are equal', () {
      final a = _base();
      final b = _base();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('copyWith changes only the specified field', () {
      final original = _base();
      final modified = original.copyWith(title: 'Lunch');
      expect(modified.title, 'Lunch');
      expect(modified.id, original.id);
      expect(modified.total, original.total);
      expect(modified, isNot(equals(original)));
    });

    test('Expense.payers list is unmodifiable', () {
      final expense = _base();
      expect(
        () => (expense.payers as List).add(Payer(userId: 'x', amount: lkr(100))),
        throwsUnsupportedError,
      );
    });

    test('Expense.shares list is unmodifiable', () {
      final expense = _base();
      expect(
        () => (expense.shares as List).add(Share(userId: 'x', amount: lkr(100))),
        throwsUnsupportedError,
      );
    });

    test('Expense.items list is unmodifiable', () {
      final expense = _base(
        items: [
          ExpenseItem(
            id: 'i1',
            name: 'Steak',
            price: lkr(10000),
            consumerUserIds: ['alice'],
          ),
        ],
      );
      expect(
        () => (expense.items as List).add(
          ExpenseItem(
            id: 'i2',
            name: 'Wine',
            price: lkr(500),
            consumerUserIds: [],
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('Money equality and hashCode', () {
      expect(lkr(5000), equals(lkr(5000)));
      expect(lkr(5000).hashCode, equals(lkr(5000).hashCode));
      expect(lkr(5000), isNot(equals(lkr(4999))));
      expect(lkr(5000), isNot(equals(usd(5000))));
    });

    test('Money.copyWith produces new instance with changed field', () {
      final m = lkr(1000);
      expect(m.copyWith(minorUnits: 2000), equals(lkr(2000)));
      expect(m.copyWith(currency: 'USD'), equals(usd(1000)));
    });

    test('Payer equality', () {
      final p1 = Payer(userId: 'alice', amount: lkr(100));
      final p2 = Payer(userId: 'alice', amount: lkr(100));
      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
    });

    test('Share equality', () {
      final s1 = Share(userId: 'bob', amount: lkr(200));
      final s2 = Share(userId: 'bob', amount: lkr(200));
      expect(s1, equals(s2));
    });

    test('ExpenseItem equality', () {
      final i1 = ExpenseItem(
        id: 'i1', name: 'Steak', price: lkr(500), consumerUserIds: ['a', 'b'],
      );
      final i2 = ExpenseItem(
        id: 'i1', name: 'Steak', price: lkr(500), consumerUserIds: ['a', 'b'],
      );
      expect(i1, equals(i2));
    });
  });

  // ── validateAll collects all errors ───────────────────────────────────────
  group('validateAll – collects multiple errors simultaneously', () {
    test('returns multiple errors when multiple rules fail', () {
      // Zero total + empty payers + empty shares all fail.
      // But due to early short-circuits, zero total is caught first and
      // then payers/shares checks cascade.
      // We use a case where payers sum AND shares sum are wrong.
      final expense = _base(
        total: lkr(10000),
        payers: [Payer(userId: 'alice', amount: lkr(9000))],  // wrong sum
        shares: [Share(userId: 'alice', amount: lkr(8000))],  // wrong sum
      );
      final result = expense.validateAll();
      expect(result.isValid, isFalse);
      final codes = result.errors.map((e) => e.code).toList();
      expect(codes, containsAll([
        ValidationErrorCode.payersDoNotSumToTotal,
        ValidationErrorCode.sharesDoNotSumToTotal,
      ]));
    });

    test('empty result on valid expense', () {
      expect(_base().validateAll().isValid, isTrue);
      expect(_base().validateAll().errors, isEmpty);
    });
  });

  // ── Money.sum edge cases ──────────────────────────────────────────────────
  group('Money.sum', () {
    test('empty iterable returns zero in specified currency', () {
      expect(Money.sum([], currency: 'LKR'), equals(lkr(0)));
      expect(Money.sum([], currency: 'USD'), equals(usd(0)));
    });

    test('single element returns that element', () {
      expect(Money.sum([lkr(500)]), equals(lkr(500)));
    });

    test('multiple elements summed correctly', () {
      expect(
        Money.sum([lkr(100), lkr(200), lkr(300)]),
        equals(lkr(600)),
      );
    });
  });
}
