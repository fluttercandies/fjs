#!/bin/sh
set -eu

RUN_STRUCTURE=1
REQUIRE_CHECKSUM=0
ARTIFACT=""
PACKAGE_ARTIFACT="darwin/fjs/Binaries/fjs.xcframework.zip"

usage() {
  cat <<'USAGE'
Usage: tool/check_darwin_package_support.sh [--artifact PATH | --require-artifact]

Checks Darwin package structure by default. --artifact validates only the
exact supplied XCFramework zip. --require-artifact checks both structure and
the package-local darwin/fjs/Binaries/fjs.xcframework.zip.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact)
      [ "$#" -ge 2 ] || {
        usage >&2
        exit 2
      }
      RUN_STRUCTURE=0
      ARTIFACT="$2"
      shift 2
      ;;
    --require-artifact)
      ARTIFACT="$PACKAGE_ARTIFACT"
      REQUIRE_CHECKSUM=1
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
  required_text="$2"
  grep -F -- "$required_text" "$file" >/dev/null ||
    fail "$file does not contain: $required_text"
}

require_exact_line() {
  file="$1"
  required_text="$2"
  grep -Fx -- "$required_text" "$file" >/dev/null ||
    fail "$file does not contain the exact line: $required_text"
}

CALLER_DIR="$(pwd)"
ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
case "$ARTIFACT" in
  "") ;;
  /*) ;;
  *) ARTIFACT="$CALLER_DIR/$ARTIFACT" ;;
esac
cd "$ROOT_DIR"

PACKAGE_VERSION="$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml | head -n 1)"
[ -n "$PACKAGE_VERSION" ] || fail "unable to read package version from pubspec.yaml"
EXPECTED_FRB_CONTENT_HASH=-2005216402

check_version_invariants() {
  [ "$PACKAGE_VERSION" = "3.3.0" ] ||
    fail "pubspec.yaml version must be 3.3.0, found $PACKAGE_VERSION"

  cargo_version="$(awk '
    /^\[package\]$/ { in_package = 1; next }
    in_package && /^version = / {
      value = $0
      sub(/^version = "/, "", value)
      sub(/"$/, "", value)
      print value
      exit
    }
  ' libfjs/Cargo.toml)"
  [ "$cargo_version" = "$PACKAGE_VERSION" ] ||
    fail "libfjs/Cargo.toml version $cargo_version does not match $PACKAGE_VERSION"

  lock_version="$(awk '
    BEGIN { RS = ""; FS = "\n" }
    {
      name = ""
      version = ""
      for (i = 1; i <= NF; i++) {
        if ($i ~ /^name = "fjs"$/) name = "fjs"
        if ($i ~ /^version = "/) {
          version = $i
          sub(/^version = "/, "", version)
          sub(/"$/, "", version)
        }
      }
      if (name == "fjs") {
        print version
        exit
      }
    }
  ' libfjs/Cargo.lock)"
  [ "$lock_version" = "$PACKAGE_VERSION" ] ||
    fail "libfjs/Cargo.lock FJS version $lock_version does not match $PACKAGE_VERSION"

  example_lock_version="$(awk '
    /^  fjs:$/ { in_fjs = 1; next }
    in_fjs && /^  [^ ]/ { exit }
    in_fjs && /^    version: / {
      value = $0
      sub(/^    version: /, "", value)
      gsub(/\"/, "", value)
      print value
      exit
    }
  ' example/pubspec.lock)"
  [ "$example_lock_version" = "$PACKAGE_VERSION" ] ||
    fail "example/pubspec.lock FJS version $example_lock_version does not match $PACKAGE_VERSION"

  for podspec in darwin/fjs.podspec ios/fjs.podspec macos/fjs.podspec; do
    podspec_version="$(sed -n "s/^[[:space:]]*s\.version[[:space:]]*=[[:space:]]*'\([^']*\)'.*/\1/p" "$podspec" | head -n 1)"
    [ "$podspec_version" = "$PACKAGE_VERSION" ] ||
      fail "$podspec version $podspec_version does not match $PACKAGE_VERSION"
  done
}

