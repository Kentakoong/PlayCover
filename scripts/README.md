# Building this fork

PlayCover on `Kentakoong/PlayCover:main` uses `Kentakoong/PlayTools:main` through `Cartfile`. `Cartfile.resolved` pins the exact PlayTools commit to build.

Run `bash scripts/build-playtools.sh` to fetch that commit directly from GitHub and build the native Mac Catalyst framework and AppKit plugin. Sources and products are cached under the ignored `Carthage` directory. The script exports a fresh copy of the pinned tree for each build; it does not use a sibling repository or its uncommitted changes.

Normal Xcode builds and the Fastlane release/nightly lanes use this same script. To create an archive and verify its embedded framework and plugin against the build:

```sh
bash scripts/archive-playtools.sh /tmp/PlayCover.xcarchive [xcodebuild signing settings...]
```

To update PlayTools, first push its changes to the PlayTools repository, then update the full commit ID in `Cartfile.resolved` and rebuild. Do not change the dependency to a local file URL.
