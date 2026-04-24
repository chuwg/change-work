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
| 건강 데이터 | HealthKit (health 패키지) |
| 위젯 | WidgetKit (iOS), AppWidget (Android) |
| 공유 | share_plus |
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
- **HealthKit/Health Connect 자동 동기화** (Apple Watch 우선, 수동 입력 자동 대체)
- **백그라운드 자동 동기화**: 앱을 열지 않아도 HealthKit background delivery로 수면 데이터 자동 수집
- 취침/기상 시간 기록 (수동 입력은 백업 수단)
- Apple Watch 수면 단계 데이터 연동 (깊은 수면, 얕은 수면, REM, 각성)
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

### 4. 건강 코치 (데이터 기반 개인화)
- 6개 카테고리: 수면, 식사, 운동, 카페인, 빛 관리, 에너지
- **실제 수면/활동 데이터 기반 개인화 인사이트**
  - 어제 수면 분석 ("어제 23:30~05:45에 6.3시간 수면 - 부족")
  - 취침 시간 불규칙 경고 / 수면 부채 누적 알림
  - 활동량 부족 감지 (걸음 수 기반)
  - 심박수 이상 감지 / 에너지 저하 경고
- **시간 인식 컨텍스트 팁**: 취침 2시간 전 알림, 기상 직후 가이드, 근무 중반 에너지 관리
- 근무 유형별 맞춤 조언 (정적 가이드)
- 우선순위 기반 정렬 (데이터 인사이트 > 시간 컨텍스트 > 일반 가이드)

### 5. 스마트 알림 시스템
- **근무 연동 수면 알림**: 내일 근무 타입에 따라 취침 시간 자동 조정 (주간 22시, 야간 14시 등)
- **카페인 마감 알림**: 추천 취침 6시간 전 자동 알림
- **야간근무 사전 알림**: 야간 전날 낮잠 추천 (12:00 발송)
- 출발 알림 (이동 시간 직접 입력, "지금 출발하세요!" 메시지)
- 근무 알림 최대 7개 선(先)등록 (앱 미실행 상태에서도 1주일 보장)
- **주간 리포트 알림**: 매주 일요일 20:00에 주간 리포트 알림
- 오늘의 한 마디 (교대근무자 동기부여 메시지, 시간 자유 설정)

### 6. 주간 리포트
- 주간 종합 등급 (A+~D, 수면·에너지·수면부채 기반)
- 근무 패턴 분석 (근무 타입별 일수 시각화)
- 수면 분석: 평균/질/부채, 요일별 바 차트, 최고/최저 수면일
- 에너지 분석: 평균 에너지, 근무 유형별 비교
- 맞춤 인사이트: 수면 부채 경고, 야간 집중 주간 조언 등

### 7. 에너지 트래커
- 근무 전후 컨디션(에너지 레벨) 기록
- 일간/주간/월간 에너지 통계 차트
- 근무 유형별 에너지 비교 분석

### 8. 급여 계산기
- 기본급, 교대수당, 야간수당, 연장수당 자동 계산
- 야간 수당 방식 선택: **배수 방식** (야간 시간대 × 배율) / **고정금액 방식** (근무 1회당 고정 지급)
- 세전/세후 급여 시뮬레이션
- 월별 급여 요약 카드

### 9. Apple Watch 연동
- **컨디션 대시보드**: 수면+에너지+걸음 기반 종합 컨디션 점수 (0-100)
- **수면 자동 분석**: Apple Watch HealthKit에서 수면 단계 직접 읽기 (깊은수면/REM/코어)
- **에너지 원터치 기록**: Watch에서 1-5 탭으로 즉시 에너지 기록 → iPhone 앱 자동 동기화
- **걸음 수/심박수 실시간 표시**
- **근무 알림**: 근무 시작 10분 전, 근무 종료 시 Watch 알림
- **HealthKit Background Delivery**: 앱을 열지 않아도 새로운 수면/활동 데이터 자동 수집
- App Group (UserDefaults)을 통한 Watch↔iPhone 양방향 데이터 공유

### 10. 홈스크린 위젯
- iOS WidgetKit 위젯 (오늘 근무 + 주간 스케줄)
- Android 홈스크린 위젯 (소형/중형)
- App Group을 통한 앱↔위젯 데이터 공유

### 11. 스케줄 이미지 내보내기
- 월간 캘린더를 PNG 이미지로 생성
- 카카오톡/SNS/메시지 등으로 공유
- 다크 테마 기반 깔끔한 캘린더 디자인 (1080×1350)

