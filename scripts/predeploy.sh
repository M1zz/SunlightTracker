#!/bin/sh
# 배포 전 게이트 — 여기서 실패하면 DeployBar 가 아카이브를 만들지 않는다.
#
# 사용법:
#   sh scripts/predeploy.sh
#
# 다국어(.xcstrings) 검사는 DeployBar 에 내장돼 있으므로 여기서 다시 하지 않는다.
# 이 스크립트는 "이 앱만의" 검사 — 테스트, 금지 패턴 검사 등 — 를 담는다.
#
# ⚠️ CODE_SIGNING_ALLOWED=NO 로 테스트를 빠르게 만들지 말 것.
#    entitlements 가 빠지면 CloudKit 등 실제 배포 경로에서만 터지는 문제를 놓친다.
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

SCHEME="SunlightTracker"
PROJECT_FLAG="-project"
PROJECT="SunlightTracker.xcodeproj"

# 테스트 타겟이 없다(SunlightTracker · widgetExtension 뿐). Release 빌드가 깨지지 않는지까지만 확인한다.
echo "🔨 Release 빌드 확인 ($SCHEME · 위젯 포함)"
xcodebuild build \
  "$PROJECT_FLAG" "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination "generic/platform=iOS Simulator" \
  -quiet

echo ""
echo "✅ 게이트 통과 — 배포 가능"
echo "   (테스트 타겟이 없어 Release 빌드까지만 확인했습니다)"
