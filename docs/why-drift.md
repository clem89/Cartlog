# 로컬 DB 선택 근거 — Drift

> 작성일: 2026-03-13

---

## 후보 비교

| 항목 | sqflite | Hive | Drift |
|------|---------|------|-------|
| 기반 | SQLite (raw) | NoSQL (key-value) | SQLite (ORM) |
| 타입 안전성 | ❌ 문자열 쿼리 | △ 제한적 | ✅ 완전한 타입세이프 |
| 관계형 데이터 | △ 가능하지만 번거로움 | ❌ 부적합 | ✅ 적합 |
| 코드 자동생성 | ❌ | ❌ | ✅ `build_runner` |
| 마이그레이션 지원 | ❌ 직접 구현 | ❌ | ✅ 내장 |
| 반응형 쿼리 (Stream) | ❌ | △ | ✅ 내장 |
| 러닝 커브 | 낮음 | 낮음 | 중간 |
| Flutter 공식 지원 | ✅ | ❌ | ❌ (but 커뮤니티 활발) |

---

## sqflite를 선택하지 않은 이유

- SQL 쿼리를 **문자열로 직접 작성**해야 함 → 오타, 타입 오류를 런타임에서야 발견
- 테이블 간 관계(join) 처리나 마이그레이션을 **모두 수동으로 구현**해야 함
- 코드가 길어질수록 유지보수가 어려워짐
- 기능 면에서 Drift가 sqflite를 내부적으로 그대로 사용하면서 그 위에 편의 기능을 얹은 구조이므로, sqflite를 쓸 이유가 없음

## Hive를 선택하지 않은 이유

- Cartlog의 핵심 데이터(쇼핑 세션 ↔ 품목)는 **1:N 관계형 구조**
  - `ShoppingSession`이 여러 `Item`을 가짐
  - Hive는 이런 관계를 표현하기에 부적합 (key-value 기반)
- 복잡한 조회(날짜별 정렬, 품목별 집계 등)를 Hive로 구현하면 코드가 비대해짐
- NoSQL은 구조가 유연한 반면 이 앱은 스키마가 명확하게 고정되어 있음

---

## Drift를 선택한 이유

### 1. 타입세이프 쿼리
```dart
// 컴파일 타임에 오류를 잡아냄
final items = await (select(itemTable)
  ..where((t) => t.sessionId.equals(sessionId))
  ..orderBy([(t) => OrderingTerm.desc(t.price)]))
  .get();
```
문자열이 아닌 Dart 코드로 쿼리를 작성하므로 IDE 자동완성과 컴파일 타임 검증이 가능.

### 2. 관계형 데이터에 최적
쇼핑 세션과 품목 간의 1:N 관계를 자연스럽게 표현하고 join 쿼리도 간결하게 작성 가능.

### 3. 마이그레이션 내장
앱 업데이트로 스키마가 변경될 때 Drift의 마이그레이션 API로 안전하게 처리 가능.
sqflite는 이를 직접 구현해야 함.

### 4. 반응형 쿼리 (Stream)
```dart
// DB가 변경되면 UI가 자동으로 갱신됨
Stream<List<Item>> watchItems(int sessionId) =>
  (select(itemTable)..where((t) => t.sessionId.equals(sessionId))).watch();
```
`watch()`로 Stream을 반환받아 `StreamBuilder`와 바로 연동 가능.

### 5. Firestore 전환 대비 (Repository 패턴)
추상 Repository 인터페이스를 두면, 추후 Firestore로 전환 시 **Drift 구현체만 교체**하면 되어 상위 레이어 코드 변경 최소화.

```
domain/repositories/shopping_repository.dart  ← 인터페이스 (불변)
data/repositories/drift_shopping_repository.dart  ← 1단계 구현체
data/repositories/firestore_shopping_repository.dart  ← 2단계 구현체 (추후)
```

---

## 결론

Cartlog의 데이터 구조는 관계형이고 스키마가 명확하므로 Drift가 가장 적합.
개발 생산성(타입세이프, 자동완성)과 유지보수성(마이그레이션, 반응형) 모두 우위.