check_structure() {
  require_file "darwin/fjs/Package.swift"
  require_file "darwin/fjs.podspec"
  require_file "darwin/fjs/Binaries/.gitkeep"
  require_file ".pubignore"
  require_file "tool/build_fjs_xcframework.sh"
  require_file "tool/check_frb_content_hash.dart"
  require_file "tool/prepare_darwin_release.sh"

  require_contains "pubspec.yaml" "sharedDarwinSource: true"
  require_contains "darwin/fjs/Package.swift" ".package(name: \"FlutterFramework\", path: \"../FlutterFramework\")"
  require_contains "darwin/fjs/Package.swift" ".binaryTarget("
  require_contains "darwin/fjs/Package.swift" "path: \"Binaries/fjs.xcframework.zip\""
  require_contains "README.md" "darwin/fjs/Binaries/fjs.xcframework.zip"
  if grep -F 'path: "Binaries/fjs.xcframework"' darwin/fjs/Package.swift >/dev/null; then
    fail "Package.swift must consume the package-local zip, not a raw XCFramework"
  fi
  require_contains "libfjs/src/api/value.rs" "#[frb(ignore)]"
  awk '
    /#\[frb\(ignore\)\]/ { ignore_line = NR; next }
    /struct ConversionState/ && ignore_line > 0 && NR - ignore_line <= 2 { found = 1 }
    END { exit !found }
  ' libfjs/src/api/value.rs ||
    fail "private ConversionState must be annotated with #[frb(ignore)]"
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
  if grep -F "source_dylibs" tool/build_fjs_xcframework.sh >/dev/null ||
    grep -F "SC2086" tool/build_fjs_xcframework.sh >/dev/null; then
    fail "tool/build_fjs_xcframework.sh must pass quoted lipo input paths"
  fi
  require_contains "tool/build_fjs_xcframework.sh" 'lipo -create "$first_dylib" "$second_dylib"'
  require_contains "tool/build_fjs_xcframework.sh" "zip -qry -y"
  require_contains "tool/build_fjs_xcframework.sh" "check_darwin_package_support.sh\" --artifact \"\$ZIP_TEMP"
  require_contains "tool/build_fjs_xcframework.sh" "mv -f \"\$ZIP_TEMP\" \"\$ZIP_OUTPUT\""
  awk '
    /check_darwin_package_support\.sh" --artifact "\$ZIP_TEMP/ { validation_line = NR }
    /swift package compute-checksum "\$ZIP_TEMP"/ { checksum_line = NR }
    /mv -f "\$ZIP_TEMP" "\$ZIP_OUTPUT"/ { move_line = NR }
    END {
      if (validation_line <= 0 || checksum_line <= 0 ||
          move_line <= validation_line || move_line <= checksum_line) exit 1
    }
  ' tool/build_fjs_xcframework.sh ||
    fail "temporary zip must be validated and checksummed before final moves"
  require_contains "tool/build_fjs_xcframework.sh" "swift package compute-checksum"
  if grep -F 'rm -f "$ZIP_OUTPUT"' tool/build_fjs_xcframework.sh >/dev/null; then
    fail "tool/build_fjs_xcframework.sh must not delete the previous final archive"
  fi
  require_contains "tool/prepare_darwin_release.sh" "--require-artifact"
  require_contains "tool/prepare_darwin_release.sh" "check_frb_codegen.sh"
  require_contains "tool/prepare_darwin_release.sh" "flutter pub publish --dry-run"
  if grep -F -- "--ignore-warnings" tool/prepare_darwin_release.sh >/dev/null; then
    fail "release preparation must not ignore pub publish warnings"
  fi
  require_exact_line "tool/check_darwin_package_support.sh" "EXPECTED_FRB_CONTENT_HASH=-2005216402"
  awk '
    /dart run tool\/check_frb_content_hash\.dart .*"\$EXPECTED_FRB_CONTENT_HASH"/ { found = 1 }
    END { exit !found }
  ' tool/check_darwin_package_support.sh ||
    fail "artifact validation must enforce EXPECTED_FRB_CONTENT_HASH"
  require_exact_line ".gitignore" "/darwin/fjs/Binaries/fjs.xcframework/"
  require_exact_line ".gitignore" "/darwin/fjs/Binaries/fjs.xcframework.zip"
  require_exact_line ".gitignore" "/darwin/fjs/Binaries/fjs.xcframework.zip.checksum"
  require_exact_line ".pubignore" "/darwin/fjs/Binaries/fjs.xcframework/"
  require_exact_line ".pubignore" "/darwin/fjs/Binaries/fjs.xcframework.zip.checksum"
  require_exact_line ".pubignore" "/docs/"
  if grep -Fx '/darwin/fjs/Binaries/fjs.xcframework.zip' .pubignore >/dev/null; then
    fail ".pubignore must include darwin/fjs/Binaries/fjs.xcframework.zip"
  fi
  if grep -Fx '/darwin/fjs/Binaries/' .pubignore >/dev/null ||
    grep -Fx '/darwin/fjs/Binaries/*' .pubignore >/dev/null; then
    fail ".pubignore must not exclude the entire Binaries directory"
  fi
  require_contains "tool/build_fjs_xcframework.sh" "PACKAGE_VERSION="
  require_contains "tool/build_fjs_xcframework.sh" "BUNDLE_SHORT_VERSION="
  require_contains "tool/build_fjs_xcframework.sh" "BUNDLE_VERSION="
  require_contains "tool/build_fjs_xcframework.sh" "<string>\$BUNDLE_SHORT_VERSION</string>"
  require_contains "tool/build_fjs_xcframework.sh" "<string>\$BUNDLE_VERSION</string>"
  if grep -F "/release/release" tool/build_fjs_xcframework.sh >/dev/null; then
    fail "tool/build_fjs_xcframework.sh contains duplicate release path segments"
  fi

  check_version_invariants
}

