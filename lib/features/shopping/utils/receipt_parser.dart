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
    var lastItemPercentDiscounted = false; // 동일 품목에 퍼센트 할인 중복 방지

    for (final line in lines) {
      // 퍼센트 할인줄: 직전 품목 가격에서 X% 차감 (품목당 1회 제한)
      final percent = _extractPercentDiscount(line);
      if (percent != null) {
        if (!lastItemPercentDiscounted && items.isNotEmpty && items.last.price != null) {
          final last = items.last;
          final discountAmount = (last.price! * percent / 100).round();
          items[items.length - 1] = last.copyWith(
            price: (last.price! - discountAmount).clamp(0, last.price!),
          );
          lastItemPercentDiscounted = true;
        }
        continue;
      }

      // 고정금액 할인줄: 직전 품목 가격에서 차감
      final discount = _extractDiscount(line);
      if (discount != null) {
        if (items.isNotEmpty && items.last.price != null) {
          final last = items.last;
          items[items.length - 1] = last.copyWith(
            price: (last.price! - discount).clamp(0, last.price!),
          );
        }
        continue;
      }

      // 불필요한 줄 스킵
      if (_isNoise(line)) continue;

      final price = _extractPrice(line);
      final name = _extractName(line, price);

      if (name == null || name.isEmpty) continue;
      if (price == null) continue; // 가격 없는 줄은 가게명·헤더·서브아이템으로 간주

      items.add(ParsedReceiptItem(name: name, price: price));
      lastItemPercentDiscounted = false;
    }

    return items;
  }

  /// 퍼센트 할인줄 감지 (예: [할인쿠폰] 50%) → 퍼센트 반환
  static int? _extractPercentDiscount(String line) {
    const discountKeywords = ['할인', '쿠폰', 'L.POINT', 'LPOINT', '포인트'];
    final hasKeyword = discountKeywords.any((kw) => line.contains(kw));
    if (!hasKeyword) return null;

    final match = RegExp(r'\b(\d{1,2})%').firstMatch(line);
    if (match != null) return int.tryParse(match.group(1)!);
    return null;
  }

  /// 할인줄 판별 및 할인액 추출 (양수로 반환)
  /// - 할인 키워드 + 숫자, 또는 음수(-500, -1,000) 포함 라인
  static int? _extractDiscount(String line) {
    const discountKeywords = ['할인', '쿠폰', 'L.POINT', 'LPOINT', '포인트', '적립할인', '즉시할인'];

    final hasKeyword = discountKeywords.any((kw) => line.contains(kw));

    // 할인 키워드 없는 단독 음수 줄은 할인으로 처리하지 않음
    // (영수증 우측 '할인 상세내역' 열의 독립 숫자들이 잘못 적용되는 것 방지)
    if (!hasKeyword) return null;

    // 음수 금액 패턴 (예: -500, -1,000) — 공백/줄시작 뒤의 마이너스만 인정 (카드번호 내 하이픈 제외)
    final negativeMatch = RegExp(r'(?:^|(?<=\s))-\s*(\d{1,3}(?:,\d{3})+|\d+)', multiLine: true).firstMatch(line);
    if (negativeMatch != null) {
      final raw = negativeMatch.group(1)!.replaceAll(',', '');
      return int.tryParse(raw);
    }

    // 할인 키워드가 있고 양수 금액이 있는 경우
    if (hasKeyword) {
      final commaMatch = RegExp(r'\b\d{1,3}(?:,\d{3})+\b').firstMatch(line);
      if (commaMatch != null) {
        return int.tryParse(commaMatch.group(0)!.replaceAll(',', ''));
      }
      final plainMatch = RegExp(r'\b(\d{3,})\b').firstMatch(line);
      if (plainMatch != null) {
        return int.tryParse(plainMatch.group(1)!);
      }
    }

    return null;
  }

  /// 가격을 제거한 품목명 추출
  static String? _extractName(String line, int? price) {
    var name = line
        .replaceAll(RegExp(r'\b\d{1,3}(,\d{3})+\b'), '')
        .replaceAll(RegExp(r'\b\d{4,}\b'), '')
        .replaceAll(RegExp(r'\d+'), '')
        .replaceAll(RegExp(r'[*×xX]+'), '')
        .trim();

    if (name.replaceAll(RegExp(r'[^가-힣a-zA-Z]'), '').isEmpty) return null;

    return name;
  }

  /// 라인에서 가격(마지막 숫자 덩어리) 추출
  /// 8자리 초과(1억 이상)는 카드번호 등으로 간주해 무시
  static int? _extractPrice(String line) {
    // 콤마 포함 금액 우선 (예: 1,500)
    final commaPrice = RegExp(r'\b\d{1,3}(,\d{3})+\b');
    final commaMatches = commaPrice.allMatches(line).toList();
    if (commaMatches.isNotEmpty) {
      final raw = commaMatches.last.group(0)!.replaceAll(',', '');
      final value = int.tryParse(raw);
      if (value != null && value <= 99999999) return value;
    }

    // 3~8자리 숫자 (예: 500, 1500) — 9자리 이상은 카드번호/승인번호로 간주
    final plainPrice = RegExp(r'\b(\d{3,8})\b');
    final plainMatches = plainPrice.allMatches(line).toList();
    if (plainMatches.isNotEmpty) {
      return int.tryParse(plainMatches.last.group(1)!);
    }

    return null;
  }

  /// 합계/소계/세금 등 잡음 라인 판별
  static bool _isNoise(String line) {
    // OCR이 한글 사이에 공백을 삽입하는 경우 대응 (예: "소 계" → "소계")
    final compact = line.replaceAll(' ', '');

    const noiseKeywords = [
      '합계', '소계', '부가세', '카드', '현금', '거스름돈', '받은금액',
      '승인', '가맹점', '사업자', '전화', 'TEL', 'tel',
      '영수증', '감사합니다', '결제금액', '판매금액', '총액', '총계',
      '신한', 'KB', 'NH', 'BC', '롯데카드', '현대카드', '우리카드', '하나카드',
      '마스터', 'MASTER', 'VISA', '비자', '개인신용', '법인',
      '할부', '일시불', '체크',
      '마트', '슈퍼', '편의점', '백화점', '코스트코',
      '주문', '번호', '상품명', '수량',
      '특별시', '광역시', '특별자치도',
    ];

    for (final kw in noiseKeywords) {
      if (line.contains(kw) || compact.contains(kw)) return true;
    }

    // 날짜 패턴 (2024-01-01, 2024/01/01)
    if (RegExp(r'\d{4}[-/]\d{2}[-/]\d{2}').hasMatch(line)) return true;

    // 시간 패턴 (12:34)
    if (RegExp(r'\d{2}:\d{2}').hasMatch(line)) return true;

    // 카드번호 패턴 (4자리 그룹 2개 이상: 1234-5678 or 1234 5678)
    if (RegExp(r'\d{4}[\s\-]\d{4}').hasMatch(line)) return true;

    // 주소 패턴: [한글](로|길|대로|번길) 숫자 로 끝나는 줄
    if (RegExp(r'[가-힣]+(로|길|대로|번길)\s+\d+$').hasMatch(line)) return true;

    // 숫자와 특수문자만인 경우
    if (RegExp(r'^[\d\s\-=*.,#]+$').hasMatch(line)) return true;

    return false;
  }
}
