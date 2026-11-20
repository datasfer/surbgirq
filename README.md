# Surbgirq

A Telegram bot, a data pipeline and a small web page around **Surbgirq**, a Neo4j knowledge graph of Armenian Bible
translations, the King James Version, and Bible metadata: people, places, events, years and Easton's Bible Dictionary. The
graph also holds Grigor Narekatsi's *Book of Lamentations* (Narek) and a lexicon of Classical Armenian word roots and their
word forms.

*Surb Girq* (Սուրբ Գիրք) is Armenian for "Holy Book". This repository is the Haskell side of the project, 2019–2026. The
REST API that serves the graph lives in [`datasfer/surbgirq-graph-api`](https://github.com/datasfer/surbgirq-graph-api)
(ASP.NET Core); the bot reads the graph through it.

**Status:** nothing here runs at the moment. The code is published as it was last changed (February 2026), without a new
build. Bringing the bot back on a current stack is the next phase. Read
[Known issues / security](#known-issues--security) before running any of it.

## What's here

| Part | What it does | Where |
|---|---|---|
| **Telegram bot** (`@SurbgirqBot`) | Looks up verses by reference, in chat and in inline mode, in several translations, with per-user settings ([docs/bot.md](docs/bot.md)) | `surbgirq-bot/*`; the `telegram-bot` executable in `surbgirq/` |
| **Data pipeline** | Scrapes Bible texts from HTML into YAML, turns YAML into CSV for `neo4j-admin`, converts Theographic's KJV metadata, builds the lexicon ([docs/data-pipeline.md](docs/data-pipeline.md)) | `surbgirq-shell`: `html-scraper`, `surbgirq-shell`, `theographic`, `surbgirq-sqlite` |
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

| Branch | Last change | What it is |
|---|---|---|
| `master` (default) | 2024-03 | The 2024 state: GHC 9.4.8 (Stackage `lts-21.25`), Neo4j 5.15 in Docker |
| `bump-9.6.7` | 2026-02 | GHC 9.6.7 (`lts-22.44`) and Cabal build fixes with local clones of two forks; `surbgirq-shell` left out of the build (a `selda` conflict); the Facebook Messenger code commented out; Neo4j 5.26.6; a Nix shell |
| `fix-api` | 2026-01 | The bot's API client switched to `surbgirq-graph-api`'s `/api/…` routes; Neo4j 5.18.1 |

Both newer branches start from `master` and haven't been merged; merging them is part of the revival. All three carry the same
documentation, licence files and log clean-up from 2026.

## Build and run

The short version; system packages, the forks and the per-branch differences are in [docs/build.md](docs/build.md).

```bash
stack build                          # master and fix-api; bump-9.6.7: see docs/build.md
cd surbgirq
stack exec -- telegram-bot           # the bot: config/bot-settings.yaml, webhook server on port 5000
stack exec -- verse-explorer         # the web page: config/verse-explorer.yaml, port 8009
```

The bot also needs its own token ([docs/bot.md](docs/bot.md)), the graph in Neo4j
([docs/neo4j-import.md](docs/neo4j-import.md)), and `surbgirq-graph-api` listening on `localhost:33010`.

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
- **2025–2026:** the GHC 9.6.7 upgrade (`bump-9.6.7`) and the switch to `surbgirq-graph-api`'s routes (`fix-api`).
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
| `fix-api`: the bot asks `surbgirq-graph-api` for one verse and for sections under `api/scriptures/…`, but the API serves them under `api/verses/…`; `…/verses/count` always returns 100. | Align the two when the bot runs again |
| The API address is hard-coded (`http://localhost:33010` in `ClientRequests.hs`). | Configuration |
| A reference without a translation word uses the translation of its book abbreviation: Armenian abbreviations mean the 1994 translation (which public data won't include), English ones the KJV. The user's translation setting is ignored for references. | Use the setting as the default, and default to a public text |
| User settings live in memory (an STM `TVar`) and are lost on restart. | A small persistent store |
| The Docker Compose files run **Neo4j Enterprise** and accept its commercial licence (`NEO4J_ACCEPT_LICENSE_AGREEMENT=yes`). | Neo4j Community ([docs/neo4j-import.md](docs/neo4j-import.md)) |
| On Neo4j 2026.x the import needs `--vector-delimiter` (its default, `;`, is our column delimiter), and `--multiline-fields=true` slows the whole import although only Easton's dictionary needs it. | [docs/neo4j-import.md](docs/neo4j-import.md) |
| The verse explorer was adapted from an earlier block-explorer prototype by the same author: `app.js` still has a live counter and a filter dialog that nothing feeds, and some names (`txhash`, `tx-list`) remain. Its search always answers "Not found"; `/about` is a placeholder. | Rework the page during the revival |
| `html-scraper --z1805` runs the v1805 parser; `--json` and `--csv` still write YAML. `theodata/ar94-books.yaml` points at `e1994-T`. | Fix with the next pipeline run |
| Tests are stubs ("not yet implemented"); `surbgirq-db`'s test needs a live Neo4j; several test suites name modules that don't exist. | Real tests where the code is touched |
| `master`'s `cabal.project` doesn't list the forked dependencies, so a plain Cabal build can't resolve them; use Stack there. | One build setup after merging the branches |
| The `surbgirq` executable opens a hasbolt connection pool and never serves; on `bump-9.6.7` it is the only reason the build needs the `hs-connection` fork. | Remove it together with the dead packages |
| The Facebook Messenger integration (2020) is dead code, and commented out on `bump-9.6.7`. | Remove it |

## License

All code in this repository is licensed under the MIT License; see [LICENSE](LICENSE). Each Haskell package carries the
same text. The verse explorer's vendored front-end libraries keep their own licences; see
[THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md). The repository contains no Bible text or other data; see [Data](#data).
