import 'package:flutter_test/flutter_test.dart';
import 'package:cartlog/features/shopping/utils/receipt_parser.dart';

void main() {
  group('ReceiptParser - 기본 파싱', () {
    test('품목명과 가격 추출', () {
      const text = '''
아메리카노       1     4,500
카페라떼         2     9,000
크로와상         1     3,500
''';
      final items = ReceiptParser.parse(text);
      expect(items.length, 3);
      expect(items[0].name, contains('아메리카노'));
      expect(items[0].price, 4500);
      expect(items[1].price, 9000);
      expect(items[2].price, 3500);
    });

    test('가격 있는 품목만 추출', () {
      const text = '참이슬후레쉬    1    3,500\n합계 15,000';
      final items = ReceiptParser.parse(text);
      expect(items.length, 1);
      expect(items[0].name, contains('참이슬'));
      expect(items[0].price, 3500);
    });
  });

  group('ReceiptParser - 할인 적용 (롯데마트 등)', () {
    test('L.POINT 할인 차감', () {
      const text = '''
아메리카노       1     4,500
L.POINT할인           -500
카페라떼         2     9,000
''';
      final items = ReceiptParser.parse(text);
      expect(items.length, 2);
      expect(items[0].price, 4000); // 4,500 - 500
      expect(items[1].price, 9000); // 할인 없음
    });

    test('쿠폰 할인 차감', () {
      const text = '''
샴푸             1    12,900
쿠폰할인               3,000
치약             2     5,800
''';
      final items = ReceiptParser.parse(text);
      expect(items.length, 2);
      expect(items[0].price, 9900); // 12,900 - 3,000
      expect(items[1].price, 5800);
    });

    test('음수 표기 할인 차감', () {
      const text = '''
과자             1     2,500
즉시할인          -500
음료             1     1,800
''';
      final items = ReceiptParser.parse(text);
      expect(items.length, 2);
      expect(items[0].price, 2000);
    });

    test('할인이 가격보다 크면 0으로 처리', () {
      const text = '''
증정품           1     1,000
할인            -2,000
''';
      final items = ReceiptParser.parse(text);
      expect(items[0].price, 0);
    });
  });

  group('ReceiptParser - 노이즈 필터', () {
    test('합계/소계 라인 제외', () {
      const text = '''
사이다            1     1,500
합계                    1,500
소계                    1,500
부가세                    136
''';
      final items = ReceiptParser.parse(text);
      expect(items.length, 1);
    });

    test('카드 결제 정보 제외', () {
      const text = '''
라면              1     1,200
카드승인번호: 12345678
신한카드 1234-5678-****-9012
결제금액          1,200
''';
      final items = ReceiptParser.parse(text);
      expect(items.length, 1);
      expect(items[0].price, 1200);
    });

    test('카드번호(9자리 이상 숫자) 가격으로 인식 안 함', () {
      const text = '''
두부              1     2,500
123456789012
''';
      final items = ReceiptParser.parse(text);
      expect(items.length, 1);
      expect(items[0].price, 2500);
    });

    test('날짜/시간 라인 제외', () {
      const text = '''
2024-03-22 14:30
물               1       500
14:30
''';
      final items = ReceiptParser.parse(text);
      expect(items.length, 1);
    });

    test('감사합니다 등 인사말 제외', () {
      const text = '''
과자             1     1,500
감사합니다
영수증번호 12345
''';
      final items = ReceiptParser.parse(text);
      expect(items.length, 1);
    });
  });

  group('ReceiptParser - 실제 영수증 시나리오', () {
    test('롯데마트 스타일 영수증', () {
      const text = '''
2024/03/22 14:30
롯데마트 잠실점
사업자번호 123-45-67890

콘푸로스트        1    4,580
L.POINT할인          -500
서울우유 1L        2    5,960
쿠폰할인          -1,000
참치캔 고추        3    7,470
두부 찌개용        1    2,980

소계                  19,490
부가세                 1,772
합계                  19,490
카드결제              19,490
신한카드 1234-5678-****-1234
승인번호 98765432
감사합니다
''';
      final items = ReceiptParser.parse(text);
      expect(items.length, 4);
      expect(items[0].name, contains('콘푸로스트'));
      expect(items[0].price, 4080); // 4,580 - 500
      expect(items[1].name, contains('우유'));
      expect(items[1].price, 4960); // 5,960 - 1,000
      expect(items[2].price, 7470);
      expect(items[3].price, 2980);
    });
  });

  group('ReceiptParser - 롯데리아 스타일 영수증', () {
    test('상품명/수량/금액 헤더줄 제외', () {
      const text = '''
롯데리아 횡성읍점
주문번호 017-00-07631
2021-11-21 13:05

상품명            수량    금액
---------------------------
불고기버거세트      1    5,500
 코카콜라M
 감자튀김M
새우버거           1    2,700
치즈스틱           2    4,000
---------------------------
소계                     12,200
부가세                     1,109
합계                     12,200
카드                     12,200
감사합니다
''';
      final items = ReceiptParser.parse(text);
      // 상품명/수량/금액 헤더, 세트 서브아이템, 소계/합계 등 제외
      expect(items.length, 3);
      expect(items[0].name, contains('불고기버거'));
      expect(items[0].price, 5500);
      expect(items[1].name, contains('새우버거'));
      expect(items[1].price, 2700);
      expect(items[2].name, contains('치즈스틱'));
      expect(items[2].price, 4000);
    });
  });
}
