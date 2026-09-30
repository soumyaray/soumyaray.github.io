# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal academic website for soumyaray.com, a static site built with Middleman 4 (Slim templates, YAML data files) and hosted on GitHub Pages from the `soumyaray/soumyaray.github.io` repo. Ruby version comes from `.ruby-version` (the Gemfile reads it). middleman-core 4.4.x requires Bundler `~> 2.0`, so the lockfile pins Bundler 2.7.2. Ruby 4's default Bundler 4 cannot resolve this bundle, so use `bundle _2.7.2_ …` if the automatic version switch does not happen.

## Commands

```bash
bundle install
bundle exec rake serve      # middleman serve with livereload (http://localhost:4567)
bundle exec rake build      # middleman build → ./build (CSS/JS minified)
bundle exec rake images:convert:thumbnail   # *_original.png → *_thumb.png (200px wide)
bundle exec rake images:convert:modal       # *_original.png → *_modal.png (568px wide)
bundle exec rake images:delete              # remove all *_thumb.png
bundle exec rake url:integrity URL=https://…/lib.js   # sha384 SRI hash for a CDN asset
```

Image tasks need ImageMagick (`convert`). There are no tests or linters.

## Branches, build, and deploy

One GitHub repo, two branches with unrelated contents:

- **`source`** (this working tree, the default for work): Middleman project — `config.rb`, `Rakefile`, `source/`.
- **`master`**: only the generated static site, which GitHub Pages serves. Never edit it by hand, and never merge between `source` and `master`.

`build/` is gitignored on `source`, but it is itself a **separate clone of the same repo, checked out on `master`** (it has its own `build/.git`). Middleman's build clean skips dotfiles, so `build/.git` survives each rebuild. The deploy flow is:

1. On `source`: edit, `rake build`, commit and push `source`.
2. `cd build`, review `git status`/diff, then commit and push `master` from there (`git -C build …`).

The `master` branch in this outer checkout is stale (years behind); the up-to-date `master` is the one in `build/`.

`source/CNAME` and `source/.nojekyll` are copied into the build so Pages keeps the custom domain and skips Jekyll.

## Content lives outside git

`.gitignore` on `source` excludes **`/data`** and **`/source/images`**. The YAML content and all images are not version-controlled on `source`; they exist only in this local folder (Dropbox-synced) and, in rendered form, in the built `master`. Consequences:

- Content edits (papers, courses, awards, etc.) show up in git only as changed HTML in `build/` after a rebuild. Do not expect `git diff` on `source` to show them.
- A fresh clone or a new worktree of `source` cannot build without copying/linking `data/` and `source/images/` in.
- Commit messages on `source` with a `data:` prefix cover hardcoded content that *is* tracked (e.g. `source/partials/_current_position.md`, `source/downloads/SoumyaRay-CV.pdf`).

## Architecture

- `source/layouts/layout.slim`: single layout — Bootstrap 3.3.6 (Bootswatch "paper"), Font Awesome 4.6.3 and jQuery 1.12.4 from CDNs with SRI hashes (use `rake url:integrity` when changing a CDN URL), Cookiebot consent script, a left sidebar (`partials/_side_menu.slim`), and page content on the right.
- Top-level pages are `source/*.html.slim` (index, research, service, software, courses, achievements, social). Each renders from a matching file in `data/` through Middleman's `data.<file>` accessor:
  - `journal_papers.yml` (`highlights:` list of paper ids + `papers:`), `conference_papers.yml` → `research`, and `index` (shows the first two highlighted papers)
  - `instruction.yml` → `courses` and `index`; `achievements.yml`, `service.yml`, `software.yml`, `social.yml` → their pages (`social` also feeds `partials/social/_contact_me.slim`)
  - The commented template at the top of each YAML file shows the expected fields; `partials/_research_papers.slim` shows which paper fields render.
- Figures: `partials/_img_thumb_modal.slim` expects `source/images/<papers|courses>/<id>/<img>_thumb.png` and `<img>_modal.png`, where `<id>` matches the YAML entry's `id` and `<img>` is `figure` or `overview`. Add the new `<img>_original.png` and run the two `images:convert` tasks to make the sizes.
- `source/partials/*.md` partials are Markdown (e.g. current position text on the home page).
- `config.rb`: layout-free `.xml/.json/.txt`, livereload in development, CSS/JS minification on build. `config.ru` lets the site run under Rack, but the normal path is `rake serve`.

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
