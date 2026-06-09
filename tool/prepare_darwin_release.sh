#!/bin/sh
set -eu

usage() {
  cat <<'USAGE'
Usage: tool/prepare_darwin_release.sh [--configuration Debug|Release] [--artifact-dir PATH]

Builds the SwiftPM fjs.xcframework, creates a GitHub Release-ready zip and
checksum, then validates CocoaPods, SwiftPM, and pub packaging.
USAGE
}

CONFIGURATION=Release
ARTIFACT_DIR=""

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
    --artifact-dir)
      [ "$#" -ge 2 ] || {
        usage >&2
        exit 2
      }
      ARTIFACT_DIR="$2"
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

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
if [ -z "$ARTIFACT_DIR" ]; then
  ARTIFACT_DIR="$ROOT_DIR/build/darwin-release"
fi

mkdir -p "$ARTIFACT_DIR"

"$ROOT_DIR/tool/build_fjs_xcframework.sh" \
  --configuration "$CONFIGURATION" \
  --output "$ROOT_DIR/darwin/fjs/Binaries" \
  --zip-output "$ARTIFACT_DIR/fjs.xcframework.zip"

"$ROOT_DIR/tool/check_darwin_package_support.sh" --require-xcframework
pod ipc spec "$ROOT_DIR/darwin/fjs.podspec" >/dev/null
flutter pub publish --dry-run

echo "Darwin release artifact: $ARTIFACT_DIR/fjs.xcframework.zip"
echo "SwiftPM checksum: $(cat "$ARTIFACT_DIR/fjs.xcframework.zip.checksum")"
