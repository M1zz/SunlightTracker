# 🌻 햇빛바라기 (SunlightTracker)

하루 한 줌의 햇빛, 내 햇빛 배터리를 채워요.

밖에서 햇빛을 받은 시간을 자동으로 세는 iOS 앱입니다.
밖에 있던 시간만큼 햇빛 배터리가 차고, 시간이 지나면 조금씩 줄어요.
첫 화면의 해가 빛살로 얼마나 남았는지 보여 줍니다.

## 주요 기능

- ☀️ **자동 햇빛 감지**: 카메라로 밖인지 가려, 밖에 있던 시간을 자동 기록
- 🔋 **햇빛 배터리**: 하루 목표 시간을 채우면 100%, 시간당 2.5%씩 줄어요. 빛살 12개가 남은 만큼 켜져요
- 📅 **기록**: 캘린더/통계 뷰, 날짜별 기분 이모지 · 메모
- 👥 **친구와 함께**: 가까이에서 같이 받으면 햇살이 알록달록 물들고, 관계도에 기록이 쌓여요 (MultipeerConnectivity + NearbyInteraction)
- 📱 **위젯 & 라이브 액티비티**: 홈 화면 위젯, 잠금 화면, 다이나믹 아일랜드

## 링크

- 🏠 [소개 페이지](https://m1zz.github.io/SunlightTracker/)
- 🔒 [개인정보 처리방침](https://m1zz.github.io/SunlightTracker/privacy.html)
- 💬 [지원 · 문의](https://m1zz.github.io/SunlightTracker/support.html)

## 개인정보

서버가 없는 앱입니다. 기록은 모두 기기 안에만 저장되며 외부로 전송되지 않습니다. 익명 사용 통계와 오류 보고만 Apple iCloud로 전송됩니다.
자세한 내용은 [개인정보 처리방침](https://m1zz.github.io/SunlightTracker/privacy.html)을 참고하세요.

## 개발

- iOS 17+, SwiftUI
- 타겟: `SunlightTracker` (앱), `widgetExtension` (위젯/라이브 액티비티), `SunlightWatch` (워치 앱, watchOS 10+), `SunlightWatchWidget` (워치 컴플리케이션)
- 건강 앱: '햇빛 아래 있었던 시간'(HealthKit `timeInDaylight`)을 읽기만 한다. 설정에서 켤 때만 권한을 묻는다 (`Shared/DaylightHealth.swift`)

```bash
xcodebuild -project SunlightTracker.xcodeproj -scheme SunlightTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16e' build
```

## 문의

leeo@kakao.com · [GitHub Issues](https://github.com/M1zz/SunlightTracker/issues)