require_plist_version() {
  plist="$1"
  short_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$plist" 2>/dev/null)" ||
    fail "$plist is missing CFBundleShortVersionString"
  bundle_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$plist" 2>/dev/null)" ||
    fail "$plist is missing CFBundleVersion"
  [ "$short_version" = "$PACKAGE_VERSION" ] ||
    fail "$plist CFBundleShortVersionString is $short_version, expected $PACKAGE_VERSION"
  [ "$bundle_version" = "$PACKAGE_VERSION" ] ||
    fail "$plist CFBundleVersion is $bundle_version, expected $PACKAGE_VERSION"
}

require_architectures() {
  binary="$1"
  expected="$2"
  actual="$(lipo -archs "$binary")" || fail "unable to inspect architectures in $binary"
  actual_sorted="$(printf '%s\n' $actual | sort | tr '\n' ' ' | sed 's/ $//')"
  expected_sorted="$(printf '%s\n' $expected | sort | tr '\n' ' ' | sed 's/ $//')"
  [ "$actual_sorted" = "$expected_sorted" ] ||
    fail "$binary architectures are '$actual', expected '$expected'"
}

require_symlink() {
  link="$1"
  expected_target="$2"
  [ -L "$link" ] || fail "$link must be a symbolic link"
  actual_target="$(readlink "$link")"
  [ "$actual_target" = "$expected_target" ] ||
    fail "$link points to '$actual_target', expected '$expected_target'"
}

require_artifact_checksum() {
  artifact="$1"
  sidecar="$artifact.checksum"
  require_file "$sidecar"
  recorded_checksum="$(cat "$sidecar")"
  if ! printf '%s\n' "$recorded_checksum" | grep -Eq '^[0-9a-f]{64}$'; then
    fail "malformed SwiftPM checksum sidecar: $sidecar"
  fi
  computed_checksum="$(swift package compute-checksum "$artifact")" ||
    fail "unable to compute SwiftPM checksum for $artifact"
  [ "$recorded_checksum" = "$computed_checksum" ] ||
    fail "stale SwiftPM checksum sidecar for $artifact: recorded $recorded_checksum, computed $computed_checksum"
}

require_exported_hash_symbol() {
  binary="$1"
  architecture="$2"
  symbols="$(nm -arch "$architecture" -gU "$binary")" ||
    fail "unable to inspect exported symbols in $binary ($architecture)"
  symbol_count="$(printf '%s\n' "$symbols" | awk '
    $NF == "_frb_get_rust_content_hash" { count++ }
    END { print count + 0 }
  ')"
  [ "$symbol_count" -eq 1 ] ||
    fail "$binary ($architecture) must export exactly one _frb_get_rust_content_hash symbol"
}

require_install_name() {
  binary="$1"
  architecture="$2"
  install_names="$(otool -arch "$architecture" -D "$binary")" ||
    fail "unable to inspect LC_ID_DYLIB in $binary ($architecture)"
  install_name="$(printf '%s\n' "$install_names" | sed -n '2p')"
  extra_install_name="$(printf '%s\n' "$install_names" | sed -n '3p')"
  [ "$install_name" = "@rpath/fjs.framework/fjs" ] && [ -z "$extra_install_name" ] ||
    fail "$binary ($architecture) LC_ID_DYLIB is '$install_name', expected '@rpath/fjs.framework/fjs'"
}

require_build_version() {
  binary="$1"
  architecture="$2"
  expected_platform="$3"
  expected_minos="$4"
  build_version="$(vtool -arch "$architecture" -show-build "$binary")" ||
    fail "unable to inspect LC_BUILD_VERSION in $binary ($architecture)"
  platform="$(printf '%s\n' "$build_version" | awk '$1 == "platform" { print $2; exit }')"
  minos="$(printf '%s\n' "$build_version" | awk '$1 == "minos" { print $2; exit }')"
  [ "$platform" = "$expected_platform" ] ||
    fail "$binary ($architecture) platform is '$platform', expected '$expected_platform'"
  [ "$minos" = "$expected_minos" ] ||
    fail "$binary ($architecture) minos is '$minos', expected '$expected_minos'"
}

require_macho_slice() {
  binary="$1"
  architecture="$2"
  expected_platform="$3"
  expected_minos="$4"
  require_exported_hash_symbol "$binary" "$architecture"
  require_install_name "$binary" "$architecture"
  require_build_version "$binary" "$architecture" "$expected_platform" "$expected_minos"
  dart run tool/check_frb_content_hash.dart \
    --otool-arch "$architecture" "$binary" "$EXPECTED_FRB_CONTENT_HASH" ||
    fail "$binary ($architecture) FRB content hash does not match generated bindings"
}

