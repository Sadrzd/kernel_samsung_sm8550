#!/usr/bin/env bash
# Try the next kernel.org LTS incremental patch, e.g. 5.15.224 -> 5.15.225.
# Follows yucca-a's method in Documentation/lts-update-20261101.md:
# three-way apply of the incremental patch.
# This script never commits and never changes directory state for the
# caller: it only modifies the working tree if the patch applies cleanly,
# and always writes its result into sync-report.md in the repo root.
# It always exits 0; the workflow decides what to do from the tree diff.
set -u
REPO_ROOT="$PWD"
REPORT="$REPO_ROOT/sync-report.md"
: >> "$REPORT"

VER=$(grep -E '^VERSION =' Makefile | awk '{print $3}')
PL=$(grep -E '^PATCHLEVEL =' Makefile | awk '{print $3}')
SUB=$(grep -E '^SUBLEVEL =' Makefile | awk '{print $3}')
echo "Current kernel: $VER.$PL.$SUB" >> "$REPORT"

NEXT=$((SUB + 1))
PATCH="/tmp/patch-$VER.$PL.$SUB-$NEXT"
URL="https://cdn.kernel.org/pub/linux/kernel/v5.x/incr/patch-$VER.$PL.$SUB-$NEXT.xz"
echo "Trying: $URL" >> "$REPORT"

if ! curl -fsSL -o "$PATCH.xz" "$URL"; then
  echo "No patch $VER.$PL.$SUB-$NEXT published yet (or kernel.org unreachable). Nothing to do." >> "$REPORT"
  exit 0
fi
xz -dk -f "$PATCH.xz"
echo "Downloaded patch sha256: $(sha256sum "$PATCH" | awk '{print $1}')" >> "$REPORT"

# Test-apply first; only apply for real if it applies cleanly with --3way.
if git apply --check --3way "$PATCH"; then
  git apply --3way "$PATCH"
  echo "Applied LTS patch to $VER.$PL.$NEXT." >> "$REPORT"
  echo "Verify with: ./build.sh --check and scripts/build/check_vendor_abi.py (see Documentation/lts-update-20261101.md)." >> "$REPORT"
else
  echo "LTS patch $VER.$PL.$SUB-$NEXT did NOT apply cleanly with --3way. Manual resolution needed; tree left unchanged for this step." >> "$REPORT"
fi
exit 0
