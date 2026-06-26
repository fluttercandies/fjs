#!/bin/sh
set -eu

usage() {
  cat <<'USAGE'
Usage: tool/build_fjs_xcframework.sh [--configuration Debug|Release] [--output PATH] [--zip-output PATH]

Builds the fjs Rust dynamic libraries for iOS, iOS Simulator, and macOS, then
packages them as an XCFramework for Swift Package Manager:

  darwin/fjs/Binaries/fjs.xcframework

The script uses the existing Cargokit build tool so CocoaPods and SwiftPM share
the same Rust build inputs. When --zip-output is provided, it also writes a
SwiftPM release zip and a sidecar .checksum file.
USAGE
}

CONFIGURATION=Release
OUTPUT_DIR=""
ZIP_OUTPUT=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --configuration)
      [ "$#" -ge 2 ] || {
        usage >&2
        exit 2
      }
      CONFIGURATION="$2"
      shift 2
      ;;
    --output)
      [ "$#" -ge 2 ] || {
        usage >&2
        exit 2
      }
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --zip-output)
      [ "$#" -ge 2 ] || {
        usage >&2
        exit 2
      }
      ZIP_OUTPUT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
done

case "$CONFIGURATION" in
  Debug)
    RUST_CONFIGURATION=debug
    ;;
  Release)
    RUST_CONFIGURATION=release
    ;;
  *)
    echo "error: --configuration must be Debug or Release" >&2
    exit 2
    ;;
esac

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
PACKAGE_VERSION="$(sed -n 's/^version:[[:space:]]*//p' "$ROOT_DIR/pubspec.yaml" | head -n 1)"
if [ -z "$PACKAGE_VERSION" ]; then
  echo "error: unable to read package version from pubspec.yaml" >&2
  exit 1
fi
BUNDLE_SHORT_VERSION="${PACKAGE_VERSION%%+*}"
if [ "$BUNDLE_SHORT_VERSION" = "$PACKAGE_VERSION" ]; then
  BUNDLE_VERSION="$PACKAGE_VERSION"
else
  BUNDLE_VERSION="${PACKAGE_VERSION#*+}"
fi
if ! printf '%s\n' "$BUNDLE_SHORT_VERSION" | grep -Eq '^[0-9]+(\.[0-9]+){0,2}$'; then
  echo "error: pubspec version '$PACKAGE_VERSION' has Apple-incompatible marketing version '$BUNDLE_SHORT_VERSION'" >&2
  exit 1
fi
if ! printf '%s\n' "$BUNDLE_VERSION" | grep -Eq '^[0-9]+(\.[0-9]+){0,2}$'; then
  echo "error: pubspec version '$PACKAGE_VERSION' has Apple-incompatible build version '$BUNDLE_VERSION'" >&2
  exit 1
fi
if [ -z "$OUTPUT_DIR" ]; then
  OUTPUT_DIR="$ROOT_DIR/darwin/fjs/Binaries"
