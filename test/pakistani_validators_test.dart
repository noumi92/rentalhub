import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/core/utils/pakistani_validators.dart';

void main() {
  group('PakistaniValidators - NADRA CNIC Tests', () {
    test('Valid CNIC with standard hyphen structure passes', () {
      expect(PakistaniValidators.validateCnic('35201-1234567-1'), isNull);
      expect(PakistaniValidators.validateCnic('42201-5501928-7'), isNull);
      expect(PakistaniValidators.validateCnic('61101-9018274-3'), isNull);
      expect(PakistaniValidators.validateCnic('17301-1234567-2'), isNull);
    });

    test('Valid raw 13 digits without hyphens passes', () {
      expect(PakistaniValidators.validateCnic('3520112345671'), isNull);
    });

    test('Rejects empty or null CNIC', () {
      expect(PakistaniValidators.validateCnic(null), equals('CNIC number is required'));
      expect(PakistaniValidators.validateCnic('   '), equals('CNIC number is required'));
    });

    test('Rejects CNIC with incorrect length', () {
      expect(PakistaniValidators.validateCnic('35201-123456-1'), contains('must be exactly 13 digits'));
      expect(PakistaniValidators.validateCnic('35201-12345678-1'), contains('must be exactly 13 digits'));
    });

    test('Rejects non-numeric characters in CNIC', () {
      expect(PakistaniValidators.validateCnic('3520A-1234567-1'), contains('only digits'));
    });

    test('Rejects invalid NADRA province prefix (0, 8, 9)', () {
      expect(PakistaniValidators.validateCnic('05201-1234567-1'), contains('Invalid NADRA province prefix'));
      expect(PakistaniValidators.validateCnic('85201-1234567-1'), contains('Invalid NADRA province prefix'));
      expect(PakistaniValidators.validateCnic('95201-1234567-1'), contains('Invalid NADRA province prefix'));
    });

    test('Rejects malformed hyphen placement', () {
      expect(PakistaniValidators.validateCnic('3520-11234567-1'), contains('Format must be XXXXX-XXXXXXX-X'));
    });

    test('formatCnic helper formats raw digits correctly', () {
      expect(PakistaniValidators.formatCnic('3520112345671'), equals('35201-1234567-1'));
    });
  });

  group('PakistaniValidators - Cellular & WhatsApp Tests', () {
    test('Valid +92 mobile numbers pass', () {
      expect(PakistaniValidators.validatePakistaniPhone('+92 300 1234567'), isNull);
      expect(PakistaniValidators.validatePakistaniPhone('+923459876543'), isNull);
      expect(PakistaniValidators.validatePakistaniPhone('+92 321 0000000'), isNull);
      expect(PakistaniValidators.validatePakistaniPhone('+92 333 1122334'), isNull);
    });

    test('Valid 03 mobile numbers pass', () {
      expect(PakistaniValidators.validatePakistaniPhone('03001234567'), isNull);
      expect(PakistaniValidators.validatePakistaniPhone('0345 9876543'), isNull);
    });

    test('Rejects empty or null phone number', () {
      expect(PakistaniValidators.validatePakistaniPhone(null), equals('Mobile/WhatsApp number is required'));
      expect(PakistaniValidators.validatePakistaniPhone('  '), equals('Mobile/WhatsApp number is required'));
    });

    test('Rejects landlines and international numbers', () {
      expect(PakistaniValidators.validatePakistaniPhone('021-3456789'), contains('valid Pakistani mobile number'));
      expect(PakistaniValidators.validatePakistaniPhone('+1 555 1234567'), contains('valid Pakistani mobile number'));
    });

    test('Rejects incorrect digit length for +92 or 03 prefix', () {
      expect(PakistaniValidators.validatePakistaniPhone('+92 300 123'), contains('must be 13 characters'));
      expect(PakistaniValidators.validatePakistaniPhone('0300 123'), contains('must be 11 digits'));
    });

    test('Rejects non-numeric characters', () {
      expect(PakistaniValidators.validatePakistaniPhone('0300123456A'), contains('Invalid Pakistani mobile number format'));
    });
  });

  group('PakistaniValidators - IBAN & Account Number Tests', () {
    test('Valid Pakistani IBAN passes', () {
      expect(PakistaniValidators.validatePakistaniIban('PK36MEZN0000010123456701'), isNull);
      expect(PakistaniValidators.validatePakistaniIban('PK12HABB0000112233445566'), isNull);
      expect(PakistaniValidators.validatePakistaniIban('pk36mezn0000010123456701'), isNull);
    });

    test('Valid regular domestic bank account number passes', () {
      expect(PakistaniValidators.validatePakistaniIban('010123456701'), isNull);
      expect(PakistaniValidators.validatePakistaniIban('123456789012'), isNull);
    });

    test('Rejects empty or null IBAN', () {
      expect(PakistaniValidators.validatePakistaniIban(null), equals('IBAN / Account Number is required'));
      expect(PakistaniValidators.validatePakistaniIban(''), equals('IBAN / Account Number is required'));
    });

    test('Rejects invalid IBAN length or structure', () {
      expect(PakistaniValidators.validatePakistaniIban('PK36MEZN123'), contains('must be exactly 24'));
      expect(PakistaniValidators.validatePakistaniIban('PK3612340000010123456701'), contains('Invalid Pakistani IBAN structure'));
    });

    test('Rejects too short account numbers', () {
      expect(PakistaniValidators.validatePakistaniIban('12345'), contains('between 8 and 24 characters'));
    });
  });

  group('PakistaniValidators - Rates & Specs Tests', () {
    test('Valid rental rates pass', () {
      expect(PakistaniValidators.validateRentalRate('1500', label: 'Rate'), isNull);
      expect(PakistaniValidators.validateRentalRate('15,000', label: 'Rate'), isNull);
    });

    test('Rejects negative or zero rates when disallowed', () {
      expect(PakistaniValidators.validateRentalRate('-500', label: 'Daily Rate'), contains('cannot be negative'));
      expect(PakistaniValidators.validateRentalRate('0', label: 'Hourly Rate', allowZero: false), contains('greater than 0 PKR'));
    });

    test('Rejects non-numeric rate input', () {
      expect(PakistaniValidators.validateRentalRate('abc', label: 'Rate'), contains('valid numeric amount'));
    });

    test('Valid seating capacities pass', () {
      expect(PakistaniValidators.validateSeatingCapacity('4'), isNull);
      expect(PakistaniValidators.validateSeatingCapacity('5'), isNull);
      expect(PakistaniValidators.validateSeatingCapacity('7'), isNull);
      expect(PakistaniValidators.validateSeatingCapacity('14'), isNull);
    });

    test('Rejects invalid seating capacities', () {
      expect(PakistaniValidators.validateSeatingCapacity(null), contains('required'));
      expect(PakistaniValidators.validateSeatingCapacity('0'), contains('between 1 and 50'));
      expect(PakistaniValidators.validateSeatingCapacity('-2'), contains('between 1 and 50'));
      expect(PakistaniValidators.validateSeatingCapacity('55'), contains('between 1 and 50'));
      expect(PakistaniValidators.validateSeatingCapacity('xyz'), contains('must be a number'));
    });
  });
}

