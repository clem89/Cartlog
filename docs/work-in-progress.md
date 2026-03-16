# 작업 인수인계 — Work In Progress

> 마지막 업데이트: 2026-03-17
> 다른 환경에서 이 파일을 먼저 읽고 작업을 이어서 진행할 것

---

## 현재 상태

Phase 3 완료. 홈 화면 B안 전환 완료.

다음 작업 미정 — 기능 추가 또는 UX 개선 필요 시 여기에 기록.

---

## 현재 코드 상태

| 파일 | 상태 | 내용 |
|------|------|------|
| `home_screen.dart` | ✅ 완료 | 버튼 3개짜리 B안 홈 |
| `store_view_screen.dart` | ✅ 완료 | 날짜+마트별 그룹 목록 |
| `item_view_screen.dart` | ✅ 완료 | 품목명별 그룹 + 가격 이력 |
| `add_item_screen.dart` | ✅ 완료 | 날짜 선택, 세션 자동 생성 |
| `shopping_repository.dart` | ✅ 완료 | `findOrCreateSession()` 추가 |
| `drift_shopping_repository.dart` | ✅ 완료 | 위 메서드 구현 |

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
