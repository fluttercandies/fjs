#!/bin/sh
set -eu

FLUTTER_EXECUTABLE="flutter"
EXPECTED_VERSION=""

usage() {
  cat <<'USAGE'
Usage: tool/check_minimum_flutter_compatibility.sh --expected-version VERSION [--flutter PATH]

Compiles the public FJS Dart API from a temporary consumer using the selected
minimum supported Flutter SDK.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --expected-version)
      [ "$#" -ge 2 ] || {
        usage >&2
        exit 2
      }
      EXPECTED_VERSION="$2"
      shift 2
      ;;
    --flutter)
      [ "$#" -ge 2 ] || {
        usage >&2
        exit 2
      }
      FLUTTER_EXECUTABLE="$2"
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

[ -n "$EXPECTED_VERSION" ] || {
  usage >&2
  exit 2
}

fail() {
  echo "error: $*" >&2
  exit 1
}

flutter_version="$("$FLUTTER_EXECUTABLE" --version)" ||
  fail "unable to run Flutter: $FLUTTER_EXECUTABLE"
printf '%s\n' "$flutter_version" | grep -F "Flutter $EXPECTED_VERSION " >/dev/null ||
  fail "expected Flutter $EXPECTED_VERSION"

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/fjs-minimum-flutter.XXXXXX")"
cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT
trap 'exit 130' HUP INT TERM

mkdir -p "$TEMP_DIR/test"
ln -s "$ROOT_DIR" "$TEMP_DIR/fjs"

cat > "$TEMP_DIR/pubspec.yaml" <<'PUBSPEC'
name: fjs_minimum_compatibility
publish_to: none
environment:
  sdk: '>=3.5.0 <4.0.0'
dependencies:
  fjs:
    path: fjs
dev_dependencies:
  flutter_test:
    sdk: flutter
PUBSPEC

cat > "$TEMP_DIR/test/public_api_test.dart" <<'DART'
import 'package:fjs/fjs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public API compiles on the minimum supported Flutter', () {
    const source = JsCode.code('1 + 1');
    final createEngine = JsEngine.create;
    final compileBytecode = JsBytecode.compile;

    expect(source, isA<JsCode>());
    expect(createEngine, isA<Function>());
    expect(compileBytecode, isA<Function>());
  });
}
DART

(
  cd "$TEMP_DIR"
  "$FLUTTER_EXECUTABLE" pub get
  "$FLUTTER_EXECUTABLE" test --no-pub
)
