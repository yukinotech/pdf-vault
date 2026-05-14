import 'package:flutter/services.dart';
import 'package:pdf_vault/core/pdf/pdf_decrypt_error_type.dart';
import 'package:pdf_vault/core/pdf/pdf_decrypt_result.dart';

class PdfDecryptErrorMapper {
  const PdfDecryptErrorMapper._();

  static PdfDecryptResult fromPlatformException(
    PlatformException error, {
    String? outputPath,
  }) {
    final normalizedCode = error.code.toUpperCase();
    final normalizedMessage = (error.message ?? '').toLowerCase();

    if (normalizedCode.contains('INVALID_PASSWORD') ||
        normalizedMessage.contains('password')) {
      return PdfDecryptResult.failure(
        errorType: PdfDecryptErrorType.invalidPassword,
        outputPath: outputPath,
        message:
            'The password is incorrect. Please double-check and try again.',
      );
    }

    if (normalizedCode.contains('FILE_NOT_FOUND') ||
        normalizedCode.contains('READ') ||
        normalizedMessage.contains('not found') ||
        normalizedMessage.contains('read')) {
      return PdfDecryptResult.failure(
        errorType: PdfDecryptErrorType.unreadableInput,
        outputPath: outputPath,
        message: 'The selected PDF could not be read from this location.',
      );
    }

    if (normalizedCode.contains('CANCEL')) {
      return PdfDecryptResult.failure(
        errorType: PdfDecryptErrorType.cancelled,
        outputPath: outputPath,
        message: 'Export was cancelled before the unlocked PDF was saved.',
      );
    }

    if (normalizedCode.contains('UNSUPPORTED') ||
        normalizedMessage.contains('encrypted pdf') ||
        normalizedMessage.contains('not protected') ||
        normalizedMessage.contains('unsupported')) {
      return PdfDecryptResult.failure(
        errorType: PdfDecryptErrorType.unsupportedDocument,
        outputPath: outputPath,
        message:
            'This PDF could not be processed by the current unlock engine.',
      );
    }

    return PdfDecryptResult.failure(
      errorType: PdfDecryptErrorType.unknown,
      outputPath: outputPath,
      message: 'Something went wrong while unlocking the PDF.',
    );
  }
}
