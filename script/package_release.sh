#!/usr/bin/env bash
set -euo pipefail

APP_NAME="claude-usage"
PROJECT="claude-usage.xcodeproj"
SCHEME="claude-usage"
CONFIGURATION="Release"
TEAM_ID="${TEAM_ID:-BKGYVZGXR3}"
SIGN_IDENTITY="${SIGN_IDENTITY:-Developer ID Application: chaewon Lee (BKGYVZGXR3)}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA="$ROOT_DIR/build/ReleaseDerivedData"
APP_BUNDLE="$DERIVED_DATA/Build/Products/$CONFIGURATION/$APP_NAME.app"
DIST_DIR="$ROOT_DIR/dist"
ZIP_PATH="$DIST_DIR/$APP_NAME.zip"
SIGNED_ZIP_PATH="$DIST_DIR/$APP_NAME-signed-not-notarized.zip"
NOTARY_ZIP_PATH="$DIST_DIR/$APP_NAME-notary.zip"

cd "$ROOT_DIR"
mkdir -p "$DIST_DIR"
rm -rf "$APP_BUNDLE" "$ZIP_PATH" "$SIGNED_ZIP_PATH" "$NOTARY_ZIP_PATH"

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGNING_ALLOWED=YES \
  CODE_SIGNING_REQUIRED=YES \
  CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="$SIGN_IDENTITY" \
  ENABLE_HARDENED_RUNTIME=YES \
  OTHER_CODE_SIGN_FLAGS="--timestamp" \
  clean build

codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
codesign -dvv "$APP_BUNDLE"

if [[ -n "$NOTARY_PROFILE" ]]; then
  ditto -c -k --keepParent "$APP_BUNDLE" "$NOTARY_ZIP_PATH"
  xcrun notarytool submit "$NOTARY_ZIP_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$APP_BUNDLE"
  xcrun stapler validate "$APP_BUNDLE"
  spctl -a -vv "$APP_BUNDLE"
  ditto -c -k --keepParent "$APP_BUNDLE" "$ZIP_PATH"
  echo "Release zip: $ZIP_PATH"
else
  ditto -c -k --keepParent "$APP_BUNDLE" "$SIGNED_ZIP_PATH"
  cat <<EOF

Built and Developer ID signed:
  $APP_BUNDLE

Signed zip, not for GitHub release upload yet:
  $SIGNED_ZIP_PATH

Notarization was skipped because NOTARY_PROFILE is empty.
Create a keychain profile once:
  xcrun notarytool store-credentials claude-usage-notary --team-id "$TEAM_ID" --apple-id YOUR_APPLE_ID

Then build the GitHub release zip:
  NOTARY_PROFILE=claude-usage-notary ./script/package_release.sh

EOF
fi
