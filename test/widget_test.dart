import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_task_manager_back4app/utils/validators.dart';

void main() {
  group('BITS WILP email validation', () {
    test('accepts a valid WILP email', () {
      expect(
        Validators.email('2025tm93217@wilp.bits-pilani.ac.in'),
        isNull,
      );
    });

    test('accepts valid emails regardless of casing', () {
      expect(
        Validators.email('2025TM93217@WILP.BITS-PILANI.AC.IN'),
        isNull,
      );
    });

    test('rejects non-WILP domains', () {
      expect(
        Validators.email('2025tm93217@gmail.com'),
        'Use your BITS WILP email ending with @wilp.bits-pilani.ac.in',
      );
    });

    test('rejects empty email values', () {
      expect(Validators.email(''), 'Email is required');
    });
  });

  group('password validation', () {
    test('rejects passwords shorter than 8 characters', () {
      expect(
        Validators.password('short'),
        'Password must be at least 8 characters',
      );
    });

    test('accepts passwords with 8 or more characters', () {
      expect(Validators.password('password123'), isNull);
    });
  });
}
