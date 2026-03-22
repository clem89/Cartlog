// OCR 샘플 텍스트를 파서에 돌려보는 개발용 테스트
// 실행: flutter test test/ocr_sample_test.dart --reporter expanded
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:cartlog/features/shopping/utils/receipt_parser.dart';

void main() {
  test('ocr_sample.txt 파서 결과 출력', () {
    final file = File('test/ocr_sample.txt');
    if (!file.existsSync()) {
      printOnFailure('test/ocr_sample.txt 파일이 없습니다.');
      return;
    }

    final text = file.readAsStringSync();
    final items = ReceiptParser.parse(text);

    // ignore: avoid_print
    print('\n=== 파서 결과 (${items.length}개) ===');
    for (final item in items) {
      final price = item.price != null
          ? '${item.price!.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원'
          : '가격 미인식';
      // ignore: avoid_print
      print('  ${item.name.trim()} — $price');
    }

    expect(items, isNotEmpty);
  });
}
