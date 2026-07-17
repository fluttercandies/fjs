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
case "$ARTIFACT_DIR" in
  /*) ;;
  *) ARTIFACT_DIR="$(pwd)/$ARTIFACT_DIR" ;;
esac

mkdir -p "$ARTIFACT_DIR"
PACKAGE_ZIP="$ROOT_DIR/darwin/fjs/Binaries/fjs.xcframework.zip"

"$ROOT_DIR/tool/check_frb_codegen.sh"

"$ROOT_DIR/tool/build_fjs_xcframework.sh" \
  --configuration "$CONFIGURATION" \
  --output "$ROOT_DIR/darwin/fjs/Binaries" \
  --zip-output "$PACKAGE_ZIP"

"$ROOT_DIR/tool/check_darwin_package_support.sh" --require-artifact

RELEASE_TEMP_DIR="$(mktemp -d "$ARTIFACT_DIR/.fjs-release.XXXXXX")"
cleanup_release_temp() {
  rm -rf "$RELEASE_TEMP_DIR"
}
trap cleanup_release_temp EXIT
trap 'exit 130' HUP INT TERM
cp "$PACKAGE_ZIP" "$RELEASE_TEMP_DIR/fjs.xcframework.zip"
cp "$PACKAGE_ZIP.checksum" "$RELEASE_TEMP_DIR/fjs.xcframework.zip.checksum"
cmp -s "$PACKAGE_ZIP" "$RELEASE_TEMP_DIR/fjs.xcframework.zip" || {
  echo "error: copied release zip differs from the validated package artifact" >&2
  exit 1
}
cmp -s "$PACKAGE_ZIP.checksum" "$RELEASE_TEMP_DIR/fjs.xcframework.zip.checksum" || {
  echo "error: copied release checksum differs from the validated package checksum" >&2
  exit 1
}
mv -f "$RELEASE_TEMP_DIR/fjs.xcframework.zip" "$ARTIFACT_DIR/fjs.xcframework.zip"
mv -f "$RELEASE_TEMP_DIR/fjs.xcframework.zip.checksum" "$ARTIFACT_DIR/fjs.xcframework.zip.checksum"
cleanup_release_temp
RELEASE_TEMP_DIR=""

pod ipc spec "$ROOT_DIR/darwin/fjs.podspec" >/dev/null
(cd "$ROOT_DIR" && flutter pub publish --dry-run)

echo "Darwin release artifact: $ARTIFACT_DIR/fjs.xcframework.zip"
echo "SwiftPM checksum: $(cat "$ARTIFACT_DIR/fjs.xcframework.zip.checksum")"
