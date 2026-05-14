import 'dart:io';

import 'package:decrypt_pdf/decrypt_pdf.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_vault/core/pdf/decrypt_pdf_core.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const inputPath = String.fromEnvironment('SMOKE_INPUT_PDF', defaultValue: '');
  const passwordValue = String.fromEnvironment(
    'SMOKE_PASSWORD',
    defaultValue: '',
  );

  testWidgets('core decrypts demo PDF and writes unlocked output', (
    tester,
  ) async {
    if (inputPath.isEmpty || passwordValue.isEmpty) {
      return;
    }

    final inputFile = File(inputPath);
    expect(
      await inputFile.exists(),
      isTrue,
      reason: 'SMOKE_INPUT_PDF does not exist',
    );

    final password = passwordValue.trim();
    expect(password.isNotEmpty, isTrue, reason: 'SMOKE_PASSWORD is empty');
    final outputPath = p.join(inputFile.parent.path, 'output_unlocked.pdf');

    final core = DecryptPdfCore();
    final result = await core.decryptPdf(
      inputPath: inputFile.path,
      password: password,
      outputPath: outputPath,
    );

    expect(result.isSuccess, isTrue, reason: result.message);
    expect(result.outputPath, isNotNull);

    final outFile = File(outputPath);
    expect(await outFile.exists(), isTrue);
    expect(await outFile.length(), greaterThan(0));

    final isStillProtected = await DecryptPdf.isPdfProtected(
      filePath: outputPath,
    );
    expect(isStillProtected, isFalse);
  });
}
