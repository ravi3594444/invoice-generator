#!/usr/bin/env node
// Open a page in headless Chromium and report what a user would see: HTTP
// status, title, console errors, uncaught page errors, failed requests, and a
// screenshot. Exits 1 when the page failed to load, an action failed, or the
// page logged errors, so it works as a feedback loop for UI changes.
import { createRequire } from 'node:module';
import { execSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { homedir } from 'node:os';
import path from 'node:path';

const USAGE = `Usage: browser-check.mjs <url> [options]

  --screenshot <file>          Where to save a full-page screenshot (default: browser-check.png)
  --no-screenshot              Skip the screenshot
  --mobile                     Use a 390x844 phone viewport instead of 1280x800
  --wait-for <selector>        Wait for a selector before running actions
  --fill <selector>=<value>    Fill an input (repeatable; runs in order with --click)
  --click <selector>           Click an element (repeatable; runs in order with --fill)
  --text                       Print the page's visible text (first 3000 characters)
  --timeout <ms>               Navigation and wait timeout (default: 30000)
  --allow-console-errors       Report console errors without failing
`;

function parseArgs(argv) {
  const opts = { url: null, screenshot: 'browser-check.png', mobile: false, waitFor: null, steps: [], text: false, timeout: 30000, allowConsoleErrors: false };
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    const next = () => {
      if (i + 1 >= argv.length) throw new Error(`${arg} needs a value`);
      return argv[++i];
    };
    switch (arg) {
      case '-h': case '--help': console.log(USAGE); process.exit(0);
      case '--screenshot': opts.screenshot = next(); break;
      case '--no-screenshot': opts.screenshot = null; break;
      case '--mobile': opts.mobile = true; break;
      case '--wait-for': opts.waitFor = next(); break;
      case '--text': opts.text = true; break;
      case '--timeout': opts.timeout = Number(next()); break;
      case '--allow-console-errors': opts.allowConsoleErrors = true; break;
      case '--click': opts.steps.push({ kind: 'click', selector: next() }); break;
      case '--fill': {
        const raw = next();
        const eq = raw.indexOf('=');
        if (eq < 1) throw new Error(`--fill expects <selector>=<value>, got "${raw}"`);
        opts.steps.push({ kind: 'fill', selector: raw.slice(0, eq), value: raw.slice(eq + 1) });
        break;
      }
      default:
        if (arg.startsWith('--')) throw new Error(`Unknown option ${arg}`);
        opts.url = arg;
    }
  }
  if (!opts.url) throw new Error('Missing <url>');
  if (!/^[a-z]+:\/\//i.test(opts.url)) opts.url = `http://${opts.url}`;
  return opts;
}

// Look for Playwright in the current project, then the global npm root, then
// gstack's install, so the script works without its own node_modules.
function loadPlaywright() {
  const bases = [process.cwd()];
  try {
    bases.push(execSync('npm root -g', { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim());
  } catch {}
  bases.push(path.join(homedir(), '.claude', 'skills', 'gstack'));
  for (const base of bases) {
    const req = createRequire(path.join(base, 'noop.js'));
    for (const name of ['playwright', '@playwright/test', 'playwright-core']) {
      try { return req(name); } catch {}
    }
  }
  return null;
}

// A Playwright release expects one exact Chromium build. If that build is not
// downloaded, fall back to a Chromium that is already on the machine.
async function launchChromium(pw) {
  try {
    return await pw.chromium.launch({ headless: true });
  } catch (err) {
    const fallbacks = [process.env.BROWSER_CHECK_CHROMIUM, '/opt/pw-browsers/chromium'].filter((p) => p && existsSync(p));
    for (const executablePath of fallbacks) {
      try { return await pw.chromium.launch({ headless: true, executablePath }); } catch {}
    }
    throw err;
  }
}

async function main() {
  let opts;
  try {
    opts = parseArgs(process.argv.slice(2));
  } catch (err) {
    console.error(`${err.message}\n\n${USAGE}`);
    process.exit(2);
  }

  const pw = loadPlaywright();
  if (!pw) {
    console.error('Playwright not found. Install it with: npm install -g playwright && npx playwright install chromium');
    process.exit(2);
  }

  const browser = await launchChromium(pw);
  const context = await browser.newContext(
    opts.mobile ? { viewport: { width: 390, height: 844 }, isMobile: true, hasTouch: true } : { viewport: { width: 1280, height: 800 } },
  );
  const page = await context.newPage();

  const consoleErrors = [];
  const pageErrors = [];
  const network = [];
  const problems = [];
  page.on('console', (msg) => {
    if (msg.type() !== 'error') return;
    const text = msg.text();
    // Chromium also logs every 4xx/5xx subresource as a console error; those are reported under Network.
    if (!text.startsWith('Failed to load resource')) consoleErrors.push(text);
  });
  page.on('pageerror', (err) => pageErrors.push(err.message));
  page.on('requestfailed', (req) => network.push(`FAILED ${req.method()} ${req.url()} (${req.failure()?.errorText ?? 'unknown'})`));
  page.on('response', (res) => {
    if (res.status() >= 400) network.push(`${res.status()} ${res.request().method()} ${res.url()}`);
  });

  let status = null;
  try {
    const res = await page.goto(opts.url, { waitUntil: 'load', timeout: opts.timeout });
    status = res ? res.status() : null;
    if (status !== null && status >= 400) problems.push(`Page responded with HTTP ${status}`);
    await page.waitForLoadState('networkidle', { timeout: 5000 }).catch(() => {});
    if (opts.waitFor) await page.waitForSelector(opts.waitFor, { timeout: opts.timeout });
    for (const step of opts.steps) {
      if (step.kind === 'fill') await page.fill(step.selector, step.value, { timeout: opts.timeout });
      else await page.click(step.selector, { timeout: opts.timeout });
      await page.waitForLoadState('networkidle', { timeout: 5000 }).catch(() => {});
    }
  } catch (err) {
    problems.push(err.message.split('\n')[0]);
  }

  const title = await page.title().catch(() => '');
  let screenshotPath = null;
  if (opts.screenshot) {
    screenshotPath = path.resolve(opts.screenshot);
    await page.screenshot({ path: screenshotPath, fullPage: true }).catch((err) => problems.push(`Screenshot failed: ${err.message}`));
  }
  const text = opts.text ? await page.innerText('body').catch(() => '') : null;
  const finalUrl = page.url();
  await browser.close();

  if (pageErrors.length) problems.push(`${pageErrors.length} uncaught page error(s)`);
  if (consoleErrors.length && !opts.allowConsoleErrors) problems.push(`${consoleErrors.length} console error(s)`);

  const section = (name, items) => {
    console.log(`\n${name}: ${items.length ? '' : 'none'}`);
    for (const item of items) console.log(`  - ${item}`);
  };
  console.log(`URL:    ${finalUrl}`);
  console.log(`Status: ${status ?? 'no response'}`);
  console.log(`Title:  ${title}`);
  if (screenshotPath) console.log(`Screenshot: ${screenshotPath}`);
  section('Console errors', consoleErrors);
  section('Page errors', pageErrors);
  section('Network (failed or 4xx/5xx)', network);
  if (text !== null) console.log(`\nVisible text:\n${text.slice(0, 3000)}`);
  console.log(`\nResult: ${problems.length ? `FAIL (${problems.join('; ')})` : 'PASS'}`);
  process.exit(problems.length ? 1 : 0);
}

main().catch((err) => {
  console.error(err.stack || err.message);
  process.exit(2);
});
