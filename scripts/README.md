# Import scripts

Bulk-import scripts for `neo4j-admin database import full` (Neo4j 5.15 and later). They run inside the Neo4j container and
read the CSVs made by the pipeline ([docs/data-pipeline.md](../docs/data-pipeline.md)); the container and the Neo4j versions
are in [docs/neo4j-import.md](../docs/neo4j-import.md).

| Script | Loads | Into the database |
|---|---|---|
| `all-import.sh` | the 1994 translation (`e1994-J`), Zohrab 1805 (`v1805`), the KJV with the Theographic layer, and Narek in both versions (Kheranyan's and the Classical Armenian original) | `bibles` |
| `kjv-import.sh` | the KJV with the Theographic layer | `kjv.graph` |
| `e1994-J-import.sh`, `e1994-import.sh` | the 1994 translation, from its two digitizations | `e1994.jupyter.graph.new`, `e1994.graph` |
| `v1805-import.sh`, `z1805-import.sh`, `ar94-import.sh` | one text each | a `….graph` database each |
| `narek-xer.sh` | Narek in Kheranyan's translation | `narek.xeranyan` |
| `narek-grabar.sh` | nothing yet (an empty file) | — |
| `neo4j_4/` | the same imports for Neo4j 4.x (`neo4j-admin import --database=…`: `bibleam`, `somebibleam`, `vizbible`); `load_scv.sh` loads CSVs with Cypher instead | — |
| `refactoring-idea-all-import.sh` (`bump-9.6.7` only) | a draft of a parameterized `all-import.sh` | — |

Neo4j 5 changed the command: `neo4j-admin import --database=<name>` (4.x) became `neo4j-admin database import full <name>`
(5.x). On 5.26 the database name goes first: `neo4j-admin database import full <name> --other-options…`
([docs/neo4j-import.md](../docs/neo4j-import.md)).

## The import runs of 2024-01-13 (Neo4j 5.15)

| Script | Result |
|---|---|
| `all-import.sh` | Worked with `--skip-bad-relationships=true`: 916,443 nodes, 996,178 relationships, 6,912,174 properties, in 1 min 29 s; peak memory 1.04 GiB |
| `kjv-import.sh` | Worked without that option: 43,878 nodes, 75,970 relationships, 306,474 properties, in 7 s |
| `e1994-J-import.sh` | First failed: relationships pointed at nodes of other books, because the shared `books.csv` listed every translation's books. Worked with `--skip-bad-relationships=true` (570,278 nodes, 584,443 relationships). **Fixed** by giving each translation its own books file: 570,251 nodes and 584,389 relationships, in 54 s |
| `e1994-import.sh` | Failed: its generated CSVs lack the `verseOrder` column that the header expects |
| `z1805-import.sh` | Failed: a word CSV has a non-number in the `versePos` column |
| `v1805-import.sh` | Failed like `e1994-J-import.sh` at first: chapter relationships pointed at another translation's nodes (the shared books file) |

The conclusion then: one books file per translation, as in the `e1994-J` fix.
