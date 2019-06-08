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
$ docker run -v ~/haskell/surbgirq/data:/data  -d -p 7474:7474 -p 7687:7687 neo4j-surbgirq
```

This will setup web-interface at http://localhost:7474 and Bolt server at localhost:7687.

Username: `neo4j`

Password: CHANGE_ME


Cypher-shell
cypher-shell -u neo4j -p CHANGE_ME

cat sample.cypher | cypher-shell -u neo4j -p CHANGE_ME


### Connect to docker terminal and run cypher-shell
    docker exec -i -t 665b4a1e17b6

### Share folder with docker container    
    -v ~/haskell/surbgirq/data:/data 