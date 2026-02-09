# 위젯 & 다이나믹 아일랜드 구현 완료

## 개요

SunlightTracker 앱에 홈 스크린 위젯과 라이브 액티비티(다이나믹 아일랜드) 기능이 추가되었습니다.

## 구현된 기능

### 1. 홈 스크린 위젯 (3가지 크기)

#### Small Widget
- 미니 해바라기 애니메이션 (건강 상태 반영)
- 배터리 충전량 표시
- 오늘의 목표 진행도 바

#### Medium Widget
- 해바라기 + 건강 상태 표시
- 배터리 충전량
- 오늘의 햇빛 시간 & 진행도

#### Large Widget
- 전체 대시보드 뷰
- 해바라기 상태 상세 정보
- 배터리 섹션
- 오늘의 햇빛 진행도
- 목표 달성 시 축하 메시지

### 2. 라이브 액티비티 & 다이나믹 아일랜드

#### Lock Screen (잠금 화면)
- 헤더: "햇빛 트래킹 중" + 경과 시간
- 조도, 예상 충전량, 해바라기 에너지 표시

#### Dynamic Island - Compact (축소)
- Leading: 해바라기 아이콘
- Trailing: 예상 충전량 (+XX%)

#### Dynamic Island - Expanded (확장)
- Leading: 해바라기 아이콘 + 경과 시간
- Trailing: 배터리 + 예상 충전량
- Center: 조도 게이지
- Bottom: 해바라기 에너지 + 조도 배터리 뷰 + 충전량

#### Dynamic Island - Minimal (최소)
- 배터리 아이콘

## 파일 구조

### 메인 앱 (SunlightTracker)
```
SunlightTracker/
├── Models.swift                    # SharedDataManager, WidgetData 추가됨
├── SunlightManager.swift           # 위젯 업데이트 로직 추가됨
└── SharedWidgetTypes.swift         # 라이브 액티비티 타입 정의 (새 파일)
```

### 위젯 익스텐션 (widget)
```
widget/
├── SharedModels.swift              # WidgetData, SharedDataManager (새 파일)
├── SharedWidgetTypes.swift         # SunlightTrackingAttributes (새 파일)
├── widget.swift                    # 홈 스크린 위젯 구현 (완전 재작성)
├── widgetLiveActivity.swift        # 라이브 액티비티 구현 (완전 재작성)
└── widgetBundle.swift              # 위젯 번들 등록 (업데이트)
```

## 데이터 흐름

### 1. App → Widget 데이터 공유

```swift
// SunlightManager.swift
private func updateWidgetData() {
    let widgetData = WidgetData(
        batteryPercentage: batteryStatus.chargedAmount,
        sunflowerEnergy: sunflowerHealth.currentEnergy,
        todayMinutes: todayRecord.totalMinutes,
        // ... 기타 필드
    )

    SharedDataManager.shared.saveWidgetData(widgetData)
    WidgetCenter.shared.reloadAllTimelines()
}
```

**업데이트 시점:**
- 햇빛 트래킹 확인 시
- 트래킹 중 30초마다
- 트래킹 종료 시
- 배터리 전달 시
- 해바라기 에너지 변화 시

### 2. Live Activity 생명주기

```swift
// 트래킹 확인 시 시작
private func startLiveActivity() {
    let attributes = SunlightTrackingAttributes(...)
    let initialState = SunlightTrackingAttributes.ContentState(...)
    currentActivity = try Activity.request(attributes: attributes, content: .init(state: initialState))
}

// 30초마다 업데이트
private func updateLiveActivity() {
    await activity.update(using: .init(state: updatedState))
}

// 트래킹 종료 시 종료
private func endLiveActivity() {
    await activity.end(using: .init(state: finalState), dismissalPolicy: .immediate)
}
```

## Xcode 프로젝트 설정 필요 사항

**⚠️ 중요: 다음 파일들을 Xcode 프로젝트에 수동으로 추가해야 합니다:**

### SunlightTracker 타겟에 추가:
- [x] `SunlightTracker/SharedWidgetTypes.swift`

### widgetExtension 타겟에 추가:
- [x] `widget/SharedModels.swift`
- [x] `widget/SharedWidgetTypes.swift`
- [x] `widget/widget.swift`
- [x] `widget/widgetLiveActivity.swift`
- [x] `widget/widgetBundle.swift`

### 파일 추가 방법:
1. Xcode에서 프로젝트 열기
2. 해당 파일을 프로젝트 네비게이터로 드래그 앤 드롭
3. "Add to targets" 다이얼로그에서 해당 타겟 체크
4. "Finish" 클릭

## 빌드 & 테스트

### 1. 빌드
```bash
xcodebuild -scheme SunlightTracker -sdk iphonesimulator build
```

### 2. 위젯 테스트 체크리스트

