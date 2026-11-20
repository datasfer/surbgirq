# Building

Nothing was built for the 2026 publication. These notes come from the code and from the author's notes of 2024–2026.

## Toolchain per branch

| Branch | GHC | Stackage resolver | Cabal | Notes |
|---|---|---|---|---|
| `master`, `fix-api` | 9.4.8 | `lts-21.25` | `cabal.project` lists the packages but not the forked dependencies, so use Stack | `stack.yaml` sets `allow-newer: true`, and points `extra-include-dirs`/`extra-lib-dirs` at a machine-specific `/nix/store/…-postgresql-11.7`; remove or adapt those two lines |
| `bump-9.6.7` | 9.6.7 | `lts-22.44` | `cabal.project` with `with-compiler: ghc-9.6.7`, plus local clones of two forks next to the repository: `../haskell-telegram-api`, `../hs-connection` | `surbgirq-shell` is left out of the build (a `selda` conflict); the Facebook Messenger packages are commented out; `shell.nix` is a plain `mkShell` (zlib, sqlite, libpq, openssl, HLS) |

```bash
# master, fix-api
stack build

# bump-9.6.7, with Cabal: clone the two forks next to this repository first
git clone https://github.com/ArthurVard/haskell-telegram-api.git ../haskell-telegram-api
git clone https://github.com/ArthurVard/hs-connection.git ../hs-connection
cabal build all
```

The `cabal.project` on `bump-9.6.7` takes the forks' working trees as they are, so check out the commit that `stack.yaml` pins
(below) in each clone.

## Forked dependencies

| Fork | Why | Pinned commit |
|---|---|---|
| [`ArthurVard/haskell-telegram-api`](https://github.com/ArthurVard/haskell-telegram-api) | The Telegram Bot API client: upstream `klappvisor/haskell-telegram-api` (Bot API 3.5) plus build fixes for newer GHCs | `4bfb0354` on `master`/`fix-api`, `94c40a15` on `bump-9.6.7` |
| [`ArthurVard/fbmessenger-api-hs`](https://github.com/ArthurVard/fbmessenger-api-hs) | The Facebook Messenger client (dead code) | `409b9369` on `master`/`fix-api` |
| [`ArthurVard/hs-connection`](https://github.com/ArthurVard/hs-connection) | Needed by hasbolt 0.1.7.0, which only the dead `surbgirq` executable uses | `98b7b0ef` on `bump-9.6.7` (no branch points at it any more; Stack fetches it by its ID) |

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
and `libgbm-dev`. The PostgreSQL client library (`libpq`) is in the Nix shell of `bump-9.6.7` as well.

## Executables

| Executable | Package | What it does |
|---|---|---|
| `telegram-bot` | `surbgirq` | The Telegram bot: a webhook server on port 5000 ([bot.md](bot.md)) |
| `verse-explorer` | `surbgirq` | The verse explorer web page, port 8009 |
| `surbgirq` | `surbgirq` | Opens a hasbolt connection pool and never serves (dead) |
| `html-scraper` | `surbgirq-shell` | HTML → YAML ([data-pipeline.md](data-pipeline.md)) |
| `surbgirq-shell` | `surbgirq-shell` | YAML → CSV or Cypher |
| `theographic` | `surbgirq-shell` | Theographic CSV → the KJV CSVs |
| `surbgirq-sqlite` | `surbgirq-shell` | The lexicon into SQLite |
| `surbgirq-db`, `surbgirq-service` | dead packages | Not in `stack.yaml`, so not built |

Run them from the `surbgirq/` folder (`cd surbgirq && stack exec -- telegram-bot`): the default config paths are relative to it.

## Tests

The test suites are template stubs. `surbgirq-db`'s test needs a live Neo4j, and several suites name modules that don't
exist, so expect `stack test` to fail.