fi
if [ -n "$ZIP_OUTPUT" ]; then
  case "$ZIP_OUTPUT" in
    /*) ;;
    *) ZIP_OUTPUT="$(pwd)/$ZIP_OUTPUT" ;;
  esac
fi
BUILD_ROOT="$ROOT_DIR/build/darwin-xcframework"
MANIFEST_DIR="$ROOT_DIR/libfjs"
TOOL_TEMP_DIR="$BUILD_ROOT/build_tool"
FRAMEWORK_BUILD_DIR="$BUILD_ROOT/frameworks"
XCFRAMEWORK="$OUTPUT_DIR/fjs.xcframework"
USER_OPTIONS_DIR="$BUILD_ROOT/options"

build_platform() {
  platform_name="$1"
  archs="$2"
  output_name="$3"
  deployment_target="$4"

  target_temp_dir="$BUILD_ROOT/$output_name/temp"
  platform_output_dir="$BUILD_ROOT/$output_name/out"

  rm -rf "$target_temp_dir" "$platform_output_dir"
  mkdir -p "$target_temp_dir" "$platform_output_dir"
  mkdir -p "$USER_OPTIONS_DIR"
  cat > "$USER_OPTIONS_DIR/cargokit_options.yaml" <<'EOF'
use_precompiled_binaries: false
EOF

  CARGOKIT_DARWIN_PLATFORM_NAME="$platform_name" \
  CARGOKIT_DARWIN_ARCHS="$archs" \
  CARGOKIT_CONFIGURATION="$CONFIGURATION" \
  CARGOKIT_MANIFEST_DIR="$MANIFEST_DIR" \
  CARGOKIT_TARGET_TEMP_DIR="$target_temp_dir" \
  CARGOKIT_OUTPUT_DIR="$platform_output_dir" \
  CARGOKIT_TOOL_TEMP_DIR="$TOOL_TEMP_DIR" \
  CARGOKIT_ROOT_PROJECT_DIR="$USER_OPTIONS_DIR" \
  IPHONEOS_DEPLOYMENT_TARGET="$deployment_target" \
  MACOSX_DEPLOYMENT_TARGET="$deployment_target" \
    sh "$ROOT_DIR/cargokit/run_build_tool.sh" build-pod "$MANIFEST_DIR" fjs
}

create_framework() {
  platform_output_name="$1"
  minimum_os_version="$2"
  framework_style="$3"
  shift 3

  framework_dir="$FRAMEWORK_BUILD_DIR/$platform_output_name/fjs.framework"
  framework_contents_dir="$framework_dir"
  framework_resources_dir="$framework_dir"
  if [ "$framework_style" = "versioned" ]; then
    framework_contents_dir="$framework_dir/Versions/A"
    framework_resources_dir="$framework_contents_dir/Resources"
  elif [ "$framework_style" != "shallow" ]; then
    echo "error: framework style must be shallow or versioned" >&2
    exit 2
  fi
  framework_binary="$framework_contents_dir/fjs"
  source_dylibs=""
  first_dylib=""

  for rust_target in "$@"; do
    candidate="$BUILD_ROOT/$platform_output_name/temp/$rust_target/$RUST_CONFIGURATION/libfjs.dylib"
    if [ ! -f "$candidate" ]; then
      echo "error: missing dynamic library: $candidate" >&2
      exit 1
    fi
    if [ -z "$first_dylib" ]; then
      first_dylib="$candidate"
    fi
    source_dylibs="$source_dylibs $candidate"
  done

  rm -rf "$framework_dir"
  mkdir -p "$framework_contents_dir/Headers" "$framework_contents_dir/Modules" "$framework_resources_dir"

  # shellcheck disable=SC2086
  if [ "$#" -eq 1 ]; then
    cp "$first_dylib" "$framework_binary"
  else
    # shellcheck disable=SC2086
    lipo -create $source_dylibs -output "$framework_binary"
  fi

  install_name_tool -id "@rpath/fjs.framework/fjs" "$framework_binary"

  cat > "$framework_resources_dir/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>fjs</string>
  <key>CFBundleIdentifier</key>
  <string>dev.fluttercandies.fjs.$platform_output_name</string>
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
  <string>$minimum_os_version</string>
</dict>
</plist>
EOF

  cat > "$framework_contents_dir/Headers/fjs.h" <<'EOF'
#pragma once
EOF

  cat > "$framework_contents_dir/Modules/module.modulemap" <<'EOF'
framework module fjs {
  umbrella header "fjs.h"
  export *
  module * { export * }
}
EOF

  if [ "$framework_style" = "versioned" ]; then
    ln -s A "$framework_dir/Versions/Current"
    ln -s Versions/Current/fjs "$framework_dir/fjs"
    ln -s Versions/Current/Headers "$framework_dir/Headers"
    ln -s Versions/Current/Modules "$framework_dir/Modules"
    ln -s Versions/Current/Resources "$framework_dir/Resources"
  fi
}

build_platform iphoneos arm64 ios 12.0
build_platform iphonesimulator "arm64 x86_64" ios-simulator 12.0
build_platform macosx "arm64 x86_64" macos 10.14

rm -rf "$XCFRAMEWORK"
mkdir -p "$OUTPUT_DIR"
rm -rf "$FRAMEWORK_BUILD_DIR"

create_framework ios 12.0 shallow aarch64-apple-ios
create_framework ios-simulator 12.0 shallow aarch64-apple-ios-sim x86_64-apple-ios
create_framework macos 10.14 versioned aarch64-apple-darwin x86_64-apple-darwin

xcodebuild -create-xcframework \
  -framework "$FRAMEWORK_BUILD_DIR/ios/fjs.framework" \
  -framework "$FRAMEWORK_BUILD_DIR/ios-simulator/fjs.framework" \
  -framework "$FRAMEWORK_BUILD_DIR/macos/fjs.framework" \
  -output "$XCFRAMEWORK"

echo "Created $XCFRAMEWORK"

if [ -n "$ZIP_OUTPUT" ]; then
  ZIP_OUTPUT_DIR="$(dirname -- "$ZIP_OUTPUT")"
  mkdir -p "$ZIP_OUTPUT_DIR"
  rm -f "$ZIP_OUTPUT" "$ZIP_OUTPUT.checksum"
  (
    cd "$OUTPUT_DIR"
    zip -qry "$ZIP_OUTPUT" fjs.xcframework
  )
  swift package compute-checksum "$ZIP_OUTPUT" > "$ZIP_OUTPUT.checksum"
  echo "Created $ZIP_OUTPUT"
  echo "Created $ZIP_OUTPUT.checksum"
fi
