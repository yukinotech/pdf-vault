import 'package:pdf_vault/core/pdf/pdf_decrypt_result.dart';

abstract class PdfDecryptCore {
  const PdfDecryptCore();

  Future<PdfDecryptResult> decryptPdf({
    required String inputPath,
    required String password,
    required String outputPath,
  });
}
