import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../utils/receipt_parser.dart';
import 'receipt_review_screen.dart';

class ReceiptScanScreen extends StatefulWidget {
  const ReceiptScanScreen({super.key});

  @override
  State<ReceiptScanScreen> createState() => _ReceiptScanScreenState();
}

class _ReceiptScanScreenState extends State<ReceiptScanScreen> {
  bool _isProcessing = false;
  String? _lastOcrText;

  Future<void> _pickAndProcess(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 90);
    if (file == null) return;
    if (!mounted) return;

    setState(() => _isProcessing = true);

    try {
      final inputImage = InputImage.fromFilePath(file.path);
      final recognizer = TextRecognizer(script: TextRecognitionScript.korean);
      final result = await recognizer.processImage(inputImage);
      await recognizer.close();
      // ignore: avoid_print
      print('=== OCR RAW ===\n${result.text}');

      setState(() => _lastOcrText = result.text);

      final items = ReceiptParser.parse(result.text);

      if (!mounted) return;

      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('품목을 인식하지 못했습니다. 다시 시도해주세요.')),
        );
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReceiptReviewScreen(parsedItems: items),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _copyOcrText() async {
    if (_lastOcrText == null) return;
    await Clipboard.setData(ClipboardData(text: _lastOcrText!));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OCR 텍스트가 클립보드에 복사됐습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('영수증 등록'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('영수증을 인식하는 중...'),
                ],
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.receipt_long_outlined,
                        size: 80, color: Colors.grey),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: () => _pickAndProcess(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('카메라로 촬영'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: () => _pickAndProcess(ImageSource.gallery),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_library_outlined),
                          SizedBox(width: 8),
                          Text('갤러리에서 선택'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      '영수증이 선명하게 찍힐수록 인식률이 높아집니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    if (_lastOcrText != null) ...[
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: _copyOcrText,
                        icon: const Icon(Icons.copy_outlined, size: 16),
                        label: const Text('OCR 텍스트 복사'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
