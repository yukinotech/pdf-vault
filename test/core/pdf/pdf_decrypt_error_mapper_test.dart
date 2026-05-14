import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_vault/core/pdf/pdf_decrypt_error_mapper.dart';
import 'package:pdf_vault/core/pdf/pdf_decrypt_error_type.dart';

void main() {
  group('PdfDecryptErrorMapper', () {
    test('maps invalid password platform errors', () {
      final result = PdfDecryptErrorMapper.fromPlatformException(
        PlatformException(code: 'INVALID_PASSWORD'),
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorType, PdfDecryptErrorType.invalidPassword);
    });

    test('maps unreadable input platform errors', () {
      final result = PdfDecryptErrorMapper.fromPlatformException(
        PlatformException(
          code: 'FILE_NOT_FOUND',
          message: 'source file not found',
        ),
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorType, PdfDecryptErrorType.unreadableInput);
    });

    test('falls back to unknown for unmapped errors', () {
      final result = PdfDecryptErrorMapper.fromPlatformException(
        PlatformException(code: 'SOMETHING_ELSE'),
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorType, PdfDecryptErrorType.unknown);
    });
  });
}
