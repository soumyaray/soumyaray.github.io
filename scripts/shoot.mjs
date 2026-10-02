// Usage (from scripts/): node shoot.mjs <outdir> [baseURL]
// Full-page screenshots of every page at desktop and phone widths, plus modal/collapse/menu states.
// Writes <outdir>/console.log with console errors, failed requests and 4xx responses.
import { chromium } from 'playwright';
import fs from 'node:fs';

const out = process.argv[2];
const base = process.argv[3] || 'http://localhost:8765';
fs.mkdirSync(out, { recursive: true });
const pages = ['', 'research', 'service', 'software', 'courses', 'achievements', 'social'];
const widths = { desktop: [1280, 900], phone: [390, 844] };
const log = [];

const browser = await chromium.launch();
async function open(w, path) {
  const ctx = await browser.newContext({ viewport: { width: w[0], height: w[1] }, deviceScaleFactor: 1 });
  await ctx.route(/cookiebot\.com/, r => r.abort());
  const page = await ctx.newPage();
  page.on('console', m => { if ((m.type() === 'error' || m.type() === 'warning') && !/cookiebot|chrome-extension/.test(m.location().url + m.text())) log.push(`${path} [${m.type()}] ${m.text()} @ ${m.location().url}`); });
  page.on('pageerror', e => log.push(`${path} [pageerror] ${e.message}`));
  page.on('requestfailed', r => { if (!/cookiebot|chrome-extension/.test(r.url())) log.push(`${path} [failed] ${r.url()}`); });
  page.on('response', r => { if (r.status() >= 400) log.push(`${path} [${r.status()}] ${r.url()}`); });
  await page.goto(`${base}/${path ? path + '.html' : ''}`, { waitUntil: 'networkidle' });
  await page.evaluate(() => document.fonts.ready);
  return { ctx, page };
}

for (const [wname, w] of Object.entries(widths)) {
  for (const p of pages) {
    const { ctx, page } = await open(w, p);
    await page.screenshot({ path: `${out}/${p || 'index'}-${wname}.png`, fullPage: true });
    await ctx.close();
  }
}

// interactive states
async function state(name, w, path, action) {
  const { ctx, page } = await open(w, path);
  try {
    await action(page);
    await page.waitForTimeout(800);
    await page.screenshot({ path: `${out}/${name}.png`, fullPage: false });
  } catch (e) { log.push(`${name} [state-failed] ${e.message.split('\n')[0]}`); }
  await ctx.close();
}
const D = widths.desktop, P = widths.phone;
await state('state-index-paper-modal', D, '', p => p.locator('[data-target^="#showFull"] img, [data-bs-target^="#showFull"] img').first().click());
await state('state-courses-overview-modal', D, 'courses', p => p.locator('[data-target^="#showFull"] img, [data-bs-target^="#showFull"] img').first().click());
await state('state-research-expanded', D, 'research', async p => { await p.locator('a[href="#collapseExample"]').click(); await p.waitForTimeout(600); await p.locator('#collapseExample').scrollIntoViewIfNeeded(); });
await state('state-social-pgp-modal', D, 'social', p => p.locator('[data-target="#showPgpKey"], [data-bs-target="#showPgpKey"]').click());
await state('state-privacy-modal', D, '', p => p.locator('[data-target="#showPrivacyPolicy"], [data-bs-target="#showPrivacyPolicy"]').click());
await state('state-phone-menu-open', P, '', p => p.locator('.navbar-toggle, .navbar-toggler').click());
await state('state-phone-menu-closed', P, '', async () => {});
await state('state-tablet-index', [800, 1000], '', async () => {});

// modal close check
{
  const { ctx, page } = await open(D, 'social');
  try {
    await page.locator('[data-target="#showPgpKey"], [data-bs-target="#showPgpKey"]').click();
    await page.waitForTimeout(600);
    const shown = await page.locator('#showPgpKey').isVisible();
    await page.locator('#showPgpKey .modal-footer button').click();
    await page.waitForTimeout(600);
    const after = await page.locator('#showPgpKey').isVisible();
    log.push(`check pgp modal: opened=${shown} closedAfterButton=${!after}`);
  } catch (e) { log.push(`check pgp modal failed: ${e.message.split('\n')[0]}`); }
  await ctx.close();
}

await browser.close();
fs.writeFileSync(`${out}/console.log`, log.join('\n') + '\n');
console.log(log.join('\n') || 'no console errors');
