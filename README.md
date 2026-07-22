# 🌻 햇빛바라기 (SunlightTracker)

하루 한 줌의 햇빛, 나의 해바라기를 키워요.

카메라 조도 센서로 실제 햇빛 노출을 자동 감지해 기록하는 iOS 앱입니다.
햇빛을 받을수록 배터리가 충전되고, 그 에너지로 나만의 해바라기를 키웁니다.
돌보지 않으면 해바라기가 시들어요.

## 주요 기능

- ☀️ **자동 햇빛 감지** — 카메라 노출 정보로 조도를 추정, 실외 밝기가 지속되면 자동 기록
- 🌻 **해바라기 키우기** — 햇빛으로 충전한 배터리를 해바라기에게 전달해 건강 유지
- 📅 **기록** — 캘린더/통계 뷰, 날짜별 기분 이모지 · 메모
- 👥 **친구와 함께** — 가까이에서 같이 받으면 꽃잎이 알록달록 물들고, 관계도에 기록이 쌓여요 (MultipeerConnectivity + NearbyInteraction)
- 📱 **위젯 & 라이브 액티비티** — 홈 화면 위젯, 잠금 화면, 다이나믹 아일랜드

## 링크

- 🏠 [소개 페이지](https://m1zz.github.io/SunlightTracker/)
- 🔒 [개인정보 처리방침](https://m1zz.github.io/SunlightTracker/privacy.html)
- 💬 [지원 · 문의](https://m1zz.github.io/SunlightTracker/support.html)

## 개인정보

서버가 없는 앱입니다. 모든 데이터는 기기 안에만 저장되며 외부로 전송되지 않습니다.
자세한 내용은 [개인정보 처리방침](https://m1zz.github.io/SunlightTracker/privacy.html)을 참고하세요.

## 개발

- iOS 17+, SwiftUI
- 타겟: `SunlightTracker` (앱), `widgetExtension` (위젯/라이브 액티비티)

```bash
xcodebuild -project SunlightTracker.xcodeproj -scheme SunlightTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16e' build
```

## 문의

mizzking75@gmail.com · [GitHub Issues](https://github.com/M1zz/SunlightTracker/issues)
