# Dev scripts

Checks for the site. They are not part of the Middleman build: Middleman only builds `source/`.

## `smoke.sh`: every page returns 200

Starts `middleman serve`, requests `/` and each `source/*.html.slim` page, and fails on a non-200 status or on a warning or error in the server log. It needs no extra setup.

```bash
bash scripts/smoke.sh            # PORT=4567 by default
```

## `shoot.mjs`: screenshots before and after a change

Uses Playwright. It blocks Cookiebot so that the banner does not cover the pages. It takes full-page screenshots of the 7 pages at 1280px and 390px wide. It also takes shots of these states: a paper modal, a course modal, the expanded journal list, the PGP and privacy modals, and the phone menu. It writes `console.log` with console errors, failed requests, and 4xx responses.

One-time setup:

```bash
cd scripts && npm install && npx playwright install chromium
```

Compare a change with the current build:

```bash
bundle exec rake build
python3 -m http.server 8765 -d build &        # serve the build
(cd scripts && node shoot.mjs shots/before)   # base URL defaults to http://localhost:8765
# … make the change, rebuild …
(cd scripts && node shoot.mjs shots/after)
kill %1
```

To shoot the live site, add the URL: `node shoot.mjs shots/live https://soumyaray.com`. The `shots/` and `node_modules/` folders are gitignored.
