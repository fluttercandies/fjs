#!/bin/sh
set -eu

# Runs `flutter pub publish --dry-run` and enforces its warnings.
#
# The flutter_rust_bridge dependency is pinned to the exact codegen version
# because FRB requires runtime == codegen at run time, so pub's "should
# allow more than one version" warning for it is expected; it is the only
# warning tolerated here. Any other warning or failure is fatal.

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

log="$(mktemp "${TMPDIR:-/tmp}/fjs-pub-dry-run.XXXXXX")"
cleanup() {
  rm -f "$log"
}
trap cleanup EXIT
trap 'exit 130' HUP INT TERM

status=0
(cd "$ROOT_DIR" && flutter pub publish --dry-run) >"$log" 2>&1 || status=$?

total_warnings="$(sed -nE 's/^Package has ([0-9]+) warnings?\.$/\1/p' "$log" | tail -n 1)"
[ -n "$total_warnings" ] || total_warnings=0
frb_pin_warnings="$(grep -c 'should allow more than one version' "$log" || true)"
unexpected_warnings=$((total_warnings - frb_pin_warnings))

if [ "$unexpected_warnings" -gt 0 ] ||
  { [ "$status" -ne 0 ] && [ "$frb_pin_warnings" -eq 0 ]; } ||
  grep -q '^Error' "$log"; then
  cat "$log" >&2
  echo "error: pub publish dry-run failed or reported unexpected warnings ($unexpected_warnings)" >&2
  exit 1
fi
