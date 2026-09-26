# Heads or Tails for Android

The coin toss from `../coin-toss/index.html`, packaged as an Android app: a lamplit table
or a cricket ground, and a cricket toss coin or an Indian ₹2 coin. It is a full-screen
WebView that serves the page, three.js and its fonts from inside the APK, so it works offline.

- Android 5.0 or newer (minSdk 21, targetSdk 34)
- Permissions: internet (required by WebView; the app loads nothing from the web) and
  vibrate (a buzz when the coin lands)

## Install

1. Copy `dist/HeadsOrTails-1.1.apk` to the phone and open it.
2. If Android asks, allow your browser or file manager to install unknown apps.
3. Play Protect may warn about an app from an unknown developer. Tap **Install anyway**.

## Build

No Gradle or Android Studio needed. On Ubuntu 24.04:

```sh
sudo apt-get install android-sdk-platform-23 aapt dalvik-exchange zipalign apksigner \
  openjdk-21-jdk-headless python3 npm zip
./build.sh          # writes build/HeadsOrTails.apk
```

`build.sh` converts the web page with `make_assets.py`, which swaps the CDN script and web
font for bundled copies. It then compiles resources with `aapt2` and code with `javac` and
`dx`, aligns the APK and signs it.

`make_icons.mjs` redraws the launcher icons from the coin artwork (needs Playwright):
`node make_icons.mjs`.

## Signing

The APK is signed with `debug.keystore` (password `android`, alias `androiddebugkey`).
Keep using that key so a new build installs over an old one. To put the app on the
Play Store, sign it with your own private key instead, and don't commit that key.
When you ship an update, raise `android:versionCode` in `AndroidManifest.xml`.
