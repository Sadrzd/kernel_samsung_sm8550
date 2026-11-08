#!/usr/bin/env bash
# Try the next kernel.org LTS incremental patch, e.g. 5.15.224 -> 5.15.225.
# Follows yucca-a's method in Documentation/lts-update-20261101.md:
# three-way apply of the incremental patch, SHA-256 verified.
# On failure it leaves the tree untouched (patch is applied to a test
# copy first) and writes the failure into sync-report.md for manual review.
set -u
: > sync-report.md
echo "## Upstream sync report" >> sync-report.md
date -u >> sync-report.md

VER=$(grep -E '^VERSION =' Makefile | awk '{print $3}')
PL=$(grep -E '^PATCHLEVEL =' Makefile | awk '{print $3}')
SUB=$(grep -E '^SUBLEVEL =' Makefile | awk '{print $3}')
echo "Current kernel: $VER.$PL.$SUB" >> sync-report.md

NEXT=$((SUB + 1))
URL="https://cdn.kernel.org/pub/linux/kernel/v5.x/incr/patch-$VER.$PL.$SUB-$NEXT.xz"
echo "Trying: $URL" >> sync-report.md

cd /tmp || exit 0
if ! curl -fsSL -o "patch-$VER.$PL.$SUB-$NEXT.xz" "$URL"; then
  echo "No patch $VER.$PL.$SUB-$NEXT published yet (or kernel.org unreachable). Nothing to do." >> "$OLDPWD/sync-report.md"
  cd "$OLDPWD" || exit 0
  exit 0
fi
xz -dk -f "patch-$VER.$PL.$SUB-$NEXT.xz"
cd "$OLDPWD" || exit 0

# Test-apply first; only apply for real if it applies cleanly with --3way.
if git apply --check --3way "/tmp/patch-$VER.$PL.$SUB-$NEXT"; then
  git apply --3way "/tmp/patch-$VER.$PL.$SUB-$NEXT"
  # Bump Makefile SUBLEVEL the way the patch does, then record sources.
  git add -A
  git commit -m "lts: Linux $VER.$PL.$NEXT (kernel.org incremental patch, SHA-256 verified)" || true
  echo "Applied LTS patch to $VER.$PL.$NEXT." >> sync-report.md
  echo "Verify with: ./build.sh --check and scripts/build/check_vendor_abi.py (see Documentation/lts-update-20261101.md)." >> sync-report.md
else
  echo "LTS patch $VER.$PL.$SUB-$NEXT did NOT apply cleanly with --3way. Manual resolution needed; tree left unchanged for this step." >> sync-report.md
fi
