# Claude Usage Bar Mac

Claude Code 사용량을 macOS 메뉴 막대에서 확인하는 작은 유틸리티 앱입니다.

앱을 실행하면 Claude Code의 `statusLine` 설정에 브리지 스크립트를 설치하고,
Claude가 전달하는 rate limit 정보를 `~/Library/Application Support/ClaudeUsageLimits/usage.json`에 저장합니다.
메뉴 막대 패널에서는 현재 세션 사용량과 주간 사용량을 한국어로 보여줍니다.

## Requirements

- macOS 14+
- Xcode
- `jq` 권장

## Build and Run

```bash
./script/build_and_run.sh
```

빌드만 직접 실행하려면:

```bash
xcodebuild \
  -project ClaudeUsageBarMac.xcodeproj \
  -scheme ClaudeUsageBarMac \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Notes

- 앱은 메뉴 막대 전용 앱으로 Dock에 표시되지 않습니다.
- 기존 Claude Code `statusLine.command`가 있으면 `~/.claude/claude-usage-limit-original-command.txt`에 보관한 뒤 함께 실행합니다.
