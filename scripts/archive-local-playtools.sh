#!/bin/bash
# Build and archive the sibling PlayTools working copy, then verify provenance.
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
archive_path="${1:?Usage: archive-local-playtools.sh /absolute/output.xcarchive [xcodebuild settings...]}"
shift
playtools_root="${PLAYTOOLS_SOURCE_DIR:-$(cd "$repo_root/../PlayTools" && pwd)}"
/bin/bash "$repo_root/scripts/build-local-playtools.sh" "$playtools_root"
framework="$repo_root/Carthage/Build/LocalPlayTools/PlayTools.framework"
FASTLANE=1 xcodebuild -project "$repo_root/PlayCover.xcodeproj" -scheme PlayCover \
    -configuration Nightly -destination 'generic/platform=macOS' \
    -archivePath "$archive_path" "PLAYTOOLS_FRAMEWORK_PATH=$framework" "$@" archive
embedded="$archive_path/Products/Applications/PlayCover.app/Contents/Frameworks/PlayTools.framework"
for executable in PlayTools PlugIns/AKInterface.bundle/Contents/MacOS/AKInterface; do
    built_uuid="$(xcrun dwarfdump --uuid "$framework/$executable" | awk '{print $2, $3}')"
    embedded_uuid="$(xcrun dwarfdump --uuid "$embedded/$executable" | awk '{print $2, $3}')"
    if [[ "$built_uuid" != "$embedded_uuid" || -z "$built_uuid" ]]; then
        echo "ERROR: archive contains a different $executable binary" >&2
        exit 1
    fi
    echo "Verified $executable UUID: $embedded_uuid"
done
