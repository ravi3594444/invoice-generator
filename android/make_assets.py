#!/usr/bin/env python3
"""Turns the web page into the app's offline page.

Swaps the three.js CDN script and the Google Fonts stylesheets (Manrope, and Noto Sans
Devanagari for the ₹2 coin) for copies bundled in the APK, and adjusts two lines of copy
that only make sense in a browser.

Usage: make_assets.py <coin-toss/index.html> <out/index.html>
"""
import sys

src_path, out_path = sys.argv[1], sys.argv[2]
with open(src_path, encoding="utf-8") as f:
    html = f.read()


def swap(old, new):
    global html
    if old not in html:
        sys.exit(f"make_assets.py: could not find {old!r} in {src_path}; update this script to match the page.")
    html = html.replace(old, new)


FONT_FACE = """<style>
  @font-face {
    font-family: 'Manrope';
    font-style: normal;
    font-weight: 200 800;
    font-display: swap;
    src: url(fonts/manrope-latin-wght-normal.woff2) format('woff2');
    unicode-range: U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+0304, U+0308, U+0329, U+2000-206F, U+20AC, U+2122, U+2191, U+2193, U+2212, U+2215, U+FEFF, U+FFFD;
  }
  @font-face {
    font-family: 'Manrope';
    font-style: normal;
    font-weight: 200 800;
    font-display: swap;
    src: url(fonts/manrope-latin-ext-wght-normal.woff2) format('woff2');
    unicode-range: U+0100-02BA, U+02BD-02C5, U+02C7-02CC, U+02CE-02D7, U+02DD-02FF, U+0304, U+0308, U+0329, U+1D00-1DBF, U+1E00-1E9F, U+1EF2-1EFF, U+2020, U+20A0-20AB, U+20AD-20C0, U+2113, U+2C60-2C7F, U+A720-A7FF;
  }
  @font-face {
    font-family: 'Noto Sans Devanagari';
    font-style: normal;
    font-weight: 700;
    font-display: swap;
    src: url(fonts/noto-sans-devanagari-devanagari-700-normal.woff2) format('woff2');
    unicode-range: U+0900-097F, U+1CD0-1CF9, U+200C-200D, U+20A8, U+20B9, U+20F0, U+25CC, U+A830-A839, U+A8E0-A8FF, U+11B00-11B09;
  }
</style>"""

swap('<link rel="preconnect" href="https://fonts.googleapis.com">\n', "")
swap('<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>\n', "")
swap('<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Manrope:wght@400;500;600;700;800&display=swap">', FONT_FACE)
swap('<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Noto+Sans+Devanagari:wght@700&text='
     '%E0%A4%AD%E0%A4%BE%E0%A4%B0%E0%A4%A4%20%E0%A4%B8%E0%A4%A4%E0%A5%8D%E0%A4%AF%E0%A4%AE%E0%A5%87%E0%A4%B5%20'
     '%E0%A4%9C%E0%A4%AF%E0%A4%A4%E0%A5%87&display=swap">\n', "")
swap("https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js", "three.min.js")
swap(" or press Space to toss", " to toss")
swap("Fair 50/50 from your browser's secure random generator", "Fair 50/50 from your phone's secure random generator")

with open(out_path, "w", encoding="utf-8") as f:
    f.write(html)
