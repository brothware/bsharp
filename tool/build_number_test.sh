#!/usr/bin/env bash
set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
build_number="$script_dir/build_number.sh"
failures=0

expect_number() {
  local tag="$1"
  local expected="$2"
  local actual
  actual="$("$build_number" "$tag")"
  if [[ "$actual" == "$expected" ]]; then
    echo "ok   $tag -> $actual"
  else
    echo "FAIL $tag -> $actual (expected $expected)"
    failures=$((failures + 1))
  fi
}

expect_rejected() {
  local tag="$1"
  if "$build_number" "$tag" >/dev/null 2>&1; then
    echo "FAIL '$tag' was accepted"
    failures=$((failures + 1))
  else
    echo "ok   '$tag' rejected"
  fi
}

expect_greater() {
  local higher="$1"
  local lower="$2"
  if (( $("$build_number" "$higher") > $("$build_number" "$lower") )); then
    echo "ok   $higher > $lower"
  else
    echo "FAIL $higher is not greater than $lower"
    failures=$((failures + 1))
  fi
}

expect_number v1.4.0 10400
expect_number v1.3.21 10321
expect_number v2.0.0 20000
expect_number v1.4.99 10499
expect_number v0.0.0 0
expect_greater v1.4.0 v1.3.21
expect_rejected v1.4.100
expect_rejected v1.100.0
expect_rejected v1.4
expect_rejected v1.4.0-rc1
expect_rejected 1.4.0
expect_rejected v1.4.0.1
expect_rejected ""

if (( failures > 0 )); then
  echo "$failures failure(s)"
  exit 1
fi
echo "all passed"