### 12. 온보딩
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
    │   ├── report/
    │   │   └── weekly_report_screen.dart       # 주간 리포트 (등급, 분석, 인사이트)
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
| `lib/app.dart` | MaterialApp 구성, IndexedStack 기반 하단 네비게이션 (홈/캘린더/컨디션/설정) |

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
| `notification_service.dart` | iOS/Android 로컬 알림. 스마트 수면 알림, 카페인 마감, 야간 사전 알림, 근무 알림, 주간 리포트 알림 |

### screens/

| 파일 | 설명 |
|------|------|
| `home_screen.dart` | 인사말, 오늘 근무 카드, 컴팩트 메트릭(수면/에너지/리듬), 에너지 퀵 입력, 이번 주 근무, 주간 리포트, 맞춤 건강 팁(최대 2개) |
| `calendar_screen.dart` | TableCalendar 월간 뷰, 근무 타입 범례, 패턴 선택 바텀시트, 근무 추가/수정/삭제 |
| `sleep_tracker_screen.dart` | 오늘의 수면 카드, 주간 바차트, 근무별 평균 수면 진행바, 최근 기록 리스트, 수면 기록 바텀시트(시간+품질) |
| `sleep_stats_screen.dart` | 평균 수면/품질/기록수 요약, 30일 추이 차트, 품질 분포 바, 근무 유형별 분석 |
| `health_coach_screen.dart` | 서카디안 배너(탭→상세), 카테고리 필터 칩, 건강 팁 확장 리스트 |
| `circadian_screen.dart` | 24시간 원형 시계(CustomPainter), 건강 점수 진행바, 권장 시간표, 24시간 타임라인 가이드 |
| `weekly_report_screen.dart` | 주간 종합 등급(A+~D), 근무 패턴, 수면/에너지 분석 차트, 맞춤 인사이트 |
| `settings_screen.dart` | 프로필, 스마트 수면 알림/근무/건강/명언 토글, 이동 시간 자유 입력, 데이터 내보내기/가져오기/초기화, 앱 정보 |
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

### v1.0.6 (2026-04-01) - 홈 최적화 & 스마트 알림 & 주간 리포트 & 위젯 개선

#### 홈 화면 최적화
- **컴팩트 메트릭 카드**: 수면/에너지/리듬 점수를 하나의 카드 한 줄에 통합 (기존 3개 카드 → 1개)
- **활동 데이터 통합**: 걸음수/심박수도 동일한 컴팩트 스타일로 통일
- **급여 카드 조건부 표시**: 매월 20일 이후에만 표시 (월말 관심 시점 최적화)
- **맞춤 건강 팁**: 데이터 기반 팁만 최대 2개 표시 (priority ≤ 1), 기존 4개 → 2개로 정보 밀도 감소
- **홈 에너지 퀵 입력**: 오늘 에너지 미기록 시 "지금 에너지는?" 1~5 원터치 입력 바 표시

#### 스마트 알림 시스템
- **근무 연동 수면 알림**: 내일 근무 타입에 따라 취침 시간 자동 조정
  - 주간: 22:00 / 오후: 00:00 / 야간: 14:00(낮잠) / 휴무: 23:00
  - 실제 근무 시작 시간 기준 8시간 전 자동 계산
- **야간근무 사전 알림**: 야간근무 전날 12:00에 "오후에 90분 이내 낮잠 추천" 알림
- **카페인 마감 알림**: 추천 취침 6시간 전 "지금부터 카페인 피하세요" 알림
- **설정 UI 업데이트**: "수면 리마인더" → "스마트 수면 알림" (근무 타입 맞춤 취침·카페인 마감 알림)

#### 주간 리포트
- **주간 리포트 화면 신규 추가** (`/weekly-report`)
  - 주간 종합 등급 (A+~D, 수면·에너지·수면부채 기반)
  - 근무 패턴 분석 (주간/오후/야간/휴무 일수)
  - 수면 분석: 평균 수면/질/부채, 요일별 바 차트, 최고/최저 수면일
  - 에너지 분석: 평균 에너지, 기록 횟수, 근무 유형별 에너지 비교
  - 맞춤 인사이트: 수면 부채 경고, 야간 집중 주간 조언, 에너지 저하 경고 등
