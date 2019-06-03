# Dockerfile with Neo4j

This directory contains `Dockerfile` with Neo4j set up  password is set.

## Build

To build the image run

```console
$ docker build . -t neo4j-surbgirq
```

## Run

To run the resulting instance do

```console
$ docker run -d -p 7474:7474 -p 7687:7687 neo4j-surbgirq
```

This will setup web-interface at http://localhost:7474 and Bolt server at localhost:7687.

Username: `neo4j`

Password: CHANGE_ME
