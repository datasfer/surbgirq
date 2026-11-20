# The data pipeline

How Bible texts become the Surbgirq graph. The inputs and outputs aren't in this repository (see the README's
[Data](../README.md#data) section); the commands show how the author ran each stage, with the `data/` layout of the time.

```text
HTML (saved pages, e-book XHTML, pages made by the conversion notebooks)
  └─ html-scraper ............ YAML, one file per chapter
       └─ surbgirq-shell ..... CSV files for neo4j-admin (nodes and relationships)
            └─ scripts/*.sh .. a Neo4j database (neo4j-import.md)
Theographic Bible Metadata (CSV)
  └─ theographic ............. the KJV, people, places, events, years, Easton's dictionary (CSV)
The word list (forms, roots, grammar tags, English glosses)
  └─ surbgirq-shell / surbgirq-sqlite ... Armat (root) and Token (word form) CSVs, an SQLite lexicon
```

All the code is in `surbgirq-shell` (`src/Surbgirq/Shell/…` and `app/…`).

## 1. HTML → YAML: `html-scraper`

```bash
stack exec -- html-scraper (--v1805 | --e1994 | --z1805 | --ar94) (--yaml | --json | --csv) -i <html folder> -o <output folder>
stack exec -- html-scraper --v1805 --yaml -i ./data/html/v1805 -o ./data/yaml      # example
```

| Scraper (`Scraper/Scalpel/…`) | Input | Output folder |
|---|---|---|
| `BibleScraper.parseE1994BibleHtml` | the 1994 Etchmiadzin text in qahana.am-style HTML (`p.Body-Text`, `span.Numeral`, footnotes) | `bible/am/e1994` |
| `GrabarBibleScraper.parseGrabarBibleHtml` | Zohrab 1805 from the e-book's XHTML | `bible/am/v1805` |
| `JupyterHtml.ZohrapScraper` | HTML written by the conversion notebooks (`p.verse-text`): Zohrab with variant notes, and the 1994 text from another source | `bible/am/z1805`, `bible/am/ar94`, `bible/am/e1994-J` |
| `Narek.XeranyanScraper` | Narek in Kheranyan's translation | `narek/am/<file>/<chapter>.yaml` (run from GHCi) |

Known bugs: `--z1805` runs the v1805 parser, and `--json`/`--csv` still write YAML.

## 2. YAML → CSV: `surbgirq-shell`

```bash
stack exec -- surbgirq-shell (--bible | --narek) (--cypher | --csv) -c <config> -i <yaml folder> -o <output folder>
stack exec -- surbgirq-shell --bible --csv -c ./theodata/corpora.conf -i ./data/yaml -o ./data/csv      # example
```

- **`theodata/corpora.conf`** says what to convert: the scriptures (the YAML folders and their book lists) and the
  translations' metadata files.
- **`theodata/*-translation.yaml`:** per translation: ID, name, year, language, dialect, spelling, translators, description.
- **`theodata/*-books.yaml`:** per translation: each book's name, Armenian abbreviations, title, order, chapter count,
  testament and input file.
- **`--cypher`** writes Cypher statements instead (the older model of `surbgirq-db`); the import uses the CSVs.

## 3. The KJV and Theographic: `theographic`

```bash
stack exec -- theographic --csv -i ./data/theodata/CSV -o ./data/csv      # --json isn't implemented
```

It reads [Theographic Bible Metadata](https://github.com/robertrouse/theographic-bible-metadata) and writes the KJV layer:
books, chapters, verses, people, places, events, years, people groups and Easton's dictionary entries, with their links.
The converters write CSV by string interpolation, with no escaping, so a `"` in a text or a `;` in an unquoted field would
break a row.

## 4. The lexicon

- **`surbgirq-sqlite`** reads `data/txt/engLemmas.txt` and `data/txt/wordForms.txt` and builds `db/ban.sqlite`.
- **`Store.Neo4j.wordFormsCSV`** turns `wordForms.txt` into `armats.csv`, `wordForms.csv` and `WordArmatRel.csv` for the
  `Armat` → `Token` part of the graph.

The word list itself isn't public ([data-sources.md](data-sources.md)).

## 5. Import

See [neo4j-import.md](neo4j-import.md) and [scripts/README.md](../scripts/README.md).

## The graph model

- **Text:** `Translation` → `Book` → `Chapter` → `Section` → `Verse` → `Word` (`Capitalized:Word` too), all linked by
  `CONTAINS`; `Verse` -`REF_FOOTNOTE`→ `Footnote`. Also `Testament`, `Division` and `Commentary` (Easton's).
  - IDs: `bookID` = short name + translation + order; `chapterID` = `bookID-n`; `verseID` = `chapterID.order`; `wordID`
    carries a 6-character hash of its verse.
- **Lexicon:** `Armat` (root) -`ARMAT`→ `Token` (word form).
- **KJV layer (Theographic):** `Verse` -`MENTIONS`→ `Person`, `Place`; -`DESCRIBES`→ `Event`; `OCCURRED_IN`, `BORN_IN`,
  `DIED_IN` → `Year`; Easton's entries.
- **The older model** (`surbgirq-db`, `--cypher`): `HAS_CH`, `HAS_SEC`, `HAS_VERSE`, `HAS_WORD`, `FIRST_WORD`, `NEXT`, `REF_TO`,
  `YOUTUBE_REF`.

## Adding a new book (the author's steps)

1. Add the translation to the translations YAML in `theodata/`.
2. Add the book to the books YAML.
3. Add a data constructor for it to `Girq` (`surbgirq-types`), with its abbreviations.
4. Scrape its HTML into YAML (`html-scraper`), then convert the YAML into CSV (`surbgirq-shell`).
5. Add it to the import script.
6. Import inside the Neo4j container: `docker exec -it neo bash`, then `bash all-import.sh` in the CSV folder.