- **주간 리포트 알림**: 매주 일요일 20:00에 "이번 주 리포트가 준비됐어요" 알림
- **홈 화면 진입점**: 이번 주 근무 아래 "주간 리포트" 버튼 추가

#### 위젯 실시간 갱신
- **7일치 타임라인 생성**: 기존 entry 1개 → 7개로 확장, 앱 실행 없이도 자정에 자동으로 다음 날 근무 표시
- **14일치 데이터 저장**: Flutter에서 14일치 shift 데이터를 위젯에 전달하여 7일 타임라인 + 주간 스트립 커버
- 각 날짜별 근무 타입/시간/휴무 D-day 자동 계산

#### 동기부여 메시지 확장
- **20개 → 100개**로 대폭 확장 (7개 카테고리: 응원/건강/마인드셋/명언/실용/관계/성장)
- **날짜 기반 선택**: 하루에 하나씩 바뀌고 100일간 반복 없음 (기존 앱 실행마다 동일 메시지 반복 문제 해결)

### v1.0.5 (2026-04-01) - 컨디션 대시보드 & 건강 코치 개인화

#### 구조 변경
- **탭 구조 개편**: 5탭(홈/캘린더/컨디션/건강/설정) → 4탭(홈/캘린더/컨디션/설정)으로 축소
- **컨디션 통합 대시보드**: 수면/에너지 탭 분리 → 단일 대시보드로 통합
  - 컨디션 종합 점수 (수면 40% + 에너지 35% + 활동량 25%)
  - 오늘의 수면/에너지/걸음수 한눈에 확인
  - 1탭 에너지 퀵 입력 (1~5 버튼)
  - 주간 수면 추이 차트
  - 데이터 기반 인사이트 인라인 표시
  - 수면 기록 / 에너지 기록 / 건강 가이드 빠른 접근 버튼
- 건강 코치/서카디안 화면은 라우트로 유지 (컨디션에서 접근)

#### 건강 코치 개인화 (옵션B)
- **데이터 기반 인사이트 추가**: 어제 수면 분석, 취침 불규칙 경고, 수면 부채 누적, 활동량 부족 감지, 심박수 이상, 에너지 저하 경고
- **시간 인식 컨텍스트 팁**: 취침 준비 알림, 기상 후 가이드, 근무 중반 에너지 관리
- 기존 정적 팁 우선순위 하향 조정 (인사이트가 최상위)

#### 수면 동기화 개선
- **HealthKit 데이터 우선 정책**: 수동 입력이 있어도 HealthKit 데이터로 자동 교체
- HealthKit 연동 시 수동 입력 UI 축소 ("Apple Watch에서 자동 기록됩니다" + 작은 편집 버튼)
- 미연동 시 건강 데이터 연동 유도 배너 표시

#### 버그 수정
- **근무 시간 설정 미반영**: 설정에서 근무 시간 변경 후 알림이 이전 시간으로 오던 문제 수정 → DB 일괄 업데이트 + 알림 재스케줄링

---

### v1.0.3 (2026-03-05) - 알림 개선 및 급여계산기 고도화

#### 버그 수정
- **급여계산기 음수 수당**: 수당 배율이 1 미만일 때 `(배율-1)`이 음수가 되어 수당이 마이너스로 표시되던 문제 수정 → `max(0, 배율-1)` 적용
- **월급제 기본급 오류**: 월급제에서 기본급이 실제 근무시간으로 재계산되어 설정한 월급과 다른 값이 표시되던 문제 수정 → 월급 고정값 사용
- **연장시간 과다 계산**: 법정 40h/주 기준으로 계산하여 교대근무자에게 연장시간이 과도하게 잡히던 문제 수정 → 실제 근무일×8h 기준 초과분만 계산
- **근무 알림 오늘 근무 누락**: `nextShift`가 내일부터만 탐색하여 오늘 야간 근무 알림이 등록되지 않던 문제 수정 → 시작 전인 당일 근무도 포함
- **근무 알림 일회성 문제**: 알림 발생 후 앱을 다시 열어야만 다음 알림이 등록되던 문제 수정 → 앱 시작 시 최대 7개 알림 선(先)등록 (14일 내 근무 기준)

