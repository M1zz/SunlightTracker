# 햇빛바라기 TODO

## 최근 업데이트 (v1.0.0)

### 앱 설정 및 브랜딩 ✅
- [✓] 앱 이름: "햇빛바라기"로 변경
- [✓] 버전 관리: AppConfig.swift 중앙 관리 (1.0.0)
- [✓] 햇빛 노출 권장사항 정보 추가

### UX 개선 ✅
- [✓] 스마트 넛지: 사용자가 기능 사용 후 힌트 자동 숨김
- [✓] 더블탭 인터랙션: 트래킹 종료/센서 재시작
- [✓] 조도 센서 스마트 센싱: 안정 시 10초마다 체크
- [✓] 해바라기 섹션 레이아웃 최적화

### 시각 효과 ✅
- [✓] 해바라기 썬글라스 (트래킹 중)
- [✓] 태양 오라 효과 (3겹 동심원 펄스)
- [✓] 플로팅 팁 시스템
- [✓] 부드러운 조도 센서 (EMA + 애니메이션)

### 균형 조정 ✅
- [✓] 해바라기 시들음: 1시간당 2.5% (하루 60%)
- [✓] 15분 목표로 하루 생존 가능하도록 조정

## 최근 작업 이력
- [✓] 처음 만나는 친구는 수락 후 함께 트래킹: 신규 상대 감지 시 "같이 받기 💛/다음에" 확인 알림, 수락해야 물듦·기록 시작. 기존 친구는 자동 연결, 거절 시 세션 동안 다시 안 물음 (pendingFriendRequest / approve / decline)
- [✓] 크래시 수정: 배터리 전달 시트 Slider — 충전량이 1% 미만(0.4% 등)일 때 range(0...0.4) < step(1)로 SwiftUI precondition 크래시. step 제거 + 시트 오픈 시점 범위 스냅샷(transferMax)으로 수정, 1% 미만 소수점 표기 추가
- [✓] 꽃잎 물듦 3일 유지: 페이드 7분 → 3일(선형), UserDefaults 영속화로 앱 재시작에도 이어서 빠짐 (SunlightManager.restorePetalFade)
- [✓] 함께 받는 중 피드백 강화: 히어로 화면에 친구 미니 해바라기 등장(살구빛 꽃잎+이름표+💛 하트, 내 해바라기가 옆으로 비켜줌), 배지 "OO이(가) 옆에서 같이 받는 중!" 리스타일, connectedPeerNames 노출
- [✓] 탭 재구성: 통계+캘린더 → "기록" 탭 하나로 병합 (세그먼트 전환, RecordsView.swift), "친구" 탭 신설 (FriendsView.swift)
- [✓] 친구 관계도: 함께 트래킹 성사 시 친구 자동 기록 (FriendRecord, UserDefaults 저장, NearbyActivityManager), 나를 중심으로 방사형 관계도 (만남 횟수 → 선 굵기/꽃 크기/꽃 종류 🌼→🌷→🌻) + 친구 목록
- [✓] 대시보드 심플+귀엽게 리디자인: 11개 섹션 → 6개 (해바라기 히어로, 상태 캡슐, 오늘 진행 바, 트래킹 버튼/카드, 배터리 카드, 수동 추가). 건강팁/일출일몰/세션목록/주간차트는 대시보드에서 제거 (통계·캘린더 탭에 유지). 이모지+캡슐+rounded 폰트 디자인 언어 적용
- [✓] 해바라기 캐릭터 로고 스타일로 리디자인 (진갈색 테두리 링, 까만 눈+하이라이트, 볼터치+주근깨, 갈색 스마일, 윤광, 두 겹 꽃잎) — 메인 앱 + 위젯 모두 적용
- [✓] 앱 이름 브랜딩 통일: pbxproj 옛 이름("일조량 트래커", "widget") → "햇빛바라기", 설정 화면 이름/버전을 AppConfig 단일 소스로, AppConfig.swift 타겟 등록
- [✓] 확인 후에도 센서 주기 재측정: 확인 후 90초 센서 유지 → 2분마다 20초 버스트 재측정, 조도 게이지 실시간 갱신 + "실시간 측정 중" 인디케이터, 화면 진입 시 즉시 재측정
- [✓] 대시보드 레이아웃 개선 (트래킹 버튼 상단 배치, 수동 입력 하단 이동, NavigationStack 타이틀 추가) + 앱 아이콘 교체
- [✓] 원형 진행 위젯 여백 조정 (spacing 12→6, padding 8→4)

## 현재 작업: 배터리 충전 컨셉으로 변경

### 컨셉 변경 사항
- [완료] 폰이 햇빛을 받아서 배터리 충전
- [완료] 충전한 배터리를 해바라기에 전달
- [완료] 해바라기가 실시간으로 시들어감

### 구현 완료
- [✓] 배터리 충전: 세션 종료 후 일괄 충전 (UI는 실시간 예상량 표시)
- [✓] 해바라기: 실시간으로 시듦 (1시간당 10%씩 에너지 감소)
- [✓] 배터리 전달: 버튼으로 수동 전달 (슬라이더로 전달량 조절)
- [✓] 시간 기록: 유지 (백엔드), UI는 배터리 중심

