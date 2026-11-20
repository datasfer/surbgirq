# Verse explorer

A small server-rendered web page for browsing the Surbgirq graph: book lists, chapters, verses and sections, as HTML pages
built with [Lucid](https://hackage.haskell.org/package/lucid). It is the `verse-explorer` executable
(`surbgirq/app/Explorer.hs`) over this folder's `service` library.

It doesn't talk to Neo4j itself. Like the bot, it calls the graph API,
[`surbgirq-graph-api`](https://github.com/datasfer/surbgirq-graph-api), at `http://localhost:33010`, and renders what it
gets as HTML, or passes it on as JSON.

## Run it

```bash
cd surbgirq                           # the package folder inside the repository
stack exec -- verse-explorer          # http://localhost:8009
```

`surbgirq/config/verse-explorer.yaml` sets the host and port (8009), request logging, and `staticDir`, the folder with the
page's CSS, JavaScript and images (`EXPLORER_STATIC_PATH`; by default `../surbgirq-web/verse-explorer/front/`).

## Pages

| Route | What it shows |
|---|---|
| `/` | the books of the 1994 translation (`e1994-T`), Old and New Testament |
| the graph API's `/api/…` routes, forwarded to `surbgirq-graph-api` (four of them don't match it yet; see the root README's Known issues) | the same data as the API: the books of a translation, a verse range, one verse, a chapter's sections, a book's sections |
| `/about` | a placeholder |
| `POST /search` | always "Not found" |

How Bible references are written in the project: [docs/bot.md](../../docs/bot.md#references).

## Layout

| Path | What it is |
|---|---|
| `service/src/VerseExplorer/App.hs` | the routes and their handlers |
| `service/src/Lucid/Helper.hs`, `Lucid/Instances.hs` | the page layout (nav bar, footer, search box) and the HTML for books, verses and sections |
| `front/static/` | CSS, JavaScript and images; the third-party libraries are listed in [THIRD-PARTY-NOTICES.md](../../THIRD-PARTY-NOTICES.md) |

## State

- **It was adapted in 2021 from an earlier block-explorer prototype by the same author,** and some of that is still here:
  `front/static/js/app.js` has a live counter over a WebSocket and a filter dialog that nothing feeds; `custom.css` styles
  lists that the pages don't have; a few names (`txhash`, `tx-list`) remain.
- **The home page lists the 1994 translation,** which public data won't include ([data sources](../../docs/data-sources.md)).
- **It builds with the rest of `master`** (GHC 9.6.7, November 2026). Its rework belongs to the project's revival.