#### 새 기능
- **이동 시간 기반 출발 알림**: 알림 메시지 "N분 후 근무 시작" → "지금 출발하세요! 야간 근무 22:00 시작 · 이동 시간 35분"으로 변경. 이동 시간 드롭다운(30/60/90/120분 고정) → 1~300분 자유 입력으로 개선
- **야간 수당 방식 선택**: 급여 설정에서 배수 방식(야간 시간대 기본급 × 배율) / 고정금액 방식(야간 근무 1회당 고정 지급) 중 선택 가능
- **오늘의 한 마디**: 설정에서 활성화 시 매일 지정 시간에 교대근무자 동기부여 메시지 알림 (20개 메시지 랜덤 발송, 앱 시작마다 갱신)

---

### v1.0.2 (2026-02-27) - 버그 수정 및 기능 개선

#### 버그 수정
- **알람 타임존 오류**: UTC 기준으로 알림이 스케줄되어 한국(KST, UTC+9) 기준으로 9시간 차이 발생하던 문제 수정 → `Asia/Seoul` 타임존 명시 적용
- **수면 알림 일회성 문제**: 알림이 한 번 뜨면 이후 다시 울리지 않던 문제 수정 → 매일 반복 알림으로 변경 (`matchDateTimeComponents.time`)
- **근무 알림 미갱신**: 앱 재시작 후 다음 근무 알림이 재등록되지 않던 문제 수정 → 앱 시작 시 자동 재스케줄
- **홈 화면 전체보기 버튼**: 이번 주 근무 옆 '전체보기' 버튼을 눌러도 반응 없던 버그 수정 → 캘린더 탭으로 이동 연결

#### 새 기능
- **에너지 자동 추정**: 수동으로 에너지를 기록하지 않아도 오늘 수면 데이터(시간+품질) 기반으로 에너지 레벨 자동 추정, 홈 카드에 '추정' 표시
- **데이터 내보내기**: 근무/수면/에너지 기록을 CSV 파일로 내보내기 지원
- **수면 동기화 개선**: Apple Watch 수면 단계 데이터(깊은 수면, 얕은 수면, REM, 각성) 연동
- **서카디안 화면**: 7일간 수면 요약 통계 카드 추가
- **탭 네비게이션 Provider 통합**: 화면 간 탭 이동을 `tabIndexProvider`로 중앙 관리

---

### v1.0.0 (2026-02-17) - App Store 제출

#### 신규 기능
- 에너지 트래커: 근무 전후 컨디션 기록 및 통계 차트
- 급여 계산기: 교대수당/야간수당/연장수당 자동 계산, 세전/세후 시뮬레이션
- 홈스크린 위젯: iOS WidgetKit + Android AppWidget (오늘 근무, 주간 스케줄)
- 스케줄 이미지 내보내기: 월간 캘린더 PNG 생성 및 SNS 공유
- HealthKit 연동: 수면, 걸음 수, 심박수 데이터 자동 동기화

#### 빌드 및 배포
- Apple Developer Portal 설정 (App ID, App Groups, HealthKit)
- Xcode Archive → App Store Connect 업로드 완료
- health 플러그인 v13으로 업그레이드

---

### v0.1.0 (2025-02-12) - 최초 생성

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
- 하단 네비게이션 4탭 셸 구성 (`app.dart`)
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

## 변경 이력

### v1.0.8 (2026-04-24)

**수면 기록 동기화 버그 수정**
- HealthKit에서 이미 동기화된 수면 레코드가 있으면 이후 업데이트가 무시되던 문제 수정
  - 워치에서 수면 추적 완료 후 최종 데이터가 앱에 반영되지 않던 현상 해결
  - 취침 중 부분 동기화된 짧은 세션이 기상 후 완전한 세션으로 자동 교체됨
- 같은 날짜에 여러 수면 세션(낮잠 + 밤잠)이 기록될 때 더 짧은 세션이 밤잠을 덮어쓰던 문제 수정
  - 정책: 같은 날짜 내에서는 **가장 긴 세션**을 유지 (밤잠 우선, 낮잠은 저장 안됨)
  - 낮잠 별도 기록 지원은 추후 스키마 확장 시 적용 예정

### v1.0.7 (2026-04-06)

**Apple Watch 건강 자동 동기화**
- Watch HealthKitManager에 수면 데이터 직접 읽기 추가 (깊은수면/REM/코어 단계 분석)
- Watch 컨디션 점수 화면 신규 (수면+에너지+걸음 기반 0-100점 게이지)
- HealthSummaryView 전면 개편: 컨디션 스코어 + 수면 분석 + 걸음 진행바 + 심박수
- Watch→iPhone 에너지 기록 동기화 (watch_energy_pending → Flutter DB 자동 반영)

