#!/usr/bin/env python3
"""Turns the web page into the app's offline page.

Swaps the three.js CDN script and the Google Fonts stylesheet for copies bundled in the
APK, and adjusts two lines of copy that only make sense in a browser.

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
  }
</style>"""

swap('<link rel="preconnect" href="https://fonts.googleapis.com">\n', "")
swap('<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>\n', "")
swap('<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Manrope:wght@400;500;600;700;800&display=swap">', FONT_FACE)
swap("https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js", "three.min.js")
swap("Tap the table or press Space to toss", "Tap the table to toss")
swap("Fair 50/50 from your browser's secure random generator", "Fair 50/50 from your phone's secure random generator")

with open(out_path, "w", encoding="utf-8") as f:
    f.write(html)
