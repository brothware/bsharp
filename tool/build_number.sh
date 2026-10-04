#!/usr/bin/env bash
set -euo pipefail

readonly MAJOR_MULTIPLIER=10000
readonly MINOR_MULTIPLIER=100
readonly MAX_MINOR=99
readonly MAX_PATCH=99
readonly MAX_MAJOR_DIGITS=5
readonly MAX_MINOR_PATCH_DIGITS=2
readonly TAG_PATTERN='^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'

tag="${1-}"

if [[ ! "$tag" =~ $TAG_PATTERN ]]; then
  echo "error: tag '$tag' must match vMAJOR.MINOR.PATCH" >&2
  exit 1
fi

major="${BASH_REMATCH[1]}"
minor="${BASH_REMATCH[2]}"
patch="${BASH_REMATCH[3]}"

if (( ${#minor} > MAX_MINOR_PATCH_DIGITS || minor > MAX_MINOR )); then
  echo "error: minor $minor in tag '$tag' must be 0..$MAX_MINOR" >&2
  exit 1
fi

if (( ${#patch} > MAX_MINOR_PATCH_DIGITS || patch > MAX_PATCH )); then
  echo "error: patch $patch in tag '$tag' must be 0..$MAX_PATCH" >&2
  exit 1
fi

if (( ${#major} > MAX_MAJOR_DIGITS )); then
  echo "error: major $major in tag '$tag' is too large" >&2
  exit 1
fi

echo $(( major * MAJOR_MULTIPLIER + minor * MINOR_MULTIPLIER + patch ))
