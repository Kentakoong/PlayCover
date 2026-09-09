#!/bin/bash
# Rebuild local PlayTools and install into ~/Library/Frameworks (what games actually load).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
PLAYTOOLS="$(cd "$ROOT/../PlayTools" && pwd)"
FRAMEWORKS="$HOME/Library/Frameworks"
DEST="$FRAMEWORKS/PlayTools.framework"

echo "==> PlayTools repo: $PLAYTOOLS"
echo "==> $(cd "$PLAYTOOLS" && git log -1 --oneline)"

cd "$ROOT"
rm -rf Carthage/Checkouts/PlayTools Carthage/Build/PlayTools.xcframework Carthage/Build/.PlayTools.version

# Pin resolved to current HEAD of the local branch
HEAD="$(cd "$PLAYTOOLS" && git rev-parse HEAD)"
cat > Cartfile <<EOF
git "file://${PLAYTOOLS}" "fix/follow-in-game-orientation"
EOF
cat > Cartfile.resolved <<EOF
git "file://${PLAYTOOLS}" "${HEAD}"
EOF

echo "==> Cartfile.resolved -> ${HEAD}"
/opt/homebrew/bin/carthage update --use-xcframeworks --no-use-binaries

SRC="$ROOT/Carthage/Build/PlayTools.xcframework/ios-arm64/PlayTools.framework"
if [[ ! -d "$SRC" ]]; then
  echo "error: missing $SRC" >&2
  exit 1
fi

echo "==> Installing system PlayTools to $DEST"
mkdir -p "$FRAMEWORKS"
rm -rf "$DEST"
# Deep-copy ios-arm64 framework; PlayCover's copy script normally converts to maccatalyst.
# Prefer the already-converted framework from the latest Nightly build if present.
NIGHTLY=$(ls -d "$HOME"/Library/Developer/Xcode/DerivedData/PlayCover-*/Build/Products/Nightly/PlayCover.app/Contents/Frameworks/PlayTools.framework 2>/dev/null | head -1 || true)
if [[ -n "${NIGHTLY}" && -d "${NIGHTLY}" ]]; then
  echo "==> Using converted Nightly framework: $NIGHTLY"
  cp -R "$NIGHTLY" "$DEST"
else
  echo "==> Using Carthage ios-arm64 framework (may need PlayCover launch to convert)"
  cp -R "$SRC" "$DEST"
fi

echo "==> Verify symbols"
nm "$DEST/Versions/A/PlayTools" 2>/dev/null | grep -i OrientationSession | head -3 \
  || nm "$DEST/PlayTools" 2>/dev/null | grep -i OrientationSession | head -3 \
  || echo "warn: OrientationSession symbol not found"
echo "==> Done. Quit 学マス fully, rebuild PlayCover in Xcode (so Nightly embeds new PlayTools),"
echo "    launch PlayCover once (installOnSystem), then relaunch 学マス."
