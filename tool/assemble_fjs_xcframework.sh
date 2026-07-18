#!/bin/sh
set -eu

TARGET_ROOT="${CARGOKIT_TARGET_OUTPUT_ROOT:?CARGOKIT_TARGET_OUTPUT_ROOT is required}"
OUTPUT_ROOT="${CARGOKIT_OUTPUT_ROOT:?CARGOKIT_OUTPUT_ROOT is required}"
WORKSPACE_ROOT="${CARGOKIT_WORKSPACE_ROOT:?CARGOKIT_WORKSPACE_ROOT is required}"

IOS_MINIMUM=12.0
MACOS_MINIMUM=10.14
ARCHIVE_NAME=fjs.xcframework.zip
CHECKSUM_NAME=fjs.xcframework.zip.checksum

fail() {
  echo "error: $*" >&2
  exit 1
}

retained_dylib() {
  rust_target="$1"
  dylib="$TARGET_ROOT/$rust_target/${rust_target}_libfjs.dylib"
  [ -f "$dylib" ] || fail "missing retained dynamic library: $dylib"
  [ ! -L "$dylib" ] || fail "retained dynamic library must not be a symlink: $dylib"
  printf '%s\n' "$dylib"
}

IOS_DEVICE_DYLIB="$(retained_dylib aarch64-apple-ios)"
IOS_SIM_ARM_DYLIB="$(retained_dylib aarch64-apple-ios-sim)"
IOS_SIM_X64_DYLIB="$(retained_dylib x86_64-apple-ios)"
MACOS_ARM_DYLIB="$(retained_dylib aarch64-apple-darwin)"
MACOS_X64_DYLIB="$(retained_dylib x86_64-apple-darwin)"

PACKAGE_VERSION="$(sed -n 's/^version:[[:space:]]*//p' "$WORKSPACE_ROOT/pubspec.yaml" | head -n 1)"
[ -n "$PACKAGE_VERSION" ] || fail "unable to read package version from pubspec.yaml"
BUNDLE_SHORT_VERSION="${PACKAGE_VERSION%%+*}"
if [ "$BUNDLE_SHORT_VERSION" = "$PACKAGE_VERSION" ]; then
  BUNDLE_VERSION="$PACKAGE_VERSION"
else
  BUNDLE_VERSION="${PACKAGE_VERSION#*+}"
fi
printf '%s\n' "$BUNDLE_SHORT_VERSION" | grep -Eq '^[0-9]+(\.[0-9]+){0,2}$' ||
  fail "invalid Apple marketing version: $BUNDLE_SHORT_VERSION"
printf '%s\n' "$BUNDLE_VERSION" | grep -Eq '^[0-9]+(\.[0-9]+){0,2}$' ||
  fail "invalid Apple build version: $BUNDLE_VERSION"

mkdir -p "$OUTPUT_ROOT"
BUILD_DIR="$(mktemp -d "$OUTPUT_ROOT/.fjs-assemble.XXXXXX")"
cleanup() {
  rm -rf "$BUILD_DIR"
}
trap cleanup EXIT
trap 'exit 130' HUP INT TERM

FRAMEWORK_ROOT="$BUILD_DIR/frameworks"
XCFRAMEWORK="$BUILD_DIR/fjs.xcframework"
mkdir -p "$FRAMEWORK_ROOT"

create_framework() {
  platform_name="$1"
  minimum_version="$2"
  framework_style="$3"
  first_dylib="$4"
  second_dylib="${5:-}"

  framework_dir="$FRAMEWORK_ROOT/$platform_name/fjs.framework"
  contents_dir="$framework_dir"
  resources_dir="$framework_dir"
  if [ "$framework_style" = versioned ]; then
    contents_dir="$framework_dir/Versions/A"
    resources_dir="$contents_dir/Resources"
  elif [ "$framework_style" != shallow ]; then
    fail "unsupported framework style: $framework_style"
  fi

  mkdir -p "$contents_dir/Headers" "$contents_dir/Modules" "$resources_dir"
  framework_binary="$contents_dir/fjs"
  if [ -n "$second_dylib" ]; then
    lipo -create "$first_dylib" "$second_dylib" -output "$framework_binary"
  else
    cp "$first_dylib" "$framework_binary"
  fi
  install_name_tool -id "@rpath/fjs.framework/fjs" "$framework_binary"

  cat > "$resources_dir/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>fjs</string>
  <key>CFBundleIdentifier</key>
  <string>dev.fluttercandies.fjs.$platform_name</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>fjs</string>
  <key>CFBundlePackageType</key>
  <string>FMWK</string>
  <key>CFBundleShortVersionString</key>
  <string>$BUNDLE_SHORT_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUNDLE_VERSION</string>
  <key>MinimumOSVersion</key>
  <string>$minimum_version</string>
</dict>
</plist>
EOF

  cat > "$contents_dir/Headers/fjs.h" <<'EOF'
#pragma once
EOF
  cat > "$contents_dir/Modules/module.modulemap" <<'EOF'
framework module fjs {
  umbrella header "fjs.h"
  export *
  module * { export * }
}
EOF

  if [ "$framework_style" = versioned ]; then
    ln -s A "$framework_dir/Versions/Current"
    ln -s Versions/Current/fjs "$framework_dir/fjs"
    ln -s Versions/Current/Headers "$framework_dir/Headers"
    ln -s Versions/Current/Modules "$framework_dir/Modules"
    ln -s Versions/Current/Resources "$framework_dir/Resources"
  fi
}

create_framework ios "$IOS_MINIMUM" shallow "$IOS_DEVICE_DYLIB"
create_framework ios-simulator "$IOS_MINIMUM" shallow "$IOS_SIM_ARM_DYLIB" "$IOS_SIM_X64_DYLIB"
create_framework macos "$MACOS_MINIMUM" versioned "$MACOS_ARM_DYLIB" "$MACOS_X64_DYLIB"

xcodebuild -create-xcframework \
  -framework "$FRAMEWORK_ROOT/ios/fjs.framework" \
  -framework "$FRAMEWORK_ROOT/ios-simulator/fjs.framework" \
  -framework "$FRAMEWORK_ROOT/macos/fjs.framework" \
  -output "$XCFRAMEWORK"

find "$XCFRAMEWORK" ! -type l -exec touch -t 198001010000 {} +
find "$XCFRAMEWORK" -type l -exec touch -h -t 198001010000 {} +

ARCHIVE_TEMP="$BUILD_DIR/$ARCHIVE_NAME"
(
  cd "$BUILD_DIR"
  find fjs.xcframework -print | LC_ALL=C sort | zip -q -y -X "$ARCHIVE_TEMP" -@
)

"$WORKSPACE_ROOT/tool/check_darwin_package_support.sh" --artifact "$ARCHIVE_TEMP"
checksum="$(shasum -a 256 "$ARCHIVE_TEMP" | awk '{print $1}')"
printf '%s\n' "$checksum" | grep -Eq '^[0-9a-f]{64}$' ||
  fail "unable to compute lowercase SHA-256 checksum"
printf '%s\n' "$checksum" > "$BUILD_DIR/$CHECKSUM_NAME"

mv -f "$ARCHIVE_TEMP" "$OUTPUT_ROOT/$ARCHIVE_NAME"
mv -f "$BUILD_DIR/$CHECKSUM_NAME" "$OUTPUT_ROOT/$CHECKSUM_NAME"
