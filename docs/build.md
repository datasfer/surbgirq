# Building

`master` builds with Stack and GHC 9.6.7 (checked on Linux in November 2026). The rest of these notes come from the code and
from the author's notes of 2024–2026.

## Toolchain

| GHC | Stackage resolver | Notes |
|---|---|---|
| 9.6.7 | `lts-22.44` | `stack.yaml` sets `allow-newer: true`, and asks for `-j4` with large GHC heaps for every package (so does `cabal.project.local`): lower `-j` on a small machine. `surbgirq-shell` is left out of the build (a `selda` conflict; see the README's Known issues). The Facebook Messenger packages are commented out. `shell.nix` is a plain `mkShell` (zlib, sqlite, openssl, HLS). |

```bash
stack build        # Stack installs GHC 9.6.7 and fetches the Telegram fork at its pinned commit

# or with Cabal: clone the Telegram fork next to this repository, at the commit that stack.yaml pins
git clone https://github.com/ArthurVard/haskell-telegram-api.git ../haskell-telegram-api
git -C ../haskell-telegram-api checkout 94c40a15515920a4919fb4dc1a7ee008d598765d
cabal build all
```

Until November 2026 `master` was on GHC 9.4.8 (`lts-21.25`); the GHC 9.6.7 work came from the `bump-9.6.7` branch (see the
README's Branches).

## Forked dependencies

| Fork | Why | Pinned commit |
|---|---|---|
| [`ArthurVard/haskell-telegram-api`](https://github.com/ArthurVard/haskell-telegram-api) | The Telegram Bot API client: upstream `klappvisor/haskell-telegram-api` (Bot API 3.5) plus build fixes for newer GHCs | `94c40a15` |
| [`ArthurVard/fbmessenger-api-hs`](https://github.com/ArthurVard/fbmessenger-api-hs) | The Facebook Messenger client (dead code; commented out in `stack.yaml`) | `409b9369` |

## System packages

On Debian or Ubuntu the author installed:

```bash
sudo apt-get install git-core zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev \
  libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev
```

Two build failures and their fixes, from the same notes:
- `pcre-light` failed until `libghc-pcre-light-dev` was installed (it brings the PCRE headers);
- `regex-pcre` failed (`[S-7011]`) until `pkg-config` was installed.

The notes also list `libghc-regex-pcre-dev`, `libghc-regex-base-dev`, `libghc-regex-tdfa-dev`, `libpcre2-posix3`, `libgmp-dev`
and `libgbm-dev`. No package needs PostgreSQL's client library (`libpq`) any more: `postgresql-simple`, the only user, was
listed but never imported, and is gone since November 2026.

## Executables

| Executable | Package | What it does |
|---|---|---|
| `telegram-bot` | `surbgirq` | The Telegram bot: a webhook server on port 5000 ([bot.md](bot.md)) |
| `verse-explorer` | `surbgirq` | The verse explorer web page, port 8009 |
| `html-scraper` | `surbgirq-shell` | HTML → YAML ([data-pipeline.md](data-pipeline.md)) |
| `surbgirq-shell` | `surbgirq-shell` | YAML → CSV or Cypher |
| `theographic` | `surbgirq-shell` | Theographic CSV → the KJV CSVs |
| `surbgirq-sqlite` | `surbgirq-shell` | The lexicon into SQLite |
| `surbgirq-db`, `surbgirq-service` | dead packages | Not in `stack.yaml`, so not built |

The four `surbgirq-shell` executables aren't built at the moment (see the README's Known issues).

Run them from the `surbgirq/` package folder inside the repository (`cd surbgirq && stack exec -- telegram-bot`; in a clone
named `surbgirq`, that's `surbgirq/surbgirq/`): the default config paths are relative to it.

## Tests

`stack test` builds and runs the test suite of every package in `stack.yaml`. Most are still template stubs;
`surbgirq-utils`'s suite tests what the bot makes of a typed verse reference (`parseVerseRef`) and the title it
gives every book in every translation (`toRefText`), so run `stack test surbgirq-utils` after changing the parser or
the book names. (`surbgirq-db`, whose test needs a live Neo4j, isn't in the build.)
