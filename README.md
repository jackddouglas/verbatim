# Verbatim

A small native SwiftUI app for macOS 27 or later that extracts full text from Apple Podcasts' locally cached episode transcripts. No accounts, API keys, network requests, or dependencies.

## Build and run

Requires Xcode 27 or later with its Swift command-line tools selected.

```sh
./scripts/build-app.sh
open build/Verbatim.app
```

You can also open `Package.swift` in Xcode and run the Verbatim executable target. The build script creates an ad-hoc signed local app; it is not notarized for distribution.

## Use

1. Open an episode in Apple Podcasts and choose **View Transcript**. Give Podcasts time to load it.
2. Open Verbatim and click **Refresh**.
3. Select the episode, then **Copy All** or **Export…** to save a UTF-8 text file. Enable **Show Timestamps** in the toolbar options menu to include the original paragraph start times.

Search filters episode titles and show names. **Choose Folder** also supports a folder of `.ttml` files. If initial access is denied, click **Choose Folder** and confirm the preselected Apple Podcasts container. This was verified to resolve access on this Mac. Custom folder selections last for the current session.

Verbatim reads the Apple Podcasts group container at `~/Library/Group Containers/243LU875E5.groups.com.apple.podcasts`, finds TTML files, and opens `Documents/MTLibrary.sqlite` read-only to match episode titles using store IDs. If metadata is unavailable, files remain accessible under their IDs or filenames. It never changes the Podcasts database or cache. All transcript paragraphs are retained, with nested word spans converted to readable text.

## Limits

This app extracts existing cached transcripts; it does not download a transcript from an arbitrary episode URL or transcribe audio. An episode must have a transcript available in Podcasts and cached on this Mac. It exports all text in the file, but cannot verify that Apple's cached transcript covers the entire recording. Apple's private storage layout and database schema may change. Speaker IDs are parsed but are not included in the plain-text output.

## Verify

```sh
CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache" \
SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/module-cache" \
swift test --cache-path .build/cache --disable-sandbox
build/Verbatim.app/Contents/MacOS/Verbatim --check-cache
```

Tests use synthetic temporary files and do not modify the Podcasts library. The diagnostic command parses real cached files and prints counts without printing transcript contents.

## Native macOS 27 interface

Built with the macOS 27 SDK using SwiftUI's system sidebar, trailing-toolbar search, toolbar groups and spacing, menus, semantic typography, and native open/save panels. The empty-state primary action uses `glassProminent`; standard navigation and toolbar controls receive the current Liquid Glass appearance automatically. Transcript text stays on the content surface. Copy and export have high toolbar visibility priority.

Every toolbar action is also available from the menu bar. Shortcuts: Command-O to choose a folder, Command-R to refresh, Shift-Command-C to copy the transcript, and Shift-Command-E to export. View includes the standard sidebar command and Show Timestamps.

Design references: [Apple toolbar HIG](https://developer.apple.com/design/human-interface-guidelines/toolbars), [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass), and [What's new in SwiftUI, WWDC26](https://developer.apple.com/videos/play/wwdc2026/269/).

## App icon

`Resources/Verbatim.icon` is the editable Icon Composer document. The current direction replaces the central figure with a fountain-pen nib over the original two purple discs, using four native Liquid Glass material groups. Previous transcript-page versions are preserved in `Resources/Archive`. Original vectors are in `Resources/IconLayers`; Icon Composer keeps its imported copies in the document's `Assets` directory. Reimport a vector when changing its source.

The app build script compiles the document with Xcode's `actool`, installs `Assets.car` and the fallback `.icns`, merges the generated icon metadata, and then signs the bundle.

`Resources/Podcasts-Original.icon` is an editable reference baseline recovered from the installed Apple Podcasts icon, for the requested design study. It preserves the original vectors and material settings. `Podcasts-Study.icon` is the earlier hand-reconstructed study. Neither changes the current Verbatim bundle icon. The original artwork is Apple's; it is retained here as the reference for the next iteration.
