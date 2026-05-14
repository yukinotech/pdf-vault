import 'dart:io';

import 'package:decrypt_pdf/decrypt_pdf.dart';
import 'package:flutter/services.dart';
import 'package:pdf_vault/core/pdf/pdf_decrypt_core.dart';
import 'package:pdf_vault/core/pdf/pdf_decrypt_error_mapper.dart';
import 'package:pdf_vault/core/pdf/pdf_decrypt_error_type.dart';
import 'package:pdf_vault/core/pdf/pdf_decrypt_result.dart';

class DecryptPdfCore extends PdfDecryptCore {
  const DecryptPdfCore();

  @override
  Future<PdfDecryptResult> decryptPdf({
    required String inputPath,
    required String password,
    required String outputPath,
  }) async {
    final sourceFile = File(inputPath);
    if (!await sourceFile.exists()) {
      return PdfDecryptResult.failure(
        errorType: PdfDecryptErrorType.unreadableInput,
        message: 'The selected PDF no longer exists at the original location.',
      );
    }

    try {
      final isProtected = await DecryptPdf.isPdfProtected(filePath: inputPath);
      if (!isProtected) {
        return PdfDecryptResult.failure(
          errorType: PdfDecryptErrorType.unsupportedDocument,
          message:
              'This PDF is not password protected, so there is nothing to unlock.',
        );
      }

      final decryptedPath = await DecryptPdf.openPdf(
        filePath: inputPath,
        password: password,
      );

      if (decryptedPath == null) {
        return PdfDecryptResult.failure(
          errorType: PdfDecryptErrorType.unknown,
          message: 'The PDF engine did not return an unlocked file.',
        );
      }

      final unlockedFile = File(decryptedPath);
      if (!await unlockedFile.exists()) {
        return PdfDecryptResult.failure(
          errorType: PdfDecryptErrorType.outputWriteFailed,
          outputPath: outputPath,
          message: 'The unlocked PDF could not be prepared for export.',
        );
      }

      final outputFile = File(outputPath);
      await outputFile.parent.create(recursive: true);
      await unlockedFile.copy(outputPath);

      return PdfDecryptResult.success(outputPath: outputPath);
    } on PlatformException catch (error) {
      return PdfDecryptErrorMapper.fromPlatformException(
        error,
        outputPath: outputPath,
      );
    } on FileSystemException {
      return PdfDecryptResult.failure(
        errorType: PdfDecryptErrorType.outputWriteFailed,
        outputPath: outputPath,
        message:
            'The app could not write the unlocked PDF to temporary storage.',
      );
    } catch (_) {
      return PdfDecryptResult.failure(
        errorType: PdfDecryptErrorType.unknown,
        outputPath: outputPath,
        message: 'Unexpected error while unlocking the PDF.',
      );
    }
  }
}
