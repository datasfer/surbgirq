# Importing into Neo4j

The graph is always rebuilt from scratch: generate the CSVs ([data-pipeline.md](data-pipeline.md)), then bulk-load them with
`neo4j-admin database import full`. Nothing is migrated in place.

## Neo4j in Docker

`docker/docker-compose.yaml` starts one container, `neo`:

| | `master` | `fix-api` | `bump-9.6.7` |
|---|---|---|---|
| Image | `neo4j:5.15.0-enterprise` | `neo4j:5.18.1-enterprise` | `neo4j:5.26.6-enterprise` |
| Ports | 7474 (Browser), 7687 (Bolt) | the same | the same |
| Memory | heap up to 4 GB, page cache 2 GB | the same | the same |
| Volumes | `~/scriptures` (the CSVs) bound as the data, import and log folders; a `conf` folder (create it first); the scripts | the database in `~/neo4jDB`, the CSVs mounted separately (`/csv_data`); the scripts | separate folders for data, import, plugins and logs; `~/scriptures` at `/scriptures`; the scripts at `/import-scripts` |

Set your own password in `NEO4J_AUTH` (the files say `neo4j/CHANGE_ME`). The older files (`docker-compose_4.0.4.yml`,
`old_docker.yaml`, `neo4j/Dockerfile`, `neo4j/runNeo4jDocker.sh`) are for Neo4j 4.x and are kept for reference.

```bash
cd docker
docker compose up -d
docker exec -it neo bash          # then, inside the container: bash ~/scripts/all-import.sh
```

## The import

The scripts are in [`scripts/`](../scripts/README.md). The main one, `all-import.sh`, loads the 1994 translation, Zohrab
1805, the KJV with the Theographic layer, and both Narek texts into a database named `bibles`:

```bash
neo4j-admin database import full \
    --id-type STRING \
    --delimiter ";" \
    --array-delimiter "|" \
    --multiline-fields=true \
    --nodes=Scripture="$SCRIPTURES/scriptures.csv" \
    --nodes=…  --relationships=…   \
    bibles
```

Its last recorded run (Neo4j 5.15, 2024-01-13, with `--skip-bad-relationships=true` added): 916,443 nodes, 996,178
relationships and 6,912,174 properties in 1 min 29 s, with a peak of 1 GB of memory.

**After the import** on Enterprise, create the database once in the Browser: `:use system`, then `CREATE DATABASE bibles`.

**On 5.26** (the notes of `bump-9.6.7`): the database name goes first, `neo4j-admin database import full bibles …`, and the
running `neo4j` database must be stopped first (`STOP DATABASE neo4j`). To wait for the server after `docker compose up -d`:

```bash
until curl -s localhost:7474 > /dev/null; do echo "Waiting for Neo4j..."; sleep 2; done
```

## On a current Neo4j (2026.x): what will change

Researched in November 2026, **not tried yet**:

- **Community instead of Enterprise.** The compose files accept Enterprise's commercial licence
  (`NEO4J_ACCEPT_LICENSE_AGREEMENT=yes`). Community has one user database; its name can still be set with
  `initial.dbms.default_database=bibles`. Community can't stop a single database, so stop the server, run the import in a
  one-off container (`docker run --rm … neo4j-admin database import full …`), and start the server again.
- **`--vector-delimiter "|"` is required.** Its default is `;`, our column delimiter, and the importer refuses to start when
  the two are equal. It may be the same character as `--array-delimiter`, so the CSVs don't change.
- **Only one imported file has line breaks inside fields:** the KJV layer's `eastons.csv`. `--multiline-fields=true` slows the
  whole import, so restrict it to that file (`--multiline-fields-format=v2 --multiline-fields=…/eastons.csv`), or flatten
  those line breaks in the converter.
- **Useful options:** `--overwrite-destination` (rerun the same command every time), `--dry-run` (validate first), and a
  low `--bad-tolerance` once the bad relationships are fixed in the pipeline, so pipeline bugs fail loudly.
- **APOC isn't needed** for the import. An old APOC jar for Neo4j 3.5 used to be in `docker/neo4j/plugins/` and was removed.
