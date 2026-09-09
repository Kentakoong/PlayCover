#!/bin/bash
# Fetch and build the exact GitHub commit recorded in Cartfile.resolved.
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
dependency_repo="$(awk -F '"' '/^github / {print $2}' "$repo_root/Cartfile.resolved")"
revision="$(awk -F '"' '/^github / {print $4}' "$repo_root/Cartfile.resolved")"
if [[ "$dependency_repo" != "Kentakoong/PlayTools" || ! "$revision" =~ ^[0-9a-f]{40}$ ]]; then
    echo "error: expected a pinned GitHub PlayTools dependency in Cartfile.resolved" >&2
    exit 1
fi
source_cache="$repo_root/Carthage/RepositoryPlayTools.git"
playtools_root="$repo_root/Carthage/Build/PlayToolsSource-$revision"
if [[ ! -d "$source_cache" ]]; then
    git init --bare "$source_cache"
fi
git --git-dir="$source_cache" fetch --depth=1 "https://github.com/$dependency_repo.git" "$revision"
[[ "$(git --git-dir="$source_cache" rev-parse FETCH_HEAD)" == "$revision" ]]
# Always export the pinned tree so uncommitted edits cannot enter the build.
rm -rf "$playtools_root"
mkdir -p "$playtools_root"
git --git-dir="$source_cache" archive "$revision" | tar -x -C "$playtools_root"
derived_data="$repo_root/Carthage/DerivedData/RepositoryPlayTools"
output="$repo_root/Carthage/Build/RepositoryPlayTools/PlayTools.framework"
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
