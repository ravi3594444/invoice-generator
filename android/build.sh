#!/usr/bin/env bash
# Builds build/HeadsOrTails.apk: the coin toss page in a full-screen WebView, fully offline.
#
# No Gradle or Android Studio needed. On Ubuntu 24.04 the tools come from apt:
#   sudo apt-get install android-sdk-platform-23 aapt dalvik-exchange zipalign apksigner \
#     openjdk-21-jdk-headless python3 npm zip
set -euo pipefail
cd "$(dirname "$0")"

ANDROID_JAR=${ANDROID_JAR:-/usr/lib/android-sdk/platforms/android-23/android.jar}
THREE_VERSION=0.128.0
MANROPE_VERSION=5.3.0
DEVANAGARI_VERSION=5.3.0
OUT=build

rm -rf "$OUT"
mkdir -p "$OUT/assets/fonts" "$OUT/assets/licenses" "$OUT/npm/three" "$OUT/npm/manrope" "$OUT/npm/devanagari" "$OUT/classes" "$OUT/dex"

echo "==> Page and offline copies of three.js, Manrope and Noto Sans Devanagari"
(cd "$OUT/npm" && npm pack --silent "three@$THREE_VERSION" "@fontsource-variable/manrope@$MANROPE_VERSION" \
  "@fontsource/noto-sans-devanagari@$DEVANAGARI_VERSION" > /dev/null)
tar -xzf "$OUT/npm/three-$THREE_VERSION.tgz" -C "$OUT/npm/three"
tar -xzf "$OUT/npm/fontsource-variable-manrope-$MANROPE_VERSION.tgz" -C "$OUT/npm/manrope"
tar -xzf "$OUT/npm/fontsource-noto-sans-devanagari-$DEVANAGARI_VERSION.tgz" -C "$OUT/npm/devanagari"
cp "$OUT/npm/three/package/build/three.min.js" "$OUT/assets/"
cp "$OUT/npm/manrope/package/files/manrope-latin-wght-normal.woff2" "$OUT/assets/fonts/"
cp "$OUT/npm/manrope/package/files/manrope-latin-ext-wght-normal.woff2" "$OUT/assets/fonts/"
cp "$OUT/npm/devanagari/package/files/noto-sans-devanagari-devanagari-700-normal.woff2" "$OUT/assets/fonts/"
cp "$OUT/npm/three/package/LICENSE" "$OUT/assets/licenses/three.js-LICENSE.txt"
cp "$OUT/npm/manrope/package/LICENSE" "$OUT/assets/licenses/Manrope-OFL.txt"
cp "$OUT/npm/devanagari/package/LICENSE" "$OUT/assets/licenses/NotoSansDevanagari-OFL.txt"
python3 make_assets.py ../coin-toss/index.html "$OUT/assets/index.html"

echo "==> Resources"
aapt2 compile --dir res -o "$OUT/res.zip"
aapt2 link -I "$ANDROID_JAR" --manifest AndroidManifest.xml -A "$OUT/assets" -o "$OUT/unsigned.apk" "$OUT/res.zip"

echo "==> Code"
javac -source 8 -target 8 -Xlint:-options -bootclasspath "$ANDROID_JAR" -d "$OUT/classes" $(find src -name '*.java')
dalvik-exchange --dex --min-sdk-version=21 --output="$OUT/dex/classes.dex" "$OUT/classes"
(cd "$OUT/dex" && zip -q ../unsigned.apk classes.dex)

echo "==> Align and sign"
zipalign -p -f 4 "$OUT/unsigned.apk" "$OUT/aligned.apk"
apksigner sign --ks debug.keystore --ks-pass pass:android --key-pass pass:android \
  --ks-key-alias androiddebugkey --out "$OUT/HeadsOrTails.apk" "$OUT/aligned.apk"
apksigner verify "$OUT/HeadsOrTails.apk"
echo "Built $OUT/HeadsOrTails.apk ($(du -k "$OUT/HeadsOrTails.apk" | cut -f1) KB)"
