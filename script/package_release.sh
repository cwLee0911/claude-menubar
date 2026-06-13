#!/usr/bin/env bash
set -euo pipefail

APP_NAME="claude-usage"
PROJECT="claude-usage.xcodeproj"
SCHEME="claude-usage"
CONFIGURATION="Release"
TEAM_ID="${TEAM_ID:-}"
SIGN_IDENTITY="${SIGN_IDENTITY:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
VOLUME_NAME="${VOLUME_NAME:-claude-usage}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA="$ROOT_DIR/build/ReleaseDerivedData"
APP_BUNDLE="$DERIVED_DATA/Build/Products/$CONFIGURATION/$APP_NAME.app"
DIST_DIR="$ROOT_DIR/dist"
ZIP_PATH="$DIST_DIR/$APP_NAME.zip"
DMG_PATH="$DIST_DIR/$APP_NAME.dmg"
SIGNED_ZIP_PATH="$DIST_DIR/$APP_NAME-signed-not-notarized.zip"
SIGNED_DMG_PATH="$DIST_DIR/$APP_NAME-signed-not-notarized.dmg"
NOTARY_ZIP_PATH="$DIST_DIR/$APP_NAME-notary.zip"
UNZIP_CHECK_DIR="$DIST_DIR/unzip-check"
DMG_STAGING_DIR="$DIST_DIR/dmg-staging"
DMG_MOUNT_DIR="$DIST_DIR/dmg-mount"

detect_signing_identity() {
  if [[ -n "$SIGN_IDENTITY" ]]; then
    return
  fi

  SIGN_IDENTITY="$(security find-identity -v -p codesigning | sed -n 's/.*"\(Developer ID Application: .*\)".*/\1/p' | head -n 1)"
  if [[ -z "$SIGN_IDENTITY" ]]; then
    echo "No Developer ID Application signing identity found. Set SIGN_IDENTITY to build a release." >&2
    exit 1
  fi
}

detect_team_id() {
  if [[ -n "$TEAM_ID" ]]; then
    return
  fi

  if [[ "$SIGN_IDENTITY" =~ \(([A-Z0-9]{10})\)$ ]]; then
    TEAM_ID="${BASH_REMATCH[1]}"
  fi
}

make_zip() {
  local source_app="$1"
  local output_zip="$2"
  COPYFILE_DISABLE=1 ditto -c -k --norsrc --noextattr --noqtn --keepParent "$source_app" "$output_zip"
}

verify_zip_signature() {
  local input_zip="$1"
  rm -rf "$UNZIP_CHECK_DIR"
  mkdir -p "$UNZIP_CHECK_DIR"
  /usr/bin/unzip -q "$input_zip" -d "$UNZIP_CHECK_DIR"
  codesign --verify --deep --strict --verbose=2 "$UNZIP_CHECK_DIR/$APP_NAME.app"
  if /usr/bin/unzip -l "$input_zip" | grep -Eq '(^|/)\._|(^|/)__MACOSX(/|$)'; then
    echo "Refusing zip with AppleDouble metadata: $input_zip" >&2
    exit 1
  fi
  rm -rf "$UNZIP_CHECK_DIR"
}

make_dmg() {
  local source_app="$1"
  local output_dmg="$2"

  rm -rf "$DMG_STAGING_DIR" "$DMG_MOUNT_DIR" "$output_dmg"
  mkdir -p "$DMG_STAGING_DIR"
  ditto "$source_app" "$DMG_STAGING_DIR/$APP_NAME.app"
  ln -s /Applications "$DMG_STAGING_DIR/Applications"

  COPYFILE_DISABLE=1 hdiutil create \
    -volname "$VOLUME_NAME" \
    -srcfolder "$DMG_STAGING_DIR" \
    -ov \
    -format UDZO \
    "$output_dmg"
}

