import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/security/memory_zeroizer.dart';

void main() {
  group('MemoryZeroizer Tests', () {
    test('Zeroizes buffer in place completely', () {
      final keyBuffer = Uint8List.fromList([1, 2, 3, 4, 5, 255, 128, 42]);
      expect(keyBuffer.any((b) => b != 0), isTrue);

      MemoryZeroizer.zeroize(keyBuffer);

      expect(keyBuffer.every((b) => b == 0), isTrue);
    });

    test('withZeroizedKey executes block and zeroizes key upon completion', () {
      final keyBuffer = Uint8List.fromList([10, 20, 30, 40]);

      final result = MemoryZeroizer.withZeroizedKey(keyBuffer, (key) {
        expect(key[0], equals(10));
        return 'executed';
      });

      expect(result, equals('executed'));
      expect(keyBuffer.every((b) => b == 0), isTrue);
    });

    test('withZeroizedKey zeroes key even if exception is thrown', () {
      final keyBuffer = Uint8List.fromList([99, 88, 77]);

      expect(
        () => MemoryZeroizer.withZeroizedKey(keyBuffer, (key) {
          throw Exception('Fatal error in crypto block');
        }),
        throwsException,
      );

      // Memory must be wiped regardless of exception
      expect(keyBuffer.every((b) => b == 0), isTrue);
    });
  });
}
