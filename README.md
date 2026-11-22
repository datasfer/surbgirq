# Surbgirq

A Telegram bot, a data pipeline and a small web page around **Surbgirq**, a Neo4j knowledge graph of Armenian Bible
translations, the King James Version, and Bible metadata: people, places, events, years and Easton's Bible Dictionary. The
graph also holds Grigor Narekatsi's *Book of Lamentations* (Narek) and a lexicon of Classical Armenian word roots and their
word forms.

*Surb Girq* (Սուրբ Գիրք) is Armenian for "Holy Book". This repository is the Haskell side of the project, 2019–2026. The
REST API that serves the graph lives in [`datasfer/surbgirq-graph-api`](https://github.com/datasfer/surbgirq-graph-api)
(ASP.NET Core); the bot reads the graph through it.

**Status:** nothing here runs in public at the moment. `master` builds with Stack and GHC 9.6.7 (checked in November 2026);
bringing the bot back on a current stack is the current phase. Read [Known issues / security](#known-issues--security) before
running any of it.

## What's here

| Part | What it does | Where |
|---|---|---|
| **Telegram bot** (`@SurbgirqBot`) | Looks up verses by reference, in chat and in inline mode, in several translations, with per-user settings ([docs/bot.md](docs/bot.md)) | `surbgirq-bot/*`; the `telegram-bot` executable in `surbgirq/` |
| **Data pipeline** | Scrapes Bible texts from HTML into YAML, turns YAML into CSV for `neo4j-admin`, converts Theographic's KJV metadata, builds the lexicon ([docs/data-pipeline.md](docs/data-pipeline.md)) | `surbgirq-shell`: `html-scraper`, `surbgirq-shell`, `theographic`, `surbgirq-sqlite` (not built at the moment; see [Known issues](#known-issues--security)) |
| **Import scripts** | Bulk-load the CSVs into Neo4j ([docs/neo4j-import.md](docs/neo4j-import.md), [scripts/README.md](scripts/README.md)) | `scripts/`, `docker/` |
| **Verse explorer** | A small server-rendered web page (Lucid): books and verses ([its README](surbgirq-web/verse-explorer/README.md)) | `surbgirq-web/verse-explorer/`; the `verse-explorer` executable |
| Shared code | Domain types (books, chapters, verses, translations, Armenian and English book abbreviations), helpers, the API client | `surbgirq-types`, `surbgirq-utils`, `common`, `surbgirq-api/surbgirq-api-instances`, `surbgirq-api/surbgirq-neo4j-client` |
| **Dead packages** | The first Haskell REST API and its Neo4j access, kept for the record ([below](#the-dead-packages-and-why)) | `surbgirq-api/surbgirq-api`, `surbgirq-api/surbgirq-api-client`, `surbgirq-db`, `surbgirq-service` |

### The dead packages, and why

The project started in 2019 with its own Haskell REST API over Neo4j: `surbgirq-api` (Servant types, Swagger, a WebSocket
channel), `surbgirq-service` (the server) and `surbgirq-db` (queries through the
[hasbolt](https://hackage.haskell.org/package/hasbolt) driver). In 2020 Neo4j 4 changed the Bolt protocol, and hasbolt could
no longer connect. The data access moved to a .NET API, today's
[`surbgirq-graph-api`](https://github.com/datasfer/surbgirq-graph-api), which the bot calls through
`surbgirq-api/surbgirq-neo4j-client`. The old packages stay in the tree, but `stack.yaml` doesn't list them, so nothing builds
them. Released hasbolt versions still speak only Bolt 3, so they can't reach Neo4j 5 either.

## Branches

`master` is the only branch. Two side branches were brought into it on 2026-11-21, as four topic commits, and then deleted:

| Branch | Work | What it brought |
|---|---|---|
| `fix-api` | 2024-03 → 2026-01 | The bot's API client and the verse explorer's links on `surbgirq-graph-api`'s `/api/…` routes |
| `bump-9.6.7` | 2025-05 → 2026-02 | GHC 9.6.7 (`lts-22.44`) and Cabal build fixes; `surbgirq-shell` and the Facebook Messenger packages left out of the build; Neo4j 5.26.6 in Docker; `hie.yaml` and a Nix shell |

`fix-api`'s own commits are still on its pull request, [#1](https://github.com/datasfer/surbgirq/pull/1).

## Build and run

The short version; system packages, the Cabal build and the fork are in [docs/build.md](docs/build.md).

```bash
stack build                          # GHC 9.6.7 (lts-22.44); Stack installs the compiler and fetches the Telegram fork
cd surbgirq                          # the package folder inside the repository: the config paths are relative to it
stack exec -- telegram-bot           # the bot: config/bot-settings.yaml, webhook server on port 5000
stack exec -- verse-explorer         # the web page: config/verse-explorer.yaml, port 8009
```

The bot also needs its own token ([docs/bot.md](docs/bot.md)), the graph in Neo4j
([docs/neo4j-import.md](docs/neo4j-import.md)), and `surbgirq-graph-api` listening on `localhost:33010` (or wherever
`GRAPH_API_URL` points).

## Secrets

No secret is committed. Tokens and passwords come from environment variables, set in git-ignored files (`.env` and
`.env.*`, except `.env.example`):

- **Neo4j's password:** in `docker/.env`, which Compose reads by itself; copy [`docker/.env.example`](docker/.env.example), and
  see [docs/neo4j-import.md](docs/neo4j-import.md);
- **the bot's token:** still hard-coded until the next fix; see [Known issues](#known-issues--security).

**A pre-commit hook** in [`.githooks/`](.githooks/pre-commit) stops a commit when a staged file contains anything
[gitleaks](https://github.com/gitleaks/gitleaks) finds, a Telegram bot token in any form, or a literal password in a config
file. Turn it on once per clone:

```bash
git config core.hooksPath .githooks
```

It needs gitleaks 8.19 or newer on your `PATH`: `winget install --id Gitleaks.Gitleaks --exact` on Windows,
`brew install gitleaks` on macOS. On Linux, download `gitleaks_<version>_linux_x64.tar.gz` and
`gitleaks_<version>_checksums.txt` from its [releases](https://github.com/gitleaks/gitleaks/releases), then:

```bash
sha256sum --ignore-missing -c gitleaks_*_checksums.txt
tar -xzf gitleaks_*_linux_x64.tar.gz gitleaks
install -D -m 755 gitleaks ~/.local/bin/gitleaks
```

The hook names the file and the line, never the value. On a false alarm, check twice, then commit once with
`git commit --no-verify`.

## Data

- **This repository holds code, not data.** The pipeline's inputs and outputs (HTML, YAML, CSV) lived in a `data/` folder
  until 2022, and then in a separate private repository. They were removed from this repository's history before publishing
  ([History](#history)).
- **What the graph combines, and what can be shared** (sources and credits: [docs/data-sources.md](docs/data-sources.md)):

  | Text or dataset | Status |
  |---|---|
  | Zohrab Bible, Venice 1805, Classical Armenian | Public domain; planned as a downloadable release |
  | Narek, *Book of Lamentations*, the Classical Armenian original | Public domain; planned, once its digital source is confirmed |
  | King James Version, with Theographic Bible Metadata (people, places, events, years, Easton's) | The KJV is public domain; Theographic is CC BY-SA 4.0, to be downloaded from its own repository, not re-hosted |
  | The 1994 Etchmiadzin translation, modern Eastern Armenian | **Copyrighted** (Mother See of Holy Etchmiadzin and the Bible Society of Armenia), so not published |
  | Narek in Mkrtich Kheranyan's modern translation (1960) | **Copyrighted** until the end of 2040, so not published |
  | The Classical Armenian word list (forms, roots, grammar tags, English glosses) | From the Arak29 Foundation's annotated Bible, all rights reserved, so not published |

- **The code still knows these translations,** through IDs such as `e1994-T` and the book lists in `theodata/`, because a
  private graph may contain them.

## History

- **2019:** started as a Haskell project: domain types, HTML scrapers, a Servant API over Neo4j, Nix and Docker.
- **2020:** the Telegram bot (webhook, inline mode, settings); the .NET API took over the data access when Neo4j 4 broke
  hasbolt; the KJV and Theographic layer.
- **2021:** the verse explorer; Narek.
- **2022:** the text data moved out of this repository.
- **2024:** the Neo4j 5 bulk import: 916,443 nodes and 996,178 relationships in one run.
- **2025–2026:** the GHC 9.6.7 upgrade (`bump-9.6.7`) and the switch to `surbgirq-graph-api`'s routes (`fix-api`), on two
  side branches.
- **2026-11:** published; the two side branches brought into `master`; the dead `surbgirq` executable removed, and with it
  hasbolt and the `hs-connection` fork.
- **The history was rewritten before publishing (2026).**
  - Secrets and server addresses were replaced by `CHANGE_ME`, `REMOVED-TELEGRAM-TOKEN`, `REMOVED-FACEBOOK-TOKEN`,
    `REMOVED-SENDGRID-KEY` and `192.0.2.x` documentation addresses.
  - Removed from every commit: the text data; a copied example bot; a Neo4j 3.5 plugin jar; an unused module and four logos
    from an earlier block-explorer prototype; a dead deploy script; a 2021 demo GIF of the bot, because it showed a
    copyrighted translation (a new demo will come when the bot runs again); and two notes files holding text copied from
    other sources.
  - The few sample strings of the 1994 translation in the scrapers' test code were replaced: the verse by the Zohrab 1805
    text, the section heading by a placeholder.
  - Commits that only changed data are kept, now empty. Dates, authors and messages are unchanged. Some old commits don't
    build as checked out, because files they need were removed.

## Known issues / security

Nothing runs this code in public at the moment. Fix these before it does:

| Issue | Planned fix |
|---|---|
| **The bot token is hard-coded** in `Telegram.hs`. The public copy holds the placeholder `REMOVED-TELEGRAM-TOKEN`, so the bot doesn't work until a real token is put there. | Read it from the configuration or an environment variable |
| **The webhook is open:** no secret path, and no `X-Telegram-Bot-Api-Secret-Token` check (the check is a stub, `let b = True`). | Set `secret_token` in `setWebhook` and check the header |
| **A failing handler answers 500,** so Telegram retries and holds back that chat's later updates. Some handlers call `error` when an API call fails. | Catch errors, always answer 200 |
| The bot's logs were cut down before publishing (no token, no user data), so they say little about failures. | Structured logging that never prints the token or user data |
| The bot asks `surbgirq-graph-api` for one verse and for sections under `api/scriptures/…`, but the API serves them under `api/verses/…`; `…/verses/count` always returns 100. The verse explorer forwards the same routes. | Align the two when the bot runs again |
| A reference without a translation word uses the translation of its book abbreviation: Armenian abbreviations mean the 1994 translation (which public data won't include), English ones the KJV. The user's translation setting is ignored for references. | Use the setting as the default, and default to a public text |
| User settings live in memory (an STM `TVar`) and are lost on restart. | A small persistent store |
| The Docker Compose files run **Neo4j Enterprise** and accept its commercial licence (`NEO4J_ACCEPT_LICENSE_AGREEMENT=yes`). | Neo4j Community ([docs/neo4j-import.md](docs/neo4j-import.md)) |
| On Neo4j 2026.x the import needs `--vector-delimiter` (its default, `;`, is our column delimiter), and `--multiline-fields=true` slows the whole import although only Easton's dictionary needs it. | [docs/neo4j-import.md](docs/neo4j-import.md) |
| The verse explorer was adapted from an earlier block-explorer prototype by the same author: `app.js` still has a live counter and a filter dialog that nothing feeds, and some names (`txhash`, `tx-list`) remain. Its search always answers "Not found"; `/about` is a placeholder. | Rework the page during the revival |
| **The data pipeline (`surbgirq-shell`) is out of the build** since the GHC 9.6.7 upgrade: the author's note in `stack.yaml` names a `selda` conflict. So the CSV converters can't be rebuilt from `master` at the moment. | Update or replace `selda`, and bring the package back |
| `html-scraper --z1805` runs the v1805 parser; `--json` and `--csv` still write YAML. `theodata/ar94-books.yaml` points at `e1994-T`. | Fix with the next pipeline run |
| Tests are stubs ("not yet implemented"); `surbgirq-db`'s test needs a live Neo4j; several test suites name modules that don't exist. | Real tests where the code is touched |
| `cabal.project` needs a local clone of the Telegram fork next to the repository (`../haskell-telegram-api`), and lists the dead `surbgirq-api`, which `stack.yaml` doesn't build. Stack fetches the fork itself. | A `source-repository-package` entry for the fork; one package list for both tools |
| The Facebook Messenger integration (2020) is dead code; its packages are commented out of the build. | Remove it |

## License

All code in this repository is licensed under the MIT License; see [LICENSE](LICENSE). Each Haskell package carries the
same text. The verse explorer's vendored front-end libraries keep their own licences; see
[THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md). The repository contains no Bible text or other data; see [Data](#data).
