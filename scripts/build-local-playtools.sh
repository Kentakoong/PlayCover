#!/bin/bash
# Build the configured local working copy, including uncommitted fixes.
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
playtools_root="${1:?Usage: build-local-playtools.sh /path/to/PlayTools}"
derived_data="$repo_root/Carthage/DerivedData/LocalPlayTools"
output="$repo_root/Carthage/Build/LocalPlayTools/PlayTools.framework"
developer_dir="${DEVELOPER_DIR:-$(xcode-select -p)}"
env -i \
  PATH="/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin" \
  HOME="$HOME" \
  DEVELOPER_DIR="$developer_dir" \
  FASTLANE=1 \
  xcodebuild -project "$playtools_root/PlayTools.xcodeproj" \
  -scheme PlayTools -configuration Release -destination 'generic/platform=macOS,variant=Mac Catalyst' \
  -derivedDataPath "$derived_data" CODE_SIGNING_ALLOWED=NO ARCHS=arm64 build
framework="$derived_data/Build/Products/Release-maccatalyst/PlayTools.framework"
plugin="$derived_data/Build/Products/Release/AKInterface.bundle"
mkdir -p "$framework/Versions/A/PlugIns"
ditto "$plugin" "$framework/Versions/A/PlugIns/AKInterface.bundle"
mkdir -p "$(dirname "$output")"
rm -rf "$output"
ditto "$framework" "$output"
