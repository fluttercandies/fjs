#!/bin/sh
set -eu

REQUIRE_XCFRAMEWORK=0

usage() {
  cat <<'USAGE'
Usage: tool/check_darwin_package_support.sh [--require-xcframework]

Checks the shared Darwin CocoaPods and Swift Package Manager package structure.
Pass --require-xcframework in release validation after generating
darwin/fjs/Binaries/fjs.xcframework.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --require-xcframework)
      REQUIRE_XCFRAMEWORK=1
      shift
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

fail() {
  echo "error: $*" >&2
  exit 1
}

require_file() {
  [ -f "$1" ] || fail "missing file: $1"
}

require_contains() {
  file="$1"
  text="$2"
  grep -F -- "$text" "$file" >/dev/null || fail "$file does not contain: $text"
}

require_plist_version() {
  plist="$1"
  require_contains "$plist" "<key>CFBundleShortVersionString</key>"
  require_contains "$plist" "<key>CFBundleVersion</key>"
  require_contains "$plist" "<string>$PACKAGE_VERSION</string>"
}

PACKAGE_VERSION="$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml | head -n 1)"
[ -n "$PACKAGE_VERSION" ] || fail "unable to read package version from pubspec.yaml"

require_file "darwin/fjs/Package.swift"
require_file "darwin/fjs.podspec"
require_file "darwin/fjs/Binaries/.gitkeep"
require_file ".pubignore"
require_file "tool/build_fjs_xcframework.sh"
require_file "tool/prepare_darwin_release.sh"

require_contains "pubspec.yaml" "sharedDarwinSource: true"
require_contains "darwin/fjs/Package.swift" ".package(name: \"FlutterFramework\", path: \"../FlutterFramework\")"
require_contains "darwin/fjs/Package.swift" ".binaryTarget("
require_contains "darwin/fjs/Package.swift" "fjs.xcframework"
require_contains "darwin/fjs.podspec" "s.ios.deployment_target = '12.0'"
require_contains "darwin/fjs.podspec" "s.osx.deployment_target = '10.14'"
require_contains "darwin/fjs.podspec" "s.ios.dependency 'Flutter'"
require_contains "darwin/fjs.podspec" "s.osx.dependency 'FlutterMacOS'"
require_contains "darwin/fjs.podspec" "cargokit/build_pod.sh"
require_contains "tool/build_fjs_xcframework.sh" "xcodebuild -create-xcframework"
require_contains "tool/build_fjs_xcframework.sh" "CARGOKIT_DARWIN_PLATFORM_NAME"
require_contains "tool/build_fjs_xcframework.sh" "libfjs.dylib"
require_contains "tool/build_fjs_xcframework.sh" "CFBundlePackageType"
require_contains "tool/build_fjs_xcframework.sh" "MACOSX_DEPLOYMENT_TARGET"
require_contains "tool/build_fjs_xcframework.sh" "swift package compute-checksum"
require_contains "tool/prepare_darwin_release.sh" "--require-xcframework"
require_contains "tool/prepare_darwin_release.sh" "flutter pub publish --dry-run"
require_contains ".gitignore" "/darwin/fjs/Binaries/fjs.xcframework/"
require_contains ".pubignore" "/docs/"
require_contains "darwin/fjs.podspec" "s.version          = '$PACKAGE_VERSION'"
require_contains "ios/fjs.podspec" "s.version          = '$PACKAGE_VERSION'"
require_contains "macos/fjs.podspec" "s.version          = '$PACKAGE_VERSION'"
require_contains "tool/build_fjs_xcframework.sh" "PACKAGE_VERSION="
require_contains "tool/build_fjs_xcframework.sh" "BUNDLE_SHORT_VERSION="
require_contains "tool/build_fjs_xcframework.sh" "BUNDLE_VERSION="
require_contains "tool/build_fjs_xcframework.sh" "<string>\$BUNDLE_SHORT_VERSION</string>"
require_contains "tool/build_fjs_xcframework.sh" "<string>\$BUNDLE_VERSION</string>"
if grep -F "/release/release" tool/build_fjs_xcframework.sh >/dev/null; then
  fail "tool/build_fjs_xcframework.sh contains duplicate release path segments"
fi
if grep -F "fjs.xcframework" .pubignore >/dev/null; then
  fail ".pubignore must not exclude fjs.xcframework; SwiftPM needs it in pub archives"
fi

if [ "$REQUIRE_XCFRAMEWORK" -eq 1 ]; then
  [ -d "darwin/fjs/Binaries/fjs.xcframework" ] ||
    fail "missing SwiftPM binary artifact: darwin/fjs/Binaries/fjs.xcframework"
fi

if [ -d "darwin/fjs/Binaries/fjs.xcframework" ]; then
  require_file "darwin/fjs/Binaries/fjs.xcframework/ios-arm64/fjs.framework/fjs"
  require_file "darwin/fjs/Binaries/fjs.xcframework/ios-arm64/fjs.framework/Info.plist"
  require_plist_version "darwin/fjs/Binaries/fjs.xcframework/ios-arm64/fjs.framework/Info.plist"
  require_file "darwin/fjs/Binaries/fjs.xcframework/ios-arm64_x86_64-simulator/fjs.framework/fjs"
  require_file "darwin/fjs/Binaries/fjs.xcframework/ios-arm64_x86_64-simulator/fjs.framework/Info.plist"
  require_plist_version "darwin/fjs/Binaries/fjs.xcframework/ios-arm64_x86_64-simulator/fjs.framework/Info.plist"
  require_file "darwin/fjs/Binaries/fjs.xcframework/macos-arm64_x86_64/fjs.framework/Versions/A/fjs"
  require_file "darwin/fjs/Binaries/fjs.xcframework/macos-arm64_x86_64/fjs.framework/Versions/A/Resources/Info.plist"
  require_plist_version "darwin/fjs/Binaries/fjs.xcframework/macos-arm64_x86_64/fjs.framework/Versions/A/Resources/Info.plist"
  [ -L "darwin/fjs/Binaries/fjs.xcframework/macos-arm64_x86_64/fjs.framework/Versions/Current" ] ||
    fail "macOS fjs.framework must be versioned with Versions/Current symlink"
  [ -L "darwin/fjs/Binaries/fjs.xcframework/macos-arm64_x86_64/fjs.framework/fjs" ] ||
    fail "macOS fjs.framework binary must be a symlink to Versions/Current/fjs"
  (cd darwin/fjs && swift package dump-package >/dev/null) ||
    fail "darwin/fjs/Package.swift cannot consume Binaries/fjs.xcframework"
fi

if [ "$REQUIRE_XCFRAMEWORK" -eq 1 ]; then
  echo "Darwin package support and SwiftPM binary artifact are present."
else
  echo "Darwin package support structure is present."
fi
