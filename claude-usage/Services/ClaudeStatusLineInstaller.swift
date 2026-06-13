import Foundation

enum ClaudeStatusLineInstaller {
    private static let bridgeCommand = UsagePaths.bridgeScriptURL.path

    static func installIfNeeded() throws {
        try FileManager.default.createDirectory(
            at: UsagePaths.bridgeScriptURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: UsagePaths.appSupportDirectory,
            withIntermediateDirectories: true
        )

        try bridgeScript.write(to: UsagePaths.bridgeScriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: UsagePaths.bridgeScriptURL.path
        )

        var settings = try loadSettings()
        let existingStatusLine = settings["statusLine"] as? [String: Any]
        let existingCommand = existingStatusLine?["command"] as? String
        let existingRefreshInterval = existingStatusLine?["refreshInterval"] as? Int

        if existingCommand == bridgeCommand, existingRefreshInterval == 5 {
            return
        }

        if let existingCommand, existingCommand != bridgeCommand, !existingCommand.isEmpty {
            try existingCommand.write(
                to: UsagePaths.originalStatusLineCommandURL,
                atomically: true,
                encoding: .utf8
            )
        }

        settings["statusLine"] = [
            "type": "command",
            "command": bridgeCommand,
            "padding": 0,
            "refreshInterval": 5
        ]

        let data = try JSONSerialization.data(
            withJSONObject: settings,
            options: [.prettyPrinted, .sortedKeys]
        )
        try data.write(to: UsagePaths.claudeSettingsURL, options: .atomic)
    }

    private static func loadSettings() throws -> [String: Any] {
        guard FileManager.default.fileExists(atPath: UsagePaths.claudeSettingsURL.path) else {
            return [:]
        }

        let data = try Data(contentsOf: UsagePaths.claudeSettingsURL)
        guard !data.isEmpty else { return [:] }

        let object = try JSONSerialization.jsonObject(with: data)
        return object as? [String: Any] ?? [:]
    }

    private static let bridgeScript = #"""
#!/usr/bin/env bash
set -euo pipefail

input="$(cat)"
support_dir="$HOME/Library/Application Support/ClaudeUsageLimits"
usage_file="$support_dir/usage.json"
tmp_file="$support_dir/usage.json.tmp.$$"
original_command_file="$HOME/.claude/claude-usage-limit-original-command.txt"

jq_bin="${CLAUDE_USAGE_JQ:-}"
if [ -z "$jq_bin" ]; then
  jq_bin="$(command -v jq 2>/dev/null || true)"
fi
if [ -z "$jq_bin" ] && [ -x /opt/homebrew/bin/jq ]; then
  jq_bin="/opt/homebrew/bin/jq"
fi
if [ -z "$jq_bin" ] && [ -x /usr/bin/jq ]; then
  jq_bin="/usr/bin/jq"
fi

display="--%"
json=""

if [ -n "$jq_bin" ]; then
  json="$(printf '%s' "$input" | "$jq_bin" -c '
    def epoch:
      if . == null then null
      elif type == "number" then .
      elif type == "string" then (fromdateiso8601? // tonumber? // null)
      else null end;
    .rate_limits as $limits
    | ($limits.five_hour.used_percentage // null) as $five
    | ($limits.seven_day.used_percentage // null) as $week
    | ($five // $week // null) as $display
    | select($display != null)
    | {
        schemaVersion: 1,
        currentSession: {
          usedPercentage: $five,
          resetsAt: (($limits.five_hour.resets_at // null) | epoch)
        },
        weekly: {
          usedPercentage: $week,
          resetsAt: (($limits.seven_day.resets_at // null) | epoch)
        },
        displayPercentage: $display,
        updatedAt: (now | floor)
      }
  ' 2>/dev/null || true)"

  if [ -n "$json" ]; then
    mkdir -p "$support_dir"
    printf '%s\n' "$json" > "$tmp_file"
    mv "$tmp_file" "$usage_file"
    display="$(printf '%s' "$json" | "$jq_bin" -r '.displayPercentage | round | tostring + "%"')"
  fi
fi

if [ -s "$original_command_file" ]; then
  original_command="$(cat "$original_command_file")"
  original_output="$(printf '%s' "$input" | /bin/zsh -lc "$original_command" 2>/dev/null || true)"
  if [ -n "$original_output" ]; then
    printf '%s\n' "$original_output"
    exit 0
  fi
fi

printf 'Claude %s\n' "$display"
"""#

}
