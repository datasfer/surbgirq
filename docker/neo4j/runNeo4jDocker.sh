#!/usr/bin/env bash

docker run \
    --name testneo4j112 \
    -p7474:7474 -p7687:7687 \
    -d \
    -v $HOME/haskell/surbgirq/data:/data \
    -v $HOME/haskell/surbgirq/data/logs:/logs \
    -v $HOME/haskell/surbgirq/data/conf:/conf \
    -v $HOME/haskell/surbgirq/data/import:/var/lib/neo4j/import \
    -v $HOME/haskell/surbgirq/docker/neo4j/plugins4:/plugins \
    --env NEO4J_AUTH=neo4j/CHANGE_ME \
    neo4j:4.4.4
