# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal academic website for soumyaray.com, a static site built with Middleman 4 (Slim templates, YAML data files) and hosted on GitHub Pages from the `soumyaray/soumyaray.github.io` repo. Ruby version comes from `.ruby-version` (the Gemfile reads it).

## Commands

```bash
bundle install
bundle exec rake serve      # middleman serve (http://localhost:4567); no livereload, refresh manually
bundle exec rake build      # middleman build → ./build (CSS/JS minified)
bundle exec rake images:convert:thumbnail   # *_original.png → *_thumb.png (200px wide)
bundle exec rake images:convert:modal       # *_original.png → *_modal.png (568px wide)
bundle exec rake images:delete              # remove all *_thumb.png
bundle exec rake url:integrity URL=https://…/lib.js   # sha384 SRI hash for a CDN asset
```

Image tasks need ImageMagick (`convert`). There are no tests or linters; `scripts/` (outside `source/`, so never built) has dev checks, documented in `scripts/README.md`:

```bash
bash scripts/smoke.sh                       # middleman serve, every page must return 200
(cd scripts && node shoot.mjs shots/after)  # Playwright screenshots of a served build (needs npm install once)
ruby scripts/check_data.rb                  # data/*.yml structure: unique ids, highlights resolve, paper fields
ruby scripts/crossref_check.rb              # paper metadata vs Crossref (network)
ruby scripts/cv_check.rb                    # CV sections vs data/*.yml coverage report
```

## Branches, build, and deploy

One GitHub repo, two branches with unrelated contents:

- **`source`** (this working tree, the default for work): Middleman project — `config.rb`, `Rakefile`, `source/`.
- **`master`**: only the generated static site, which GitHub Pages serves. Never edit it by hand, and never merge between `source` and `master`.

`build/` is gitignored on `source`, but it is itself a **separate clone of the same repo, checked out on `master`** (it has its own `build/.git`). Middleman's build clean skips dotfiles, so `build/.git` survives each rebuild. The deploy flow is:

1. On `source`: edit, `rake build`, commit and push `source`.
2. `cd build`, review `git status`/diff, then commit and push `master` from there (`git -C build …`).

The `master` branch in this outer checkout is stale (years behind); the up-to-date `master` is the one in `build/`.

`source/CNAME` and `source/.nojekyll` are copied into the build so Pages keeps the custom domain and skips Jekyll.

## Content and images

`data/` (YAML content) and `source/images/` are tracked on `source`. Content edits show up in `git diff` on `source` and, after a rebuild, as changed HTML in `build/`. Commit messages with a `data:` prefix cover content changes.

The source of truth for content is the CV at `/Users/soumyaray/Sync/Dropbox/Work/Curriculum Vitae/Soumya Ray - CV.pdf` (and `.docx`; older versions in `OLD CVs/`). Treat it as **read-only**: read it (e.g. `pdftotext -layout`), never edit or move it. The site's download copy is `source/downloads/SoumyaRay-CV.pdf`; replace it with the latest PDF when content is refreshed. The full refresh procedure is the `cv-update` skill (`.claude/skills/cv-update/SKILL.md`).

Images are stored once in the repo: git shares a blob across branches, so an image on both `source` and `master` costs nothing extra.

`config.rb` keeps source-only images out of the build with `ignore`: every `*_original.*` file and `images/research/**`. Pages use only `*_thumb.png`, `*_modal.png`, `photo/soumya-ray-{thumb,modal}.jpg` (sidebar photo and its modal; the full-size download is `source/downloads/soumya-ray-photo.jpg`), and `software/*/logo.png`. If a page starts to reference an ignored file, change the `ignore` rules.

## Architecture

- `source/layouts/layout.slim`: single layout — Bootstrap 5.3.8 (Bootswatch "materia"), Font Awesome 7 and Academicons from jsDelivr with SRI hashes (use `rake url:integrity` when changing a CDN URL), no jQuery, Cookiebot consent script, a left sidebar (`partials/_side_menu.slim`), and page content on the right.
- `stylesheets/styles.css` loads *before* Bootstrap, so rules that must beat Bootstrap are prefixed with `#bootstrap-override` (the body id). The section at the end keeps the look of the old Bootstrap 3 Paper theme.
- Icons: Font Awesome 7 classes (`fa-solid fa-…`, `fa-brands fa-…`), also used for `icon:` in `data/social.yml`. Brand icons that ad-blockers hide use `fa-brands my-fa-…` from `social_adblock_workaround.css`.
- Top-level pages are `source/*.html.slim` (index, research, talks, service, software, courses, achievements, social). Each renders from a matching file in `data/` through Middleman's `data.<file>` accessor:
  - `journal_papers.yml` (`highlights:` list of paper ids + `papers:`; `collaboration: true` papers get their own card), `conference_papers.yml`, `books.yml` → `research`, and `index` (shows the first two highlighted papers)
  - `talks.yml` → `talks` and `index` ("Recent Talks" shows the first two)
  - `instruction.yml` → `courses` and `index`; `achievements.yml`, `service.yml`, `software.yml`, `social.yml` → their pages (`social` also feeds `partials/social/_contact_me.slim`)
  - The commented template at the top of each YAML file shows the expected fields; `partials/_research_papers.slim` shows which paper fields render.
- Figures: `partials/_img_thumb_modal.slim` expects `source/images/<papers|courses>/<id>/<img>_thumb.png` and `<img>_modal.png`, where `<id>` matches the YAML entry's `id` and `<img>` is `figure` or `overview`. Add the new `<img>_original.png` and run the two `images:convert` tasks to make the sizes.
- Syllabi PDFs live in `source/downloads/syllabi/<course id>.pdf`; the CV PDF is `source/downloads/SoumyaRay-CV.pdf`.
- `source/partials/*.md` partials are Markdown (e.g. current position text on the home page).
- `config.rb`: layout-free `.xml/.json/.txt`, CSS/JS minification on build. middleman-livereload was dropped because it caps Rack below 3.2.

## Plans

Planning and working docs live in `.claude/plans/` (gitignored, and symlinked
into new worktrees via Sideways when configured). Each work stream gets its own
folder there.

- Folder name: `NNN-PURPOSE-slug` — `NNN` is a zero-padded sequence (`001`, `002`, …) that strictly increments and is never reused; `PURPOSE` is an uppercase tag for the document that started the stream (`PLAN`, `BUGFIX`, `REFACTOR`, …); `slug` is short kebab-case, usually from the branch name.
- The main document is named for its kind (`PLAN.md`, `BUGFIX.md`). When a folder holds two or more, prefix each with a reading-order letter (`a-PLAN.md`, `b-BUGFIX.md`).
- Supporting files keep a kind tag and no letter (`SKETCHES.html`, `ASSET-og-card.html`).
- Reference files in the same folder by bare filename; files in other folders by full path from the repo root.
- `CLAUDE.local.md` `@`-includes the active plan.
- Closed plans get a `> **CLOSED** (date): …` note under the title and keep their number.
