#!/bin/sh
set -eu

WRITE=0
if [ "${1:-}" = --write ]; then
  WRITE=1
  shift
fi
[ "$#" -eq 1 ] || {
  echo "usage: $0 [--write] STAGE_DIR" >&2
  exit 2
}

STAGE_DIR="$(CDPATH= cd -- "$1" && pwd)"
PACKAGE_DIR="$STAGE_DIR/package"
INVENTORY="$STAGE_DIR/inventory.sha256"
INVENTORY_DIGEST="$STAGE_DIR/inventory.sha256.sha256"
[ -d "$PACKAGE_DIR" ] || {
  echo "error: missing staged package: $PACKAGE_DIR" >&2
  exit 1
}

sha_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

make_inventory() {
  destination="$1"
  (
    cd "$PACKAGE_DIR"
    find . \( -type f -o -type l \) -print | LC_ALL=C sort | while IFS= read -r item; do
      if [ -L "$item" ]; then
        target="$(readlink "$item")"
        printf 'link:%s  %s\n' "$target" "$item"
      else
        printf '%s  %s\n' "$(sha_file "$item")" "$item"
      fi
    done
  ) > "$destination"
}

TEMP_INVENTORY="$(mktemp "$STAGE_DIR/.inventory.XXXXXX")"
trap 'rm -f "$TEMP_INVENTORY"' EXIT HUP INT TERM
make_inventory "$TEMP_INVENTORY"

if [ "$WRITE" -eq 1 ]; then
  mv -f "$TEMP_INVENTORY" "$INVENTORY"
  printf '%s\n' "$(sha_file "$INVENTORY")" > "$INVENTORY_DIGEST"
else
  [ -f "$INVENTORY" ] && [ -f "$INVENTORY_DIGEST" ] || {
    echo "error: missing staged inventory" >&2
    exit 1
  }
  cmp -s "$TEMP_INVENTORY" "$INVENTORY" || {
    echo "error: staged package inventory changed" >&2
    exit 1
  }
  expected="$(cat "$INVENTORY_DIGEST")"
  actual="$(sha_file "$INVENTORY")"
  [ "$expected" = "$actual" ] || {
    echo "error: staged inventory digest changed" >&2
    exit 1
  }
fi

[ ! -e "$PACKAGE_DIR/docs" ] || {
  echo "error: docs must not be present in the pub stage" >&2
  exit 1
}
[ -f "$PACKAGE_DIR/darwin/fjs/Binaries/fjs.xcframework.zip" ] || {
  echo "error: staged SwiftPM archive is missing" >&2
  exit 1
}

echo "Pub stage inventory is valid."
