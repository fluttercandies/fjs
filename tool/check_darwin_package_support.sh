#!/bin/sh
set -eu

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
  grep -F "$text" "$file" >/dev/null || fail "$file does not contain: $text"
}

require_file "darwin/fjs/Package.swift"
require_file "darwin/fjs.podspec"
require_file "darwin/fjs/Binaries/.gitkeep"
require_file ".pubignore"
require_file "tool/build_fjs_xcframework.sh"

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
require_contains ".gitignore" "/darwin/fjs/Binaries/fjs.xcframework/"
require_contains ".pubignore" "/docs/superpowers/"
if grep -F "/release/release" tool/build_fjs_xcframework.sh >/dev/null; then
  fail "tool/build_fjs_xcframework.sh contains duplicate release path segments"
fi
if grep -F "fjs.xcframework" .pubignore >/dev/null; then
  fail ".pubignore must not exclude fjs.xcframework; SwiftPM needs it in pub archives"
fi
require_contains "macos/fjs.podspec" "s.version          = '2.2.0'"

echo "Darwin package support structure is present."
