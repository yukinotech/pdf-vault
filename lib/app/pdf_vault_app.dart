import 'package:flutter/material.dart';
import 'package:pdf_vault/app/pdf_vault_theme.dart';
import 'package:pdf_vault/core/pdf/decrypt_pdf_core.dart';
import 'package:pdf_vault/features/pdf_unlock/pdf_unlock_page.dart';

class PdfVaultApp extends StatelessWidget {
  const PdfVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Vault',
      debugShowCheckedModeBanner: false,
      theme: buildPdfVaultTheme(),
      home: const PdfUnlockPage(core: DecryptPdfCore()),
    );
  }
}
