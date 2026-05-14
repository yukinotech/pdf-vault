import 'package:pdf_vault/core/pdf/pdf_decrypt_error_type.dart';

class PdfDecryptResult {
  const PdfDecryptResult._({
    required this.isSuccess,
    this.outputPath,
    this.errorType,
    required this.message,
  });

  final bool isSuccess;
  final String? outputPath;
  final PdfDecryptErrorType? errorType;
  final String message;

  factory PdfDecryptResult.success({
    required String outputPath,
    String message = 'Unlocked PDF is ready to export.',
  }) {
    return PdfDecryptResult._(
      isSuccess: true,
      outputPath: outputPath,
      message: message,
    );
  }

  factory PdfDecryptResult.failure({
    required PdfDecryptErrorType errorType,
    required String message,
    String? outputPath,
  }) {
    return PdfDecryptResult._(
      isSuccess: false,
      outputPath: outputPath,
      errorType: errorType,
      message: message,
    );
  }
}
