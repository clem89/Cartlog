# 작업 인수인계 — Work In Progress

> 마지막 업데이트: 2026-03-15
> 다른 환경에서 이 파일을 먼저 읽고 작업을 이어서 진행할 것

---

## 현재 상태

Phase 3 진행 중. 홈 화면 UX를 B안으로 전환하는 작업 직전에 멈춘 상태.

---

## 다음에 바로 해야 할 작업 (순서대로)

### Step 1. `findOrCreateSession()` 백엔드 구현
- `domain/repositories/shopping_repository.dart` 에 메서드 추가
  ```dart
  Future<int> findOrCreateSession(DateTime date, String storeName);
  ```
- `data/repositories/drift_shopping_repository.dart` 에 구현
  - 같은 날(년월일) + 같은 storeName인 세션이 있으면 해당 id 반환
  - 없으면 새 세션 생성 후 id 반환

### Step 2. 홈 화면 재작성 (`home_screen.dart`)
버튼 3개짜리 홈:
```
┌─────────────────────────────┐
│ Cartlog                     │
├─────────────────────────────┤
│                             │
│  [🏪 마트별 보기]           │
│  [📦 품목별 보기]           │
│  [+ 품목 추가하기]          │
│                             │
└─────────────────────────────┘
```

### Step 3. 마트별 보기 화면 (신규)
- 날짜+구입처 기준 그룹핑
- 각 그룹에 품목 목록 + 합계 표시
```
2026-03-15 · 이마트
  사과      3,000원 / 3개
  소고기   15,000원 / 500g
  총 18,000원 · 2개 품목
```

### Step 4. 품목별 보기 화면 (신규)
- 품목명 기준 그룹핑
- 구입처별 가격 비교 가능
```
사과
  이마트 · 2026-03-15   3,000원
  홈플러스 · 2026-03-10  2,500원

소고기
  이마트 · 2026-03-15  15,000원
```

### Step 5. `add_item_screen.dart` 수정
- `sessionId` 파라미터 제거
- 날짜 선택 필드 추가 (기본값: 오늘)
- 저장 시 `findOrCreateSession(date, store)` 호출 후 품목 저장

### Step 6. 불필요한 화면 제거
- `add_session_screen.dart` 삭제
- `session_detail_screen.dart` 삭제

---

## 현재 코드 상태 (오늘 작업 완료분)

| 파일 | 상태 | 내용 |
|------|------|------|
| `add_item_screen.dart` | ✅ 완료 | 카테고리 직접 입력, 히스토리 탭 시 이름+카테고리 자동입력 |
| `shopping_repository.dart` | ✅ 완료 | `watchAllItems()`, `watchStoreHistory()` 추가 |
| `drift_shopping_repository.dart` | ✅ 완료 | 위 메서드 구현 |
| `shopping_provider.dart` | ✅ 완료 | FutureProvider → StreamProvider 변경 |
| `item_category.dart` | ✅ 완료 | `fromLabel()` nullable 반환으로 수정 |
| `home_screen.dart` | ⏳ 재작성 필요 | B안 홈으로 전환 필요 |
| `add_session_screen.dart` | ⏳ 삭제 예정 | B안 전환 후 불필요 |
| `session_detail_screen.dart` | ⏳ 삭제 예정 | B안 전환 후 불필요 |

---

## 환경 세팅 참고

새 환경에서 클론 후 아래 순서로 실행:
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d windows   # 또는 -d emulator-xxxx
```

Windows에서 실행 시 Developer Mode 활성화 필요:
```
start ms-settings:developers
```
