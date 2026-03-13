# 아키텍처 개념 정리

> 작성일: 2026-03-13

---

## 1. 로컬 DB (SQLite/Drift)란?

### 저장 위치
외부 서버 없이 **디바이스 내부**에 `.db` 파일로 저장.

```
기존 방식 (Redis/MSSQL)
앱 → 네트워크 → 외부 DB 서버 → 저장

Drift (SQLite)
앱 → 디바이스 내부 파일시스템 → 저장 (네트워크 불필요)
```

Android 기준 실제 파일 경로:
```
/data/data/com.clem.cartlog/app_flutter/cartlog.db
```
앱 전용 샌드박스 영역 — 다른 앱 접근 불가, 앱 삭제 시 같이 삭제.

---

## 2. 로컬 파일(json/txt) vs SQLite

| 항목 | 로컬 파일 | SQLite |
|------|-----------|--------|
| 조회 성능 | 전체 로드 후 필터 | 인덱스로 빠른 검색 |
| 복잡한 쿼리 | 코드로 직접 구현 | SQL로 간단 처리 |
| 정렬/집계 | 직접 구현 | 기본 제공 |
| 동시 접근 안전성 | 없음 | 보장 |
| 데이터 무결성 | 없음 | FK, 제약조건 지원 |
| 메모리 사용 | 파일 전체 로드 | 필요한 것만 로드 |

**실질적인 차이 예시:**
```
"지난달 이마트에서 산 것 중 가격순으로 보여줘"

로컬 파일: 전체 로드 → 날짜 필터 → 마트 필터 → 정렬 (직접 구현)
SQLite:    SELECT * FROM items WHERE ... ORDER BY price  (한 줄)
```

---

## 3. Repository 패턴

### 개념
UI가 "데이터가 어디서 오는지" 모르게 중간에서 가려주는 레이어.

```
UI (화면)
  ↕  "데이터 줘 / 저장해"
ShoppingRepository (인터페이스)  ← UI는 이것만 앎
  ↕
DriftShoppingRepository          ← 실제 SQLite 접근 (구현체)
  ↕
SQLite (.db 파일)
```

### 기존 경험과 비교 (MSSQL + 프로시저)
```
기존: UI → sp_GetSessions() 호출 → DB
현재: UI → repository.getSessions() 호출 → Drift → SQLite
```

**공통점:**
- 호출하는 쪽은 내부 구현을 모름
- 내부 구현이 바뀌어도 호출부 코드는 그대로
- DB 접근 로직이 한 곳에 집중

**차이점:**
- 프로시저: DB 서버 안에 로직 존재
- Repository: 앱 코드 안에 로직 존재

### 이 앱에서의 실질적 이점 (Firestore 전환 대비)
```
1단계 (현재)             2단계 (퍼블릭 배포)
─────────────            ─────────────────
ShoppingRepository  →    ShoppingRepository  (인터페이스 동일)
DriftRepository     →    FirestoreRepository (구현체만 교체)
로컬 SQLite         →    Firebase 서버
```
UI 코드는 한 줄도 수정하지 않고 저장소 전환 가능.

---

## 4. 전체 데이터 흐름 요약

```
[화면/UI]
    ↕ repository.getSessions()
[ShoppingRepository 인터페이스]
    ↕ (DriftShoppingRepository 구현)
[AppDatabase - Drift]
    ↕ (자동생성된 .g.dart)
[SQLite - cartlog.db 파일]
    ↕
[디바이스 내부 저장소]
```