#### 홈 스크린 위젯
- [ ] Small 위젯에 해바라기 + 배터리 + 진행도 표시
- [ ] Medium 위젯에 상세 정보 표시
- [ ] Large 위젯에 대시보드 스타일 표시
- [ ] 배터리 전달 후 위젯 자동 업데이트
- [ ] 트래킹 종료 후 위젯 자동 업데이트
- [ ] 해바라기 에너지 변화 반영 (시들음 애니메이션)
- [ ] 15분마다 자동 새로고침

#### 라이브 액티비티
- [ ] 햇빛 확인 시 라이브 액티비티 자동 시작
- [ ] 잠금 화면에 트래킹 정보 표시
- [ ] 30초마다 자동 업데이트 (경과 시간, 조도, 예상 충전량)
- [ ] 트래킹 종료 시 라이브 액티비티 자동 종료

#### 다이나믹 아일랜드 (iPhone 14 Pro+ 전용)
- [ ] Compact 상태: 해바라기 아이콘 + 예상 충전량
- [ ] Expanded 상태: 모든 리전에 정보 표시
  - Leading: 해바라기 + 경과 시간
  - Trailing: 배터리 + 예상 충전량
  - Center: 조도 게이지
  - Bottom: 전체 상태 정보
- [ ] Minimal 상태: 배터리 아이콘
- [ ] 탭하면 앱이 트래킹 화면으로 열림

### 3. Edge Cases
- [ ] 앱 데이터 없을 때 placeholder 표시
- [ ] 앱 종료 후 위젯 정상 동작
- [ ] 기기 재부팅 후 위젯 정상 동작
- [ ] 라이브 액티비티 8시간 제한 처리

## 주요 컴포넌트

### MiniSunflowerView
해바라기 건강 상태에 따른 시각적 표현:
- **Thriving (80%+)**: 밝은 노란색, 꽃잎 펼침
- **Healthy (50-80%)**: 연한 노란색, 약간 시듦
- **Wilting (20-50%)**: 갈색, 꽃잎 처짐
- **Critical (<20%)**: 어두운 갈색, 심하게 처짐

### LuxGaugeView
조도 레벨을 배터리 스타일 게이지로 표시:
- 0-1000 lux: 녹색
- 1000-5000 lux: 노란색
- 5000-10000 lux: 주황색
- 10000+ lux: 빨간색

## 성능 고려사항

### 위젯 업데이트 전략
- **타임라인 정책**: 15분마다 자동 새로고침
- **수동 새로고침**: 중요 이벤트 후 즉시 `WidgetCenter.shared.reloadAllTimelines()`
- **데이터 크기**: WidgetData 약 300 bytes (1KB 미만 유지)

### 라이브 액티비티
- **업데이트 빈도**: 30초 간격 (배터리 효율)
- **최대 지속 시간**: 8시간
- **메모리 제한**: 30MB 미만

### App Groups
- **ID**: `group.com.leeo.sunflower`
- **용도**: 앱과 위젯 간 데이터 공유
- **저장 키**: `widget_data`

## 향후 개선 사항

### 가능한 추가 기능
1. **Widget Intent**: 위젯에서 직접 트래킹 시작/종료
2. **Push Notifications**: 원격에서 라이브 액티비티 업데이트
3. **Lock Screen Widget**: iOS 16+ 잠금 화면 위젯
4. **Interactive Widget**: iOS 17+ 인터랙티브 버튼
5. **Widget Animation**: 해바라기 시들음 애니메이션

### 최적화
1. 위젯 새로고침 예산 모니터링
2. 라이브 액티비티 업데이트 빈도 최적화
3. 배터리 사용량 프로파일링

## 문제 해결

### 위젯이 업데이트되지 않을 때
1. `WidgetCenter.shared.reloadAllTimelines()` 호출 확인
2. App Group 설정 확인
3. SharedDataManager의 데이터 저장/로드 로직 확인
4. Xcode에서 위젯 디버깅: Editor → Debug Preview

### 라이브 액티비티가 시작되지 않을 때
1. `ActivityAuthorizationInfo().areActivitiesEnabled` 확인
2. Info.plist에 `NSSupportsLiveActivities` 추가
3. 시뮬레이터 재시작
4. 실제 기기에서 테스트

### 빌드 에러
1. 파일이 올바른 타겟에 추가되었는지 확인
2. App Groups 설정이 동일한지 확인
3. Clean Build Folder (⌘+Shift+K)
4. DerivedData 삭제

## 참고 자료

- [Apple WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)
- [Apple ActivityKit Documentation](https://developer.apple.com/documentation/activitykit)
- [Designing Dynamic Island Experiences](https://developer.apple.com/design/human-interface-guidelines/live-activities)
- [App Groups Guide](https://developer.apple.com/documentation/xcode/configuring-app-groups)
