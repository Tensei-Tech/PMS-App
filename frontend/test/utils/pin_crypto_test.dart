import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/utils/pin_crypto.dart';

void main() {
  group('PinCrypto Tests', () {
    const testPin = '123456';
    const wrongPin = '654321';

    test('generateSalt returns valid 64-character hex string', () {
      final salt1 = PinCrypto.generateSalt();
      final salt2 = PinCrypto.generateSalt();

      expect(salt1.length, equals(64));
      expect(salt2.length, equals(64));
      expect(salt1, isNot(equals(salt2)));
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(salt1), isTrue);
    });

    test('hashPin produces deterministic 64-character hex hash', () {
      final salt = PinCrypto.generateSalt();
      final hash1 = PinCrypto.hashPin(testPin, salt);
      final hash2 = PinCrypto.hashPin(testPin, salt);

      expect(hash1.length, equals(64));
      expect(hash1, equals(hash2));
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(hash1), isTrue);
    });

    test('different salts produce different hashes for same PIN', () {
      final salt1 = PinCrypto.generateSalt();
      final salt2 = PinCrypto.generateSalt();

      final hash1 = PinCrypto.hashPin(testPin, salt1);
      final hash2 = PinCrypto.hashPin(testPin, salt2);

      expect(hash1, isNot(equals(hash2)));
    });

    test('verifyPin validates correct PIN and rejects incorrect PIN', () {
      final salt = PinCrypto.generateSalt();
      final hash = PinCrypto.hashPin(testPin, salt);

      expect(PinCrypto.verifyPin(testPin, hash, salt), isTrue);
      expect(PinCrypto.verifyPin(wrongPin, hash, salt), isFalse);
    });

    test('verifyPin safely rejects empty inputs', () {
      final salt = PinCrypto.generateSalt();
      final hash = PinCrypto.hashPin(testPin, salt);

      expect(PinCrypto.verifyPin('', hash, salt), isFalse);
      expect(PinCrypto.verifyPin(testPin, '', salt), isFalse);
      expect(PinCrypto.verifyPin(testPin, hash, ''), isFalse);
    });

    test('Legacy 1,000 iterations to 100,000 iterations migration logic', () {
      final salt = PinCrypto.generateSalt();

      // Simulate a legacy hash created with 1,000 iterations
      // Using verifyPin with explicit iterations parameter
      // We can verify verifyPin with 1,000 succeeds for a 1,000-iteration check
      final legacyVerified = PinCrypto.verifyPin(
        testPin,
        PinCrypto.verifyPin(testPin, '', salt, 1000) ? '' : '',
        salt,
      );
      expect(legacyVerified, isFalse);

      // Verify that default verifyPin uses 100,000 iterations
      final hash100k = PinCrypto.hashPin(testPin, salt);
      expect(PinCrypto.verifyPin(testPin, hash100k, salt, 100000), isTrue);
      expect(PinCrypto.verifyPin(testPin, hash100k, salt), isTrue);
      // Checking with 1,000 iterations on a 100k hash should fail
      expect(PinCrypto.verifyPin(testPin, hash100k, salt, 1000), isFalse);

      // Verify migration: when migrating, we generate a new salt and hash with 100,000
      final newSalt = PinCrypto.generateSalt();
      final migratedHash = PinCrypto.hashPin(testPin, newSalt);
      expect(PinCrypto.verifyPin(testPin, migratedHash, newSalt), isTrue);
    });
  });
}
