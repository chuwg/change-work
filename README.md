# Change - 교대근무자를 위한 스마트 스케줄 & 건강코치

[![커피 한 잔 사주기](https://img.shields.io/badge/☕%20커피%20한%20잔%20사주기-카카오페이-FFCD00?style=for-the-badge)](https://qr.kakaopay.com/Ej7lJCKxa)

교대근무자의 스케줄 관리와 건강을 동시에 케어하는 크로스플랫폼 모바일 앱입니다.

---

## 기술 스택

| 항목 | 기술 |
|------|------|
| Framework | Flutter (Dart) |
| 상태관리 | Riverpod |
| 로컬 DB | SQLite (sqflite) |
| 차트 | fl_chart |
| 캘린더 | table_calendar |
| 알림 | flutter_local_notifications |
| 타겟 플랫폼 | iOS (App Store) / Android (Play Store) |

---

## 핵심 기능

### 1. 스케줄 관리
- 교대 패턴 자동 인식 및 3개월치 스케줄 일괄 생성
- 프리셋 패턴 5종 제공 (2교대, 3교대, 격일, 4조2교대, 간호사 3교대)
- 커스텀 패턴 등록 가능
- 컬러코딩 캘린더 (주간/오후/야간/휴무)
- 다음 근무 카운트다운, 휴무까지 D-day

### 2. 수면 품질 트래커
- 취침/기상 시간 기록
- 5단계 수면 품질 평가 (최악~최고)
- 주간/월간 수면 시간 바 차트
- 근무 유형별 평균 수면 시간 비교 분석
- 수면 품질 분포 통계

### 3. 서카디안 리듬 시각화
- 24시간 원형 시계 UI (CustomPainter)
- 현재 체내 리듬 상태 실시간 표시 (각성/활동/졸림/수면/기상)
- 근무 패턴별 맞춤 리듬 가이드 (주간/오후/야간 각각 다른 타임라인)
- 서카디안 건강 점수 (수면 시간 + 품질 + 일관성 기반 산출)
- 권장 취침/기상/낮잠 시간표

### 4. 건강 코치
- 5개 카테고리: 수면, 식사, 운동, 카페인, 빛 관리
- 현재 근무 유형 + 수면 데이터 기반 맞춤 조언 자동 생성
- 우선순위 기반 팁 정렬
- 카테고리 필터링
- 수면 부족 경고 시스템

### 5. 알림 시스템
- 수면 리마인더 (취침 시간 알림)
- 출근 준비 알림 (30분~2시간 전 설정 가능)
- 건강 가이드 알림

### 6. 온보딩
- 3단계 온보딩 플로우 (환영 → 패턴 선택 → 시작)
- 교대 패턴 프리뷰 시각화

---

## 프로젝트 구조

```
change/
├── pubspec.yaml
├── analysis_options.yaml
├── README.md
├── assets/
│   ├── images/
│   └── fonts/
└── lib/
    ├── main.dart                              # 앱 진입점, 시스템 UI 설정
    ├── app.dart                               # MaterialApp, 하단 네비게이션 셸
    │
    ├── config/
    │   ├── theme.dart                         # 다크 테마, 색상 시스템, 그라데이션
    │   └── routes.dart                        # Named route 정의
    │
    ├── models/
    │   ├── shift.dart                         # 근무 데이터 모델
    │   ├── shift_pattern.dart                 # 교대 패턴 모델 (프리셋 5종 포함)
    │   ├── sleep_record.dart                  # 수면 기록 모델
    │   └── health_tip.dart                    # 건강 팁 모델
    │
    ├── providers/
    │   ├── schedule_provider.dart             # 스케줄 상태 관리
    │   ├── sleep_provider.dart                # 수면 기록 상태 관리
    │   └── health_provider.dart               # 건강/서카디안 상태 관리
    │
    ├── services/
    │   ├── database_service.dart              # SQLite CRUD, 인덱싱
    │   ├── ai_health_service.dart             # 건강 조언 생성 엔진
    │   └── notification_service.dart          # 로컬 푸시 알림
    │
    ├── screens/
    │   ├── home/
    │   │   └── home_screen.dart               # 홈 대시보드
    │   ├── calendar/
    │   │   └── calendar_screen.dart           # 근무 캘린더 + 패턴 적용
    │   ├── sleep/
    │   │   ├── sleep_tracker_screen.dart       # 수면 기록 + 주간 차트
    │   │   └── sleep_stats_screen.dart         # 수면 통계 상세
    │   ├── health/
    │   │   ├── health_coach_screen.dart        # 건강 코치 메인
    │   │   └── circadian_screen.dart           # 서카디안 리듬 상세
    │   ├── settings/
    │   │   └── settings_screen.dart            # 설정 (알림, 데이터, 앱 정보)
    │   └── onboarding/
    │       └── onboarding_screen.dart          # 최초 실행 온보딩
    │
    ├── widgets/
    │   ├── shift_card.dart                    # TodayShiftCard, ShiftDayChip
    │   ├── health_tip_card.dart               # 건강 팁 카드 (축약/확장)
    │   ├── sleep_summary_card.dart            # 수면 평균 요약 카드
    │   ├── sleep_chart.dart                   # SleepBarChart, SleepQualityLineChart
    │   └── circadian_mini_clock.dart          # 서카디안 미니 시계 + 점수 링
    │
    └── utils/
        ├── constants.dart                     # 앱 상수 (근무 타입, DB명 등)
        └── helpers.dart                       # 포맷팅, 색상, 아이콘 유틸
```

---

## 파일별 상세

### 설정 파일

| 파일 | 설명 |
|------|------|
| `pubspec.yaml` | Flutter 의존성 및 에셋 설정 |
| `analysis_options.yaml` | Dart 린트 규칙 |

### 진입점

| 파일 | 설명 |
|------|------|
| `lib/main.dart` | ProviderScope 래핑, 화면 방향 고정, 시스템 오버레이 스타일 설정 |
| `lib/app.dart` | MaterialApp 구성, IndexedStack 기반 하단 네비게이션 (홈/캘린더/수면/건강/설정) |

### config/

| 파일 | 설명 |
|------|------|
| `theme.dart` | 미니말 다크 테마 전체 정의. 브랜드 컬러(#6C63FF), 근무별 컬러, 서카디안 컬러, 글래스모피즘 카드 스타일, Material3 컴포넌트 테마 |
| `routes.dart` | 8개 Named route 매핑 |

### models/

| 파일 | 주요 필드 |
|------|----------|
| `shift.dart` | id, date, type(day/evening/night/off), startTime, endTime, note |
| `shift_pattern.dart` | id, name, pattern(List), description. 프리셋: 2교대, 3교대, 격일, 4조2교대, 간호사3교대 |
| `sleep_record.dart` | id, date, bedTime, wakeTime, quality(1-5), shiftType. 자동 계산: duration, durationHours |
| `health_tip.dart` | id, category, title, description, shiftType, timing, priority |

### providers/

| 파일 | 상태 | 주요 액션 |
|------|------|----------|
| `schedule_provider.dart` | shifts Map, activePattern, patternStartDate | loadShiftsForMonth, addShift, applyPattern, removeShift |
| `sleep_provider.dart` | records List, todayRecord, avgByShiftType | loadRecords, addSleepRecord, deleteSleepRecord |
| `health_provider.dart` | currentTips, currentPhase, circadianScore | refreshHealthData |

### services/

| 파일 | 설명 |
|------|------|
| `database_service.dart` | SQLite 싱글턴. shifts/shift_patterns/sleep_records/user_settings 4개 테이블. 날짜 인덱싱. 배치 insert 지원 |
| `ai_health_service.dart` | 근무 유형별 맞춤 건강팁 생성 (수면/식사/운동/카페인/빛). 서카디안 위상 계산. 건강 점수 산출(수면시간+품질+일관성) |
| `notification_service.dart` | iOS/Android 로컬 알림. 수면 리마인더, 근무 시작 알림 스케줄링 |

### screens/

| 파일 | 설명 |
|------|------|
| `home_screen.dart` | 인사말, 오늘 근무 카드, 수면 요약/서카디안 점수 카드, 이번 주 근무 가로 스크롤, 건강 팁 리스트 |
| `calendar_screen.dart` | TableCalendar 월간 뷰, 근무 타입 범례, 패턴 선택 바텀시트, 근무 추가/수정/삭제 |
| `sleep_tracker_screen.dart` | 오늘의 수면 카드, 주간 바차트, 근무별 평균 수면 진행바, 최근 기록 리스트, 수면 기록 바텀시트(시간+품질) |
| `sleep_stats_screen.dart` | 평균 수면/품질/기록수 요약, 30일 추이 차트, 품질 분포 바, 근무 유형별 분석 |
| `health_coach_screen.dart` | 서카디안 배너(탭→상세), 카테고리 필터 칩, 건강 팁 확장 리스트 |
| `circadian_screen.dart` | 24시간 원형 시계(CustomPainter), 건강 점수 진행바, 권장 시간표, 24시간 타임라인 가이드 |
| `settings_screen.dart` | 프로필, 알림 토글 3종, 출근 전 알림 시간 드롭다운, 데이터 내보내기/초기화, 앱 정보 |
| `onboarding_screen.dart` | 3단계 PageView (환영→패턴선택→준비완료), 프로그레스바, 패턴 프리뷰 |

### widgets/

| 파일 | 위젯 | 설명 |
|------|------|------|
| `shift_card.dart` | TodayShiftCard | 오늘 근무 타입 + 시간 + 휴무 D-day |
| | ShiftDayChip | 일별 요일/날짜/근무 칩 (가로 스크롤용) |
| `health_tip_card.dart` | HealthTipCard | 카테고리 아이콘/색상, 축약/확장 모드 지원 |
| `sleep_summary_card.dart` | SleepSummaryCard | 평균 수면 시간 + 별점 품질 |
| `sleep_chart.dart` | SleepBarChart | fl_chart 바차트, 7h 권장선 표시 |
| | SleepQualityLineChart | 품질 추이 라인차트 |
| `circadian_mini_clock.dart` | CircadianMiniClock | 원형 점수 링 + 현재 위상 아이콘/라벨 |

### utils/

| 파일 | 설명 |
|------|------|
| `constants.dart` | 앱 이름, DB 설정, 근무 타입 상수, 기본 근무 시간, 수면 품질/서카디안 위상/건강팁 카테고리 상수 |
| `helpers.dart` | 날짜/시간 포맷, 근무 라벨/색상/아이콘 매핑, 수면 품질 라벨/색상, 인사말 생성, 날짜 비교 |

---

## UI/UX 디자인

- **미니말 다크 테마**: 야간근무 시 눈 보호 최적화
- **브랜드 컬러**: `#6C63FF` (퍼플 블루)
- **근무 컬러 시스템**: 주간(하늘), 오후(오렌지), 야간(보라), 휴무(초록)
- **글래스모피즘 카드**: 반투명 배경 + 미세 테두리
- **그라데이션 액센트**: 주요 카드에 방향성 그라데이션 적용

---

## 빌드 및 실행

```bash
# Flutter SDK 설치 (https://docs.flutter.dev/get-started/install)
# 필요 버전: Dart >=3.2.0, Flutter >=3.16

# 의존성 설치
cd change
flutter pub get

# 개발 실행
flutter run

# iOS 빌드
flutter build ios

# Android 빌드
flutter build apk
```

---

## 수정 내역

### v1.0.0 (2025-02-12) - 최초 생성

#### 프로젝트 초기 설정
- Flutter 프로젝트 구조 생성
- `pubspec.yaml` 의존성 설정 (Riverpod, sqflite, fl_chart, table_calendar 등)
- `analysis_options.yaml` 린트 규칙 설정

#### 데이터 레이어
- `Shift`, `ShiftPattern`, `SleepRecord`, `HealthTip` 4개 데이터 모델 생성
- `DatabaseService` SQLite 서비스 구현 (4개 테이블, 인덱싱, CRUD, 배치 insert)

#### 상태 관리
- `ScheduleProvider` 구현 (월별 로드, 근무 추가/삭제, 패턴 일괄 적용)
- `SleepProvider` 구현 (기록 CRUD, 근무별 평균 집계)
- `HealthProvider` 구현 (건강 팁 생성 트리거, 서카디안 위상/점수 관리)

#### 서비스 레이어
- `AiHealthService` 건강 코치 엔진 구현 (5개 카테고리 × 근무 유형별 맞춤 조언)
- `NotificationService` 로컬 알림 서비스 구현 (iOS/Android)

#### UI 구현
- 미니말 다크 테마 시스템 구축 (`theme.dart`)
- 하단 네비게이션 5탭 셸 구성 (`app.dart`)
- 홈 대시보드 화면 (`home_screen.dart`)
- 근무 캘린더 화면 + 패턴 선택/근무 추가 바텀시트 (`calendar_screen.dart`)
- 수면 트래커 화면 + 기록 입력 바텀시트 (`sleep_tracker_screen.dart`)
- 수면 통계 상세 화면 (`sleep_stats_screen.dart`)
- 건강 코치 화면 + 카테고리 필터 (`health_coach_screen.dart`)
- 서카디안 리듬 상세 화면 + 24시간 시계 (`circadian_screen.dart`)
- 설정 화면 (`settings_screen.dart`)
- 3단계 온보딩 화면 (`onboarding_screen.dart`)

#### 커스텀 위젯
- `TodayShiftCard`, `ShiftDayChip` 근무 표시 위젯
- `HealthTipCard` 건강 팁 카드 (축약/확장)
- `SleepSummaryCard` 수면 요약 카드
- `SleepBarChart`, `SleepQualityLineChart` 수면 차트
- `CircadianMiniClock` 서카디안 미니 시계
- `CircadianClockPainter` 24시간 원형 시계 (CustomPainter)

---

## 향후 계획

- [ ] Apple HealthKit / Google Fit 연동 (자동 수면 데이터 수집)
- [ ] 위젯 지원 (홈 화면 위젯으로 오늘 근무 표시)
- [ ] Apple Watch / WearOS 컴패니언 앱
- [ ] 클라우드 백업 (Firebase/Supabase)
- [ ] 근무 교환 마켓플레이스 (동료 간 근무일 교환)
- [ ] 에너지/무드 트래커 추가
- [ ] 다국어 지원 (영어, 일본어)

---

## 라이선스

Private - All rights reserved.