TEMP_DIR=""
cleanup() {
  if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
  fi
}
trap cleanup EXIT
trap 'exit 130' HUP INT TERM

check_artifact() {
  artifact="$1"
  [ -f "$artifact" ] || fail "missing SwiftPM zip artifact: $artifact"
  case "$artifact" in
    *.zip) ;;
    *) fail "SwiftPM artifact must be a zip file: $artifact" ;;
  esac

  TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/fjs-darwin-check.XXXXXX")"
  extracted="$TEMP_DIR/extracted"
  mkdir -p "$extracted"
  unzip -q "$artifact" -d "$extracted" || fail "unable to extract artifact: $artifact"

  xcframework="$extracted/fjs.xcframework"
  require_file "$xcframework/Info.plist"
  ios_framework="$xcframework/ios-arm64/fjs.framework"
  simulator_framework="$xcframework/ios-arm64_x86_64-simulator/fjs.framework"
  macos_framework="$xcframework/macos-arm64_x86_64/fjs.framework"
  require_file "$ios_framework/fjs"
  require_file "$ios_framework/Info.plist"
  require_file "$simulator_framework/fjs"
  require_file "$simulator_framework/Info.plist"
  require_file "$macos_framework/Versions/A/fjs"
  require_file "$macos_framework/Versions/A/Resources/Info.plist"

  require_plist_version "$ios_framework/Info.plist"
  require_plist_version "$simulator_framework/Info.plist"
  require_plist_version "$macos_framework/Versions/A/Resources/Info.plist"
  require_architectures "$ios_framework/fjs" "arm64"
  require_architectures "$simulator_framework/fjs" "arm64 x86_64"
  require_architectures "$macos_framework/Versions/A/fjs" "arm64 x86_64"

  require_symlink "$macos_framework/Versions/Current" "A"
  require_symlink "$macos_framework/fjs" "Versions/Current/fjs"
  require_symlink "$macos_framework/Headers" "Versions/Current/Headers"
  require_symlink "$macos_framework/Modules" "Versions/Current/Modules"
  require_symlink "$macos_framework/Resources" "Versions/Current/Resources"

  require_macho_slice "$ios_framework/fjs" "arm64" "IOS" "12.0"
  require_macho_slice "$simulator_framework/fjs" "x86_64" "IOSSIMULATOR" "12.0"
  require_macho_slice "$simulator_framework/fjs" "arm64" "IOSSIMULATOR" "14.0"
  require_macho_slice "$macos_framework/Versions/A/fjs" "x86_64" "MACOS" "10.14"
  require_macho_slice "$macos_framework/Versions/A/fjs" "arm64" "MACOS" "11.0"

  dart run tool/check_frb_content_hash.dart "$macos_framework/Versions/A/fjs" "$EXPECTED_FRB_CONTENT_HASH" ||
    fail "host macOS binary FRB content hash does not match generated bindings"

  fixture="$TEMP_DIR/fixture"
  mkdir -p "$fixture/fjs/Binaries" "$fixture/FlutterFramework/Sources/FlutterFramework"
  cp darwin/fjs/Package.swift "$fixture/fjs/Package.swift"
  cp -R darwin/fjs/Sources "$fixture/fjs/Sources"
  cp "$artifact" "$fixture/fjs/Binaries/fjs.xcframework.zip"
  cat > "$fixture/FlutterFramework/Package.swift" <<'SWIFT_PACKAGE'
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FlutterFramework",
    products: [
        .library(name: "FlutterFramework", targets: ["FlutterFramework"])
    ],
    targets: [
        .target(name: "FlutterFramework")
    ]
)
SWIFT_PACKAGE
  cat > "$fixture/FlutterFramework/Sources/FlutterFramework/FlutterFramework.swift" <<'SWIFT_SOURCE'
public enum FlutterFrameworkStub {}
SWIFT_SOURCE

  swift package resolve --package-path "$fixture/fjs" ||
    fail "SwiftPM could not resolve the exact zip artifact"
  swift build --package-path "$fixture/fjs" --target FjsPlugin ||
    fail "SwiftPM could not build FjsPlugin from the exact zip artifact"

  echo "Darwin SwiftPM artifact is valid: $artifact"
}

if [ "$RUN_STRUCTURE" -eq 1 ]; then
  check_structure
  echo "Darwin package support structure is valid."
fi

if [ -n "$ARTIFACT" ]; then
  if [ "$REQUIRE_CHECKSUM" -eq 1 ]; then
    require_artifact_checksum "$ARTIFACT"
  fi
  check_artifact "$ARTIFACT"
fi