verify_dmg() {
  local input_dmg="$1"

  hdiutil verify "$input_dmg"
  rm -rf "$DMG_MOUNT_DIR"
  mkdir -p "$DMG_MOUNT_DIR"
  hdiutil attach "$input_dmg" -nobrowse -readonly -mountpoint "$DMG_MOUNT_DIR"
  codesign --verify --deep --strict --verbose=2 "$DMG_MOUNT_DIR/$APP_NAME.app"
  test -L "$DMG_MOUNT_DIR/Applications"
  hdiutil detach "$DMG_MOUNT_DIR"
  rm -rf "$DMG_MOUNT_DIR"
}

cleanup() {
  if hdiutil info | grep -Fq "$DMG_MOUNT_DIR"; then
    hdiutil detach "$DMG_MOUNT_DIR" >/dev/null 2>&1 || true
  fi
  rm -rf "$DMG_STAGING_DIR" "$DMG_MOUNT_DIR" "$UNZIP_CHECK_DIR"
}

trap cleanup EXIT

cd "$ROOT_DIR"
mkdir -p "$DIST_DIR"
rm -rf "$APP_BUNDLE" "$ZIP_PATH" "$DMG_PATH" "$SIGNED_ZIP_PATH" "$SIGNED_DMG_PATH" "$NOTARY_ZIP_PATH"

detect_signing_identity
detect_team_id

build_args=(
  -project "$PROJECT"
  -scheme "$SCHEME"
  -configuration "$CONFIGURATION"
  -derivedDataPath "$DERIVED_DATA"
  CODE_SIGNING_ALLOWED=YES
  CODE_SIGNING_REQUIRED=YES
  CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO
  CODE_SIGN_STYLE=Manual
  CODE_SIGN_IDENTITY="$SIGN_IDENTITY"
  ENABLE_HARDENED_RUNTIME=YES
  OTHER_CODE_SIGN_FLAGS="--timestamp"
)

if [[ -n "$TEAM_ID" ]]; then
  build_args+=(DEVELOPMENT_TEAM="$TEAM_ID")
fi

xcodebuild \
  "${build_args[@]}" \
  clean build

codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
codesign -dvv "$APP_BUNDLE"

if [[ -n "$NOTARY_PROFILE" ]]; then
  make_zip "$APP_BUNDLE" "$NOTARY_ZIP_PATH"
  verify_zip_signature "$NOTARY_ZIP_PATH"
  xcrun notarytool submit "$NOTARY_ZIP_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$APP_BUNDLE"
  xcrun stapler validate "$APP_BUNDLE"
  spctl -a -vv "$APP_BUNDLE"

  make_zip "$APP_BUNDLE" "$ZIP_PATH"
  verify_zip_signature "$ZIP_PATH"

  make_dmg "$APP_BUNDLE" "$DMG_PATH"
  codesign --force --sign "$SIGN_IDENTITY" --timestamp "$DMG_PATH"
  xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG_PATH"
  xcrun stapler validate "$DMG_PATH"
  spctl -a -vv --type open --context context:primary-signature "$DMG_PATH"
  verify_dmg "$DMG_PATH"

  echo "Release zip: $ZIP_PATH"
  echo "Release dmg: $DMG_PATH"
else
  make_zip "$APP_BUNDLE" "$SIGNED_ZIP_PATH"
  verify_zip_signature "$SIGNED_ZIP_PATH"
  make_dmg "$APP_BUNDLE" "$DMG_PATH"
  codesign --force --sign "$SIGN_IDENTITY" --timestamp "$DMG_PATH"
  verify_dmg "$DMG_PATH"
  cat <<EOF

Built and Developer ID signed:
  $APP_BUNDLE

Signed artifacts:
  $SIGNED_ZIP_PATH
  $DMG_PATH

Notarization was skipped because NOTARY_PROFILE is empty. To notarize before shipping:
  NOTARY_PROFILE=claude-usage-notary ./script/package_release.sh

EOF
fi
