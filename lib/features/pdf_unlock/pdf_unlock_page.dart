import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf_vault/core/pdf/pdf_decrypt_core.dart';
import 'package:pdf_vault/core/pdf/pdf_decrypt_error_type.dart';
import 'package:pdf_vault/core/pdf/pdf_decrypt_result.dart';

class PdfUnlockPage extends StatefulWidget {
  const PdfUnlockPage({super.key, required this.core});

  final PdfDecryptCore core;

  @override
  State<PdfUnlockPage> createState() => _PdfUnlockPageState();
}

class _PdfUnlockPageState extends State<PdfUnlockPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fileNameController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _unlockFormKey = GlobalKey();
  final FocusNode _passwordFocusNode = FocusNode();

  String? _selectedPdfPath;
  bool _isUnlocking = false;
  bool _obscurePassword = true;
  PdfDecryptResult? _result;
  String? _savedFilePath;
  _AppLanguage _language = _AppLanguage.zh;

  bool get _isZh => _language == _AppLanguage.zh;

  String _t({required String zh, required String en}) => _isZh ? zh : en;

  @override
  void dispose() {
    _passwordController.dispose();
    _fileNameController.dispose();
    _scrollController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      allowMultiple: false,
      withData: false,
    );

    final selectedPath = picked?.files.single.path;
    if (selectedPath == null) {
      return;
    }

    setState(() {
      _selectedPdfPath = selectedPath;
      _savedFilePath = null;
      _result = null;
      _fileNameController.text = _buildSuggestedFileName(selectedPath);
    });
    _focusUnlockForm();
  }

  Future<void> _unlockPdf() async {
    final inputPath = _selectedPdfPath;
    if (inputPath == null || inputPath.isEmpty) {
      _showSnackBar(
        _t(
          zh: '请先选择一个受密码保护的 PDF 文件。',
          en: 'Pick a password-protected PDF first.',
        ),
      );
      return;
    }

    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      _showSnackBar(
        _t(
          zh: '请先输入 PDF 密码再解锁。',
          en: 'Enter the PDF password before unlocking.',
        ),
      );
      return;
    }

    final suggestedName = _sanitizeFileName(
      _fileNameController.text,
      inputPath,
    );
    final tempDir = await getTemporaryDirectory();
    final tempOutputPath = path.join(tempDir.path, suggestedName);

    setState(() {
      _isUnlocking = true;
      _savedFilePath = null;
      _result = null;
    });

    final unlockResult = await widget.core.decryptPdf(
      inputPath: inputPath,
      password: password,
      outputPath: tempOutputPath,
    );

    if (!mounted) {
      return;
    }

    if (!unlockResult.isSuccess || unlockResult.outputPath == null) {
      setState(() {
        _isUnlocking = false;
        _result = unlockResult;
      });
      return;
    }

    final exportedPath = await _exportUnlockedPdf(
      sourcePath: unlockResult.outputPath!,
      suggestedName: suggestedName,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isUnlocking = false;
      _savedFilePath = exportedPath;
      _result = exportedPath == null
          ? PdfDecryptResult.failure(
              errorType: PdfDecryptErrorType.cancelled,
              outputPath: unlockResult.outputPath,
              message: _t(
                zh: '已完成解锁，但你取消了保存到设备。',
                en: 'The unlocked PDF is ready, but saving to your device was cancelled.',
              ),
            )
          : PdfDecryptResult.success(
              outputPath: exportedPath,
              message: _t(
                zh: '解锁后的 PDF 已成功保存。',
                en: 'Unlocked PDF saved successfully.',
              ),
            );
    });
  }

  Future<String?> _exportUnlockedPdf({
    required String sourcePath,
    required String suggestedName,
  }) async {
    try {
      return await FlutterFileDialog.saveFile(
        params: SaveFileDialogParams(
          sourceFilePath: sourcePath,
          fileName: suggestedName,
          mimeTypesFilter: const ['application/pdf'],
        ),
      );
    } catch (_) {
      return null;
    } finally {
      final tempFile = File(sourcePath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  String _buildSuggestedFileName(String inputPath) {
    final base = path.basenameWithoutExtension(inputPath);
    return '${base}_unlocked.pdf';
  }

  String _sanitizeFileName(String rawValue, String inputPath) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      return _buildSuggestedFileName(inputPath);
    }

    return trimmed.toLowerCase().endsWith('.pdf') ? trimmed : '$trimmed.pdf';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _focusUnlockForm() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final formContext = _unlockFormKey.currentContext;
      if (formContext != null) {
        await Scrollable.ensureVisible(
          formContext,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          alignment: 0.12,
        );
      }
      if (mounted) {
        _passwordFocusNode.requestFocus();
      }
    });
  }

  Future<void> _openSettingsPanel() async {
    final next = await showModalBottomSheet<_AppLanguage>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t(zh: '设置', en: 'Settings'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _t(zh: '语言', en: 'Language'),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.language_rounded),
                title: const Text('中文'),
                trailing: _language == _AppLanguage.zh
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.of(context).pop(_AppLanguage.zh),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.language_rounded),
                title: const Text('English'),
                trailing: _language == _AppLanguage.en
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.of(context).pop(_AppLanguage.en),
              ),
            ],
          ),
        );
      },
    );

    if (next != null && next != _language) {
      setState(() {
        _language = next;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFile = _selectedPdfPath != null;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              const Color(0xFFF8EADB),
              const Color(0xFFE2F0F0),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                children: [
                  _HeroHeader(
                    onPickPdf: _pickPdf,
                    onOpenSettings: _openSettingsPanel,
                    hasFile: hasFile,
                    selectedPdfPath: _selectedPdfPath,
                    language: _language,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    key: _unlockFormKey,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t(zh: '解锁流程', en: 'Unlock Flow'),
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _t(
                              zh: '选择受密码保护的 PDF，输入正确密码，然后导出一份无密码副本。',
                              en: 'Choose an encrypted PDF, confirm the password, and export a clean copy with no password attached.',
                            ),
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 24),
                          _SectionLabel(
                            title: _t(zh: '已选 PDF', en: 'Selected PDF'),
                          ),
                          const SizedBox(height: 12),
                          _FileSummaryCard(
                            pathValue: _selectedPdfPath,
                            language: _language,
                          ),
                          const SizedBox(height: 20),
                          _SectionLabel(
                            title: _t(zh: '密码', en: 'Password'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            obscureText: _obscurePassword,
                            enableSuggestions: false,
                            autocorrect: false,
                            decoration: InputDecoration(
                              hintText: _t(
                                zh: '输入你已知的 PDF 密码',
                                en: 'Enter the known PDF password',
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _SectionLabel(
                            title: _t(
                              zh: '建议导出文件名',
                              en: 'Suggested Export Name',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _fileNameController,
                            decoration: InputDecoration(
                              hintText: _t(
                                zh: '例如：example_unlocked.pdf',
                                en: 'example_unlocked.pdf',
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isUnlocking ? null : _unlockPdf,
                              icon: _isUnlocking
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                      ),
                                    )
                                  : const Icon(Icons.lock_open_rounded),
                              label: Text(
                                _isUnlocking
                                    ? _t(zh: '解锁中...', en: 'Unlocking...')
                                    : _t(
                                        zh: '解锁并保存 PDF',
                                        en: 'Unlock And Save PDF',
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ResultCard(
                    result: _result,
                    savedFilePath: _savedFilePath,
                    language: _language,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.onPickPdf,
    required this.onOpenSettings,
    required this.hasFile,
    required this.selectedPdfPath,
    required this.language,
  });

  final VoidCallback onPickPdf;
  final VoidCallback onOpenSettings;
  final bool hasFile;
  final String? selectedPdfPath;
  final _AppLanguage language;

  bool get _isZh => language == _AppLanguage.zh;
  String _t({required String zh, required String en}) => _isZh ? zh : en;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'PDF Vault',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  onPressed: onOpenSettings,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.settings_rounded),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              _t(
                zh: '把加密 PDF 变成可直接使用的无密码副本。',
                en: 'Turn a locked PDF into a clean copy you can keep.',
              ),
              style: theme.textTheme.headlineLarge?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _t(
                zh: '面向 Android 和 iOS 的单文件解锁工具。选择文件、输入已知密码，然后导出无密码 PDF。',
                en: 'Built for single-file unlock jobs on Android and iOS. Pick the file, enter the known password, and export a password-free PDF.',
              ),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.88),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: onPickPdf,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: theme.colorScheme.primary,
                  ),
                  icon: const Icon(Icons.file_open_rounded),
                  label: Text(
                    hasFile
                        ? _t(zh: '重新选择 PDF', en: 'Replace PDF')
                        : _t(zh: '选择 PDF', en: 'Choose PDF'),
                  ),
                ),
                _InfoChip(
                  icon: Icons.verified_user_outlined,
                  label: _t(zh: '需要已知密码', en: 'Known password required'),
                ),
                _InfoChip(
                  icon: Icons.phone_android_rounded,
                  label: _t(zh: 'Android + iOS', en: 'Android + iOS'),
                ),
              ],
            ),
            if (selectedPdfPath != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  _t(
                    zh: '已选择：${path.basename(selectedPdfPath!)}',
                    en: 'Selected: ${path.basename(selectedPdfPath!)}',
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.labelLarge),
        ),
      ],
    );
  }
}

class _FileSummaryCard extends StatelessWidget {
  const _FileSummaryCard({required this.pathValue, required this.language});

  final String? pathValue;
  final _AppLanguage language;

  bool get _isZh => language == _AppLanguage.zh;
  String _t({required String zh, required String en}) => _isZh ? zh : en;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = pathValue != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.55,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: hasValue
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  path.basename(pathValue!),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(pathValue!, style: theme.textTheme.bodyMedium),
              ],
            )
          : Text(
              _t(zh: '尚未选择 PDF 文件。', en: 'No PDF selected yet.'),
              style: theme.textTheme.bodyMedium,
            ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.result,
    required this.savedFilePath,
    required this.language,
  });

  final PdfDecryptResult? result;
  final String? savedFilePath;
  final _AppLanguage language;

  bool get _isZh => language == _AppLanguage.zh;
  String _t({required String zh, required String en}) => _isZh ? zh : en;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (result == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _t(
              zh: '每次解锁后的结果和校验反馈会显示在这里。',
              en: 'Results and validation feedback will appear here after each unlock attempt.',
            ),
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    final success = result!.isSuccess;
    final tone = success
        ? theme.colorScheme.primary
        : result!.errorType == PdfDecryptErrorType.cancelled
        ? theme.colorScheme.secondary
        : theme.colorScheme.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  success
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                  color: tone,
                ),
                const SizedBox(width: 10),
                Text(
                  success
                      ? _t(zh: '解锁完成', en: 'Unlock Complete')
                      : _t(zh: '解锁中断', en: 'Unlock Stopped'),
                  style: theme.textTheme.headlineSmall?.copyWith(color: tone),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(result!.message, style: theme.textTheme.bodyLarge),
            if (savedFilePath != null) ...[
              const SizedBox(height: 14),
              Text(savedFilePath!, style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}

enum _AppLanguage { zh, en }
