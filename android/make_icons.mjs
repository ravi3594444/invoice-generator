// Renders the launcher icons from the real coin artwork in ../coin-toss/index.html.
//
// Usage: node make_icons.mjs [path/to/manrope.woff2]
// Needs Playwright with Chromium. Run ./build.sh first to fetch the font it uses.
import fs from 'fs';
import path from 'path';
import { createRequire } from 'module';
import { fileURLToPath } from 'url';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const here = path.dirname(fileURLToPath(import.meta.url));
const page = fs.readFileSync(path.join(here, '../coin-toss/index.html'), 'utf8');

function grab(start, end) {
  const i = page.indexOf(start);
  const j = page.indexOf(end, i);
  if (i < 0 || j < 0) throw new Error(`make_icons: could not find "${start.trim()}" in the page`);
  return page.slice(i, j);
}
const drawing =
  grab('    function makeCanvas', '    /* ================= Reflection environment') +
  grab('    function arcText', '    function makeReeding(mode) {');

const fontPath = process.argv[2] || path.join(here, 'build/assets/fonts/manrope-latin-wght-normal.woff2');
const fontFace = fs.existsSync(fontPath)
  ? `@font-face{font-family:Manrope;font-weight:200 800;src:url(data:font/woff2;base64,${fs.readFileSync(fontPath).toString('base64')}) format('woff2')}`
  : '';

const html = `<!doctype html><meta charset="utf-8"><style>${fontFace}</style><script>
// Seeded, so the icons come out the same every time.
var rnd = (function () { var s = 7; return function () { s = (s * 16807) % 2147483647; return (s - 1) / 2147483646; }; })();
${drawing}
function coinIcon(size, coinFrac, glow) {
  var face = makeCanvas(1024, 1024);
  drawFace(face.getContext('2d'), 'H', 'color');
  var c = makeCanvas(size, size), g = c.getContext('2d');
  var d = size * coinFrac, r = d / 2, cx = size / 2, cy = size / 2 - d * 0.025;
  if (glow) {
    var gl = g.createRadialGradient(cx, cy, r * 0.7, cx, cy, r * 1.5);
    gl.addColorStop(0, 'rgba(244,184,96,0.42)');
    gl.addColorStop(1, 'rgba(244,184,96,0)');
    g.fillStyle = gl;
    g.fillRect(0, 0, size, size);
  }
  // The coin's edge, seen from slightly above.
  g.save();
  g.shadowColor = 'rgba(0,0,0,0.45)';
  g.shadowBlur = d * 0.06;
  g.shadowOffsetY = d * 0.03;
  var eg = g.createLinearGradient(cx - r, 0, cx + r, 0);
  eg.addColorStop(0, '#6f767a');
  eg.addColorStop(0.5, '#cfd4d7');
  eg.addColorStop(1, '#6f767a');
  g.fillStyle = eg;
  g.beginPath();
  g.arc(cx, cy + d * 0.05, r, 0, Math.PI * 2);
  g.fill();
  g.restore();
  g.save();
  g.beginPath();
  g.arc(cx, cy, r, 0, Math.PI * 2);
  g.clip();
  g.drawImage(face, cx - r, cy - r, d, d);
  g.restore();
  return c.toDataURL('image/png');
}
</script>`;

const densities = { mdpi: 1, hdpi: 1.5, xhdpi: 2, xxhdpi: 3, xxxhdpi: 4 };
const browser = await chromium.launch();
const tab = await browser.newPage();
await tab.setContent(html);
await tab.evaluate(() => document.fonts.load('800 64px Manrope').catch(() => {}));
for (const [name, k] of Object.entries(densities)) {
  const dir = path.join(here, 'res', `mipmap-${name}`);
  fs.mkdirSync(dir, { recursive: true });
  // Legacy icon: the coin on its own. Adaptive foreground: the coin inside the 66dp safe zone.
  const legacy = await tab.evaluate(([s]) => coinIcon(s, 0.9, false), [Math.round(48 * k)]);
  const fore = await tab.evaluate(([s]) => coinIcon(s, 0.56, true), [Math.round(108 * k)]);
  fs.writeFileSync(path.join(dir, 'ic_launcher.png'), Buffer.from(legacy.split(',')[1], 'base64'));
  fs.writeFileSync(path.join(dir, 'ic_launcher_foreground.png'), Buffer.from(fore.split(',')[1], 'base64'));
  console.log(`mipmap-${name}: ${Math.round(48 * k)}px and ${Math.round(108 * k)}px`);
}
await browser.close();
