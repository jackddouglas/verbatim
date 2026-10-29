<p align="center">
  <img src="verification/icon/Default.png" width="180" alt="Verbatim app icon">
</p>

<h1 align="center">Verbatim</h1>

<p align="center">
  A native macOS app for reading and exporting Apple Podcasts transcripts.
</p>

## Build

Requires macOS 27 or later and full Xcode 27 or later with its command-line tools selected.

```sh
swift test
bash scripts/build-app.sh
open build/Verbatim.app
```

## Use

1. Open an episode in Apple Podcasts and choose **View Transcript**.
2. Open Verbatim and click **Refresh**. If access is denied, use **Choose Transcript Folder…** to select the Podcasts container.
3. Select an episode, then copy or export its transcript. Enable **Show Timestamps** to include timestamps.

Verbatim reads transcripts already cached by Apple Podcasts. Everything stays on your Mac.
