#!/bin/sh
set -eu

ARTIFACT=""
OUTPUT=""
SOURCE_REF=HEAD
while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact) ARTIFACT="$2"; shift 2 ;;
    --output) OUTPUT="$2"; shift 2 ;;
    --source-ref) SOURCE_REF="$2"; shift 2 ;;
    *) echo "usage: $0 --artifact ZIP --output DIR [--source-ref REF]" >&2; exit 2 ;;
  esac
done
[ -n "$ARTIFACT" ] && [ -n "$OUTPUT" ] || {
  echo "error: --artifact and --output are required" >&2
  exit 2
}

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
case "$ARTIFACT" in /*) ;; *) ARTIFACT="$(pwd)/$ARTIFACT" ;; esac
case "$OUTPUT" in /*) ;; *) OUTPUT="$(pwd)/$OUTPUT" ;; esac
[ -f "$ARTIFACT" ] || { echo "error: missing artifact: $ARTIFACT" >&2; exit 1; }
[ ! -e "$OUTPUT" ] || { echo "error: output already exists: $OUTPUT" >&2; exit 1; }

test -z "$(git -C "$ROOT_DIR" ls-files docs)"
test -z "$(git -C "$ROOT_DIR" log --all --oneline -- docs)"
"$ROOT_DIR/tool/check_darwin_package_support.sh" --artifact "$ARTIFACT"

PARENT="$(dirname -- "$OUTPUT")"
mkdir -p "$PARENT"
STAGING="$(mktemp -d "$PARENT/.pub-stage.XXXXXX")"
cleanup() { rm -rf "$STAGING"; }
trap cleanup EXIT HUP INT TERM
mkdir -p "$STAGING/package"
git -C "$ROOT_DIR" archive "$SOURCE_REF" | tar -x -C "$STAGING/package"
mkdir -p "$STAGING/package/darwin/fjs/Binaries"
cp "$ARTIFACT" "$STAGING/package/darwin/fjs/Binaries/fjs.xcframework.zip"
"$ROOT_DIR/tool/verify_pub_stage.sh" --write "$STAGING"
"$ROOT_DIR/tool/verify_pub_stage.sh" "$STAGING"
mv "$STAGING" "$OUTPUT"
STAGING=""
trap - EXIT HUP INT TERM

echo "Created immutable pub stage: $OUTPUT"