### 파일 수정 완료
1. [✓] Models.swift - BatteryStatus, SunflowerHealth 모델 추가
2. [✓] SunlightManager.swift - 배터리/시들음 로직 구현
3. [✓] SunAnimationView.swift - 건강도 기반 시들음 애니메이션
4. [✓] DashboardView.swift - 배터리 UI + 전달 시트 추가

### 테스트 필요
- [ ] 앱 시작 시 해바라기 100%, 배터리 0% 확인
- [ ] 시간 경과에 따른 해바라기 에너지 감소 확인
- [ ] 햇빛 트래킹 시 실시간 예상 충전량 표시 확인
- [ ] 세션 종료 시 배터리 실제 충전 확인
- [ ] 배터리 전달 기능 확인
- [ ] 해바라기 애니메이션 변화 확인 (싱싱 → 시듦)

## 새로운 기능 구현 완료 ✓

### 햇빛 건강 팁 (정신건강 & 육체건강)
- [✓] 17가지 건강 팁 데이터 추가 (정신건강, 육체건강, 비타민D, 수면, 면역력)
- [✓] DashboardView에 랜덤 팁 카드 표시
- [✓] 새로고침 버튼으로 랜덤 팁 변경
- [✓] 카테고리별 색상 구분

### 캘린더 뷰 + 기분/메모 기록
- [✓] HistoryView → CalendarView로 교체
- [✓] 월간 캘린더 그리드 뷰
- [✓] 날짜별 일조량 + 기분 이모지 표시
- [✓] 날짜 선택 시 상세 정보 (일조량, 세션 수, 최고 조도, 목표 달성)
- [✓] 기분 이모지 5단계 (매우 좋음, 좋음, 보통, 안 좋음, 매우 안 좋음)
- [✓] 한마디 메모 기능
- [✓] 월간 요약 통계

### 파일 생성/수정
- [✓] Models.swift - DailyMood enum, mood/note 필드 추가, HealthTip 모델 추가
- [✓] SunlightManager.swift - updateMood(), updateNote(), getRandomHealthTip() 추가
- [✓] DashboardView.swift - 랜덤 건강 팁 카드 업데이트, Color hex extension
- [✓] CalendarView.swift - 캘린더 뷰 구현 (새 파일)
- [✓] ContentView.swift - HistoryView → CalendarView 교체

## 위젯 & 다이나믹 아일랜드 구현 (진행 중)

### Phase 1: 공유 데이터 레이어 ✓
- [✓] Models.swift에 SharedDataManager + WidgetData 추가
- [✓] SunlightManager에 updateWidgetData() 통합
- [✓] widget/SharedModels.swift 생성 (위젯용)

### Phase 2: 홈 스크린 위젯 ✓
- [✓] SunflowerWidgetProvider 타임라인 구현
- [✓] MiniSunflowerView 컴포넌트 작성
- [✓] 위젯 2개로 분리: SunflowerWidget (해바라기 건강도), BatteryWidget (배터리 충전량)
- [✓] widgetBundle.swift에 두 위젯 모두 등록

### Phase 3: 라이브 액티비티 ✓
- [✓] SunlightTrackingAttributes 정의
- [✓] 잠금 화면 뷰 구현
- [✓] SunlightManager에 라이브 액티비티 연동

### Phase 4: 다이나믹 아일랜드 ✓
- [✓] Compact/Minimal 프레젠테이션 구현
- [✓] Expanded 프레젠테이션 구현 (모든 리전)

### 다음 단계: Xcode 프로젝트 설정 (수동 작업 필요)

**중요: 다음 파일들을 Xcode에서 프로젝트에 추가해야 합니다:**

1. **SunlightTracker 타겟에 추가:**
   - `SunlightTracker/SharedWidgetTypes.swift` (메인 앱에서 사용)

2. **widgetExtension 타겟에 추가:**
   - `widget/SharedModels.swift` (위젯에서 WidgetData 사용)
   - `widget/SharedWidgetTypes.swift` (라이브 액티비티에서 사용)
   - `widget/widget.swift` (이미 추가되어 있어야 함)
   - `widget/widgetLiveActivity.swift` (이미 추가되어 있어야 함)
   - `widget/widgetBundle.swift` (이미 추가되어 있어야 함)

**Xcode에서 파일 추가하는 방법:**
1. Xcode에서 프로젝트 열기
2. 파일을 프로젝트 네비게이터로 드래그 앤 드롭
3. "Add to targets" 체크박스에서 해당 타겟 선택
4. 빌드

**빌드 후 테스트:**
- [ ] 빌드 에러 없이 컴파일 성공
- [ ] 시뮬레이터에서 앱 실행
- [ ] 홈 화면에 위젯 추가 (Small/Medium/Large)
- [ ] 햇빛 트래킹 시작하여 라이브 액티비티 확인
- [ ] 다이나믹 아일랜드 동작 확인 (iPhone 14 Pro+ 시뮬레이터)
