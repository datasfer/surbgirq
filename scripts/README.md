# Import scripts

Bulk-import scripts for `neo4j-admin database import full` (Neo4j 5.15 and later). They run inside the Neo4j container and
read the CSVs made by the pipeline ([docs/data-pipeline.md](../docs/data-pipeline.md)); the container and the Neo4j versions
are in [docs/neo4j-import.md](../docs/neo4j-import.md).

| Script | Loads | Into the database |
|---|---|---|
| `all-import.sh` | the 1994 translation (`e1994-J`), Zohrab 1805 (`v1805`), the KJV with the Theographic layer, and Narek in both versions (Kheranyan's and the Classical Armenian original) | `bibles` |
| `kjv-import.sh` | the KJV with the Theographic layer | `kjv.graph` |
| `e1994-J-import.sh`, `e1994-import.sh` | the 1994 translation, from its two digitizations: `e1994-J` is made from the qahana.am pages (the copy `all-import.sh` loads); `e1994` is a USFM text, and its CSVs are stale | `e1994.jupyter.graph.new`, `e1994.graph` |
| `v1805-import.sh`, `z1805-import.sh`, `ar94-import.sh` | one text each | a `….graph` database each |
| `narek-xer.sh` | Narek in Kheranyan's translation | `narek.xeranyan` |
| `narek-grabar.sh` | nothing yet (an empty file) | — |
| `neo4j_4/` | the same imports for Neo4j 4.x (`neo4j-admin import --database=…`: `bibleam`, `somebibleam`, `vizbible`); `load_scv.sh` loads CSVs with Cypher instead | — |
| `refactoring-idea-all-import.sh` | a draft of a parameterized `all-import.sh` | — |

Neo4j 5 changed the command: `neo4j-admin import --database=<name>` (4.x) became `neo4j-admin database import full <name>`
(5.x). On 5.26 the database name goes first: `neo4j-admin database import full <name> --other-options…`
([docs/neo4j-import.md](../docs/neo4j-import.md)).

## Check before importing

`check-import.py` reads an import script and the CSVs it names the way `neo4j-admin` does, without Neo4j, and says
whether the import would complete, and with how many nodes, relationships and properties. The Neo4j image has no Python,
so run it on the host, on the folder the import reads (`~/scriptures/csv` is `/scriptures/csv` in the container), before
`docker exec`:

```bash
python3 scripts/check-import.py --csv-root ~/scriptures/csv scripts/all-import.sh
```

- **It simulates what decides the outcome:**
  - the file patterns;
  - the CSV parsing: quotes, the delimiter, line breaks inside quoted fields, extra columns, numbers in `:long` columns;
  - the node IDs in their ID spaces, and the link from every relationship to its two nodes;
  - the options that tolerate problems: `--skip-bad-relationships`, `--skip-duplicate-nodes`, `--ignore-extra-columns`,
    `--bad-tolerance`.

  It writes nothing, and it can't see memory, disk or the database itself.
- **It prints:**
  - the counts to expect, per label and per relationship type: compare them with `neo4j-admin`'s closing `Imported:`
    lines;
  - every problem that would stop the import;
  - the relationships that point at missing nodes, per file;
  - the files that need `--multiline-fields`;
  - warnings, such as CRs inside quoted fields (CSVs copied from a Windows checkout).

  It never prints the text of a field.
- **Exit status:** 0 if the import would complete, 1 if it would fail, 2 if the script can't be checked. The check
  follows variables and the `neo4j-admin` command, not shell logic. So it chains:
  `python3 scripts/check-import.py … && docker exec …`.
- **Options:**
  - `--neo4j VERSION` (default 5.26, the compose file's) applies that version's rules: `--bad-tolerance` is unlimited
    from 2025.12, and from 2026.06 `--vector-delimiter` must differ from `--delimiter`;
  - `--map PREFIX=DIR` reads absolute container paths, such as `neo4j_4/`'s `/var/lib/neo4j/data/csv`, from a host
    folder;
  - `--verbose` adds one line per `--nodes` and `--relationships` group.
- **Its tests:** `python3 -m unittest discover -s scripts/tests`.

**Today's results,** on the CSVs of the 2024 runs below (the private `scriptures` repo at `2304d44`):

| Script | Nodes | Relationships | Properties | Verdict |
|---|---|---|---|---|
| `all-import.sh` | 916,443 | 996,178 | 6,912,174 | completes. Every relationship resolves, so it needs no `--skip-bad-relationships` |
| `kjv-import.sh` | 43,878 | 75,970 | 306,474 | completes |
| `e1994-J-import.sh` | 570,251 | 584,389 | 4,250,893 | completes. It skips 548 relationships from the shared `BookChapterRel.csv` and `scriptureRel.csv` to other translations |
| `v1805-import.sh`, `narek-xer.sh` | | | | fail on 1,479 and 1,691 relationships from the shared `BookChapterRel.csv` to other translations' chapters, with no `--skip-bad-relationships` |
| `e1994-import.sh`, `z1805-import.sh` | | | | fail on their stale CSVs: text in `verseOrder:long` (34,308 rows), and an extra column in 104,011 word rows |
| `ar94-import.sh` | | | | can't start: `scriptures/bible/am/ar94` doesn't exist |
| `narek-grabar.sh`, `refactoring-idea-all-import.sh` | | | | can't be checked: an empty file, and a draft with shell logic |

On Neo4j 2026.x (`--neo4j 2026.10`), every script also needs `--vector-delimiter "|"`.

## The import runs of 2024-01-13 (Neo4j 5.15)

| Script | Result |
|---|---|
| `all-import.sh` | Worked with `--skip-bad-relationships=true`, added by hand: 916,443 nodes, 996,178 relationships, 6,912,174 properties, in 1 min 29 s; peak memory 1.04 GiB. The option wasn't needed: the check finds no relationship to skip |
| `kjv-import.sh` | Worked without that option: 43,878 nodes, 75,970 relationships, 306,474 properties, in 7 s |
| `e1994-J-import.sh` | First failed: relationships pointed at nodes of other books, because the shared `books.csv` listed every translation's books. Worked with `--skip-bad-relationships=true` (570,278 nodes, 584,443 relationships). **Fixed** by giving each translation its own books file: 570,251 nodes and 584,389 relationships, in 54 s |
| `e1994-import.sh` | Failed: its generated CSVs lack the `verseOrder` column that the header expects |
| `z1805-import.sh` | Failed: a word CSV has a non-number in the `versePos` column |
| `v1805-import.sh` | Failed like `e1994-J-import.sh` at first: chapter relationships pointed at another translation's nodes (the shared books file) |

The conclusion then: one books file per translation, as in the `e1994-J` fix.
