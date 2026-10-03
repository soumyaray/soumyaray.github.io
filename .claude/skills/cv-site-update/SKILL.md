---
name: cv-site-update
description: Refresh soumyaray.com content from the latest CV — compare the CV with data/*.yml, fix and add papers, awards, grants, service, talks, courses, software and syllabi, replace the CV download, check, build, and deploy. Use when the user says the CV was updated, asks to sync or refresh the site from the CV, or mentions "cv-site-update".
---

# Update the site from the CV

The CV is the source of truth for content. This skill brings `data/*.yml`, the syllabi, and the CV download up to date with it. It was distilled from the 2026-10 overhaul (`.claude/plans/003-PLAN-content-overhaul/`, gitignored, so it may not exist).

Work on `source`. Read `.claude/CLAUDE.md` for the build and deploy layout (`build/` is a clone on `master`).

## Inputs

- **CV (read-only)**: `/Users/soumyaray/Sync/Dropbox/Work/Curriculum Vitae/Soumya Ray - CV.pdf` (`.docx` beside it, older versions in `OLD CVs/`). Never edit, move, or copy it, except to replace the site's download copy. Extract text into the scratchpad, never into the repo: `pdftotext -layout "<CV>.pdf" <scratchpad>/cv.txt`.
- **Crossref API** (no key) for paper metadata.
- **Syllabi**: `~/Sync/Dropbox/Teaching/My Courses/` (read-only).

## Scripts (`scripts/`, documented in `scripts/README.md`)

| Script | Role | When |
| --- | --- | --- |
| `cv_check.rb` | CV sections → `data/*.yml` coverage report; lists unmapped CV sections | Start (find gaps) and end (confirm coverage) |
| `crossref_check.rb` | Paper metadata vs Crossref; suggests DOIs | After paper edits |
| `check_data.rb` | Structural YAML checks (ids, highlights, required fields, page ranges, syllabus files) | After every data edit |
| `smoke.sh` | Every page returns 200, clean server log | After every group of edits |
| `shoot.mjs` | Before/after screenshots at 1280px and 390px | Before the first edit, after template changes |

Keep `SECTIONS` in `cv_check.rb` in step with any new data file.

## Procedure

0. **Is a refresh due?** Compare the CV footer `updated: Mon-DD-YYYY` with the site copy: `pdftotext source/downloads/SoumyaRay-CV.pdf - | grep -m1 updated`. If they match, tell the user and stop.
1. **Plan.** Start a plan folder under `.claude/plans/` (next `NNN`, per `.claude/CLAUDE.md`) and point `CLAUDE.local.md` at it.
2. **Baseline.** `ruby scripts/check_data.rb`; `bundle exec rake build`; `python3 -m http.server 8765 -d build &`; `(cd scripts && node shoot.mjs shots/before)`.
3. **Gap report.** `ruby scripts/cv_check.rb`. Present the gaps to the user as a checklist (grouped by data file) and ask about anything not covered by the conventions below. Do not edit blindly.
4. **Papers.** Edit `journal_papers.yml` / `conference_papers.yml` / `books.yml`, then `ruby scripts/crossref_check.rb`. Crossref wins over the CV for volume, issue, pages, year, and author order (the CV keeps stale online-first details). Add `doi:` to every paper Crossref knows.
5. **Other data files.** The CV wins for content (award and role names, dates), except for the corrected names listed below.
6. **Syllabi.** See the section below.
7. **CV download.** Replace `source/downloads/SoumyaRay-CV.pdf` with the CV PDF.
8. **Check.** `ruby scripts/check_data.rb`, `bash scripts/smoke.sh`, rebuild, `(cd scripts && node shoot.mjs shots/after)`, and look at the changed pages.
9. **Coverage.** `ruby scripts/cv_check.rb` again. Every remaining flag must be a deliberate omission (below). Record new ones in this skill.
10. **Tell the user** about errors found in the CV (it is read-only; they fix it).
11. **Commit and deploy** (ask before pushing). Commit on `source` with a `data:` prefix, push, `bundle exec rake build`, review `git -C build status`/diff, commit `build: … (source <sha>)` and push `master` from `build/`. GitHub Pages updates within a minute; check key URLs with `curl -s -o /dev/null -w '%{http_code}'` (each page, `/downloads/SoumyaRay-CV.pdf`, `/downloads/syllabi/*.pdf`).
12. **Update this skill** with anything learned.

## Syllabi

- Take the newest term's syllabus **PDF** from the course folder (handouts/slides folder, `00 - <ID> Syllabus - <year>.pdf`). Folders: `SOA Course/<year> SOA Class/`, `Service Security Course/<year> - IT Service Security/`, `Computational Statistics/<year> <term> - Computational Statistics for Data Science/`. Find them with `find "<folder>" -iname "*syllab*.pdf" -exec stat -f "%Sm  %N" -t "%Y-%m-%d" {} \;`.
- If the `.docx` is newer than the PDF, export a fresh PDF with Microsoft Word (no LibreOffice here). Word is sandboxed: copy the docx into `~/Library/Containers/com.microsoft.Word/Data/`, `open -a "Microsoft Word" <copy>`, wait until `osascript -e 'tell application "Microsoft Word" to get name of every document'` lists it, then export **by document name** (never `active document` — the user may have other files open, such as the CV):

  ```applescript
  tell application "Microsoft Word"
    set d to document "<copy>.docx"
    save as d file name "<container>/<copy>.pdf" file format format PDF
    close d saving no
  end tell
  ```

  Check the PDF (`pdftotext`, `pdftoppm -r 50 -png`), copy it to the site, then delete both files from the container. Never write into the teaching folders.
- Keep the TA names in the syllabi (user's choice, 2026-10).
- Copy to `source/downloads/syllabi/<course id>.pdf` (stable URL) and set `syllabus_term:` in `instruction.yml`.
- Ignore course folders not on the website (summer intro programming, BA MOOC) unless the user adds them.

## Conventions

- **Paper ids**: `<VENUE-ABBREV><issue year>`. Rename the id when the year changes; if `source/images/papers/<id>/` exists, `git mv` the folder too.
- **Year** = issue year (Crossref `published-print`), not the online-first year. Forthcoming papers: `year: forthcoming`, no volume.
- Article-numbered journals use `article:` (rendered "article N") instead of `pages:`.
- `note:` renders under the citation (used for the reproducibility-collaboration membership). `collaboration: true` moves a paper to the Collaboration Papers card.
- **Books**: `books.yml` entries use `publisher:` (book) or `book:` + `publisher:` + `pages:` (chapter); `url:` links the title (open-access editions).
- **Awards**: `Award – year(s) (Body)` with en dashes, newest first in each group. MOST/NSTC 傑出研究獎 is "Outstanding Research Award" in English (not "Distinguished"); name the body that gave it that year (MOST until 2022, then NSTC).
- **Grants**: grouped by role (PI / Co-I). Start year = ROC year in the grant ID + 1911; one-year grants span two calendar years (Aug–Jul); `-MY3` spans three. Co-I projects have no dates or IDs.
- **Courses**: `name` carries the abbreviation; the page does not append `(id)`. `id` = the abbreviation and keys both `images/courses/<id>/` and `downloads/syllabi/<id>.pdf`; renaming a course means `git mv` of the image folder. CSDS was "Business Analytics Using Computational Statistics (BACS)" (id BASM) until 2025; its overview image still says "BASM".
- **Talks**: one `talks.yml` entry per title, venues newest first; the file is ordered by latest venue year (the home page shows the first two). A recurring talk uses `year: "2020-2026"`.
- **Software**: SEMinR's home is <https://seminr.io>; check its resources page for new books or videos (`book_url`, `video_url`).
- **Names the site corrects** (check when copying from the CV): McIntire School of **Commerce**; **National** Chung Cheng University; University of Technology and Applied **Sciences** – Ibri; Taipei Computer Association (台北市電腦商業同業公會; CV says "Taiwan"); the Emerald book is "**Applying** Partial Least Squares in Tourism and Hospitality Research" (CV says "Application of PLS-SEM in …"). CV typos the site corrects: "Informaion", "Difusion", "Pacific Asian Journal…".

## Deliberate omissions (expected `cv_check.rb` flags)

- Academic experience / education and university–industry collaborations: user said "leave out for now" (2026-10). **Ask again** each refresh.
- PhD scholarships (pre-2010), UW teaching-assistant work, project assistantships/internships, working papers.

## Known CV errors (as of the Sep-28-2026 CV — recheck, then tell the user if still present)

- ISF 2022 pages: CV 570–594, Crossref 579–594.
- Decision Sciences paper: CV "2018, (21:1), pp. 243-241" and order Sharma, Sarstedt, Shmueli; Crossref 2021, 52(3), 567–607, order Sharma, Shmueli, Sarstedt, Danks, Ray.
- Cyberloafing (ITEM): CV 2017, pp. 1–19; Crossref 2018, 19(4), 197–215.
- compstatslib repo: CV says `github.com/soumyaray/compstatslib`; the package uses `github.com/compstatslib/compstatslib` (the site uses the latter).
