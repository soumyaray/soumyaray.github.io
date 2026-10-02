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

## `check_data.rb`: structural checks on `data/*.yml`

Plain Ruby, no gems. It fails on duplicate `id`s, `highlights` that point at no entry, papers without `authors`/`year`/`title`/venue, and page ranges that are not ascending. Run it after every data edit.

```bash
ruby scripts/check_data.rb
```

## `crossref_check.rb`: paper metadata against Crossref

Looks up each paper in `journal_papers.yml` and `conference_papers.yml` (by `doi:` when present, else by title) and prints differences in author order, year, volume, issue, and pages, plus DOIs the YAML lacks. Read-only; needs network. Papers not in Crossref (forthcoming papers, ICIS proceedings) show as "no Crossref match". Pass ids to check only some papers.

```bash
ruby scripts/crossref_check.rb             # all papers
ruby scripts/crossref_check.rb JBA2026     # one paper
```

## `cv_check.rb`: CV coverage report

Extracts the CV with `pdftotext -layout` (Homebrew `poppler`), splits it into sections at its upper-case headings, and reports, per section, the entries whose words mostly do not appear in the mapped `data/*.yml` files. Sections the script does not map are listed as "not on site", so a new CV section shows up. The section → data-file map (`SECTIONS`) is at the top of the script. The CV is read-only; the default path is the one in `.claude/CLAUDE.md`.

```bash
ruby scripts/cv_check.rb                  # flagged entries only
ruby scripts/cv_check.rb --all            # every entry with its score
ruby scripts/cv_check.rb path/to/CV.pdf   # another CV file
```

The score is word overlap, so a low score can be a CV typo or a deliberate rewording on the site. Read the flagged lines; do not chase 100%.