**HealthKit Background Delivery**
- iOS AppDelegate에 HealthKit observer query + background delivery 등록
- 수면/걸음 데이터가 새로 기록되면 앱 미실행 상태에서도 자동 수집
- BGProcessingTask로 1시간 주기 백그라운드 동기화 스케줄링
- Info.plist에 UIBackgroundModes (fetch, processing) 추가

**버그 수정**
- 수면 기록 취침시간 자동 보정: bedTime > wakeTime일 때 전날로 조정 (음수 수면시간 버그)
- SleepState.copyWith sentinel 패턴 적용: todayRecord에 null 전달 가능하도록 수정
- 컨디션 점수 계산 정상화: 가중치 합산(totalWeight) 방식으로 변경, 수면 없이 에너지만 있을 때 100점 되던 버그 수정

**인프라**
- ChangeWatchComplication bundle ID prefix 수정 (watchkitapp 하위로)
- WKCompanionAppBundleIdentifier 추가 (Watch 앱 설치 오류 해결)
- 버전 1.0.7로 업데이트

### v1.0.6 (2026-04-05)

- 홈 화면 최적화: 수면/에너지/리듬 컴팩트 메트릭 카드, 에너지 원터치 입력
- 스마트 알림: 근무 타입별 취침 알림, 카페인 마감 알림, 야간 사전 알림
- 주간 리포트: 수면·에너지·근무 패턴 분석 및 종합 등급 (A+~D)
- 위젯 실시간 갱신: 7일 타임라인 엔트리 생성, 앱 실행 없이 자정 자동 반영
- 동기부여 메시지 100개로 확장, 일별 순환 (day-of-year 기반)

### v1.0.4 (2026-04-04)

- 건강 코치 데이터 기반 개인화 (수면 분석, 활동량 감지, 심박수 이상 감지)
- 컨디션 통합 대시보드 (4탭 구조)
- 수면 HealthKit 자동 동기화 우선 정책
- Apple Watch 수면 단계 데이터 연동

### v1.0.3 (2026-04-03)

- 급여계산기 음수 수당 및 월급제 계산 버그 수정
- 이동 시간 기반 출발 알림 기능 추가
- 근무 알림 안정성 개선
- 교대근무자 일일 동기부여 알림 추가

---

## 향후 계획

- [x] ~~Apple HealthKit 연동 (자동 수면 데이터 수집)~~ ✅ 완료
- [x] ~~위젯 지원 (홈 화면 위젯으로 오늘 근무 표시)~~ ✅ 완료
- [x] ~~에너지/무드 트래커 추가~~ ✅ 완료
- [x] ~~이동 시간 기반 출발 알림~~ ✅ 완료
- [x] ~~야간 수당 고정금액 방식 지원~~ ✅ 완료
- [x] ~~동기부여 알림 (오늘의 한 마디)~~ ✅ 완료
- [x] ~~건강 코치 데이터 기반 개인화~~ ✅ 완료
- [x] ~~컨디션 통합 대시보드 (4탭 구조)~~ ✅ 완료
- [x] ~~수면 HealthKit 자동 동기화 우선 정책~~ ✅ 완료
- [x] ~~홈 화면 정보 밀도 최적화~~ ✅ 완료
- [x] ~~근무 타입 연동 스마트 알림 (수면/카페인 컷오프)~~ ✅ 완료
- [x] ~~주간 리포트~~ ✅ 완료
- [x] ~~에너지 기록 간소화 (홈 퀵 입력)~~ ✅ 완료
- [x] ~~Apple Watch 자동 건강 동기화 (수면/에너지/걸음/심박 자동 수집)~~ ✅ 완료
- [x] ~~Watch 컨디션 점수 표시 (수면+에너지+활동 기반)~~ ✅ 완료
- [x] ~~HealthKit Background Delivery (백그라운드 자동 동기화)~~ ✅ 완료
- [x] ~~Watch→iPhone 에너지 기록 동기화~~ ✅ 완료
- [ ] Apple Watch 컴패니언 앱 배포 (개발 완료, 배포 준비 중)
- [ ] 월간 리포트 (월간 추이 분석, PDF 내보내기)
- [ ] 클라우드 백업 (Firebase/Supabase)
- [ ] 근무 교환 마켓플레이스 (동료 간 근무일 교환)
- [ ] 다국어 지원 (영어, 일본어)

---

## 라이선스

Private - All rights reserved.
