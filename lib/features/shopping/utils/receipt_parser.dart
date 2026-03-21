import '../domain/models/parsed_receipt_item.dart';

/// 영수증 OCR 텍스트를 파싱해 품목 목록으로 변환
class ReceiptParser {
  /// 줄바꿈 기준으로 각 라인을 순회하며 품목명 + 가격 추출
  static List<ParsedReceiptItem> parse(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final items = <ParsedReceiptItem>[];

    for (final line in lines) {
      // 불필요한 줄 스킵: 숫자만 있거나, 합계/소계/부가세/카드 등 키워드 포함
      if (_isNoise(line)) continue;

      final price = _extractPrice(line);
      final name = _extractName(line, price);

      if (name == null || name.isEmpty) continue;

      items.add(ParsedReceiptItem(name: name, price: price));
    }

    return items;
  }

  /// 가격을 제거한 품목명 추출
  static String? _extractName(String line, int? price) {
    // 가격 패턴 제거 (숫자 + 콤마 조합, 예: 1,500 / 12500)
    var name = line
        .replaceAll(RegExp(r'\b\d{1,3}(,\d{3})+\b'), '')
        .replaceAll(RegExp(r'\b\d{4,}\b'), '')
        .replaceAll(RegExp(r'\d+'), '')
        .replaceAll(RegExp(r'[*×xX]+'), '')
        .trim();

    // 너무 짧거나 특수문자만 남은 경우 무시
    if (name.replaceAll(RegExp(r'[^가-힣a-zA-Z]'), '').length < 2) return null;

    return name;
  }

  /// 라인에서 가격(마지막 숫자 덩어리) 추출
  static int? _extractPrice(String line) {
    // 콤마 포함 금액 우선 (예: 1,500)
    final commaPrice = RegExp(r'\b\d{1,3}(,\d{3})+\b');
    final commaMatches = commaPrice.allMatches(line).toList();
    if (commaMatches.isNotEmpty) {
      final raw = commaMatches.last.group(0)!.replaceAll(',', '');
      return int.tryParse(raw);
    }

    // 4자리 이상 숫자 (예: 1500)
    final plainPrice = RegExp(r'\b(\d{4,})\b');
    final plainMatches = plainPrice.allMatches(line).toList();
    if (plainMatches.isNotEmpty) {
      return int.tryParse(plainMatches.last.group(1)!);
    }

    return null;
  }

  /// 합계/소계/세금 등 잡음 라인 판별
  static bool _isNoise(String line) {
    const noiseKeywords = [
      '합계', '소계', '부가세', '카드', '현금', '거스름돈', '받은금액',
      '승인', '가맹점', '사업자', '전화', 'TEL', 'tel',
      '영수증', '감사합니다', '결제금액', '판매금액', '총액', '총계',
    ];

    for (final kw in noiseKeywords) {
      if (line.contains(kw)) return true;
    }

    // 날짜 패턴 (2024-01-01, 2024/01/01)
    if (RegExp(r'\d{4}[-/]\d{2}[-/]\d{2}').hasMatch(line)) return true;

    // 시간 패턴 (12:34)
    if (RegExp(r'\d{2}:\d{2}').hasMatch(line)) return true;

    // 숫자와 특수문자만인 경우
    if (RegExp(r'^[\d\s\-=*.,#]+$').hasMatch(line)) return true;

    return false;
  }
}
