obsolate, see /notes.org

# Dockerfile with Neo4j

This directory contains `Dockerfile` with Neo4j set up  password is set.

## Build

To build the image run

```console
$ docker build . -t neo4j-surbgirq
```

## Run

To run the resulting instance do

``` install apoc plugin
https://github.com/neo4j-contrib/neo4j-apoc-procedures

mkdir plugins
wget https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases/download/3.5.0.3/apoc-3.5.0.3-all.jar

# to check run in neo4j cmd line
> call apoc.help("apoc")

> RETURN apoc.version();

```



```console
$ docker run -v ~/haskell/surbgirq/data:/data  -v ~/haskell/surbgirq/docker/neo4j/plugins:/plugins  -d -p 7474:7474 -p 7687:7687 neo4j-surbgirq


$ docker run -v ~/haskell/surbgirq/data:/data -v ~/haskell/surbgirq/data:/config  -v ~/haskell/surbgirq/docker/neo4j/plugins:/plugins  -d -p 7474:7474 -p 7687:7687 neo4j-surbgirq

$ docker run -v ~/haskell/surbgirq/data:/data -v ~/haskell/surbgirq/data:/config  -v ~/haskell/surbgirq/docker/neo4j/plugins1:/plugins  -d -p 7474:7474 -p 7687:7687 neo4j:4.0.4

docker run  --env=NEO4J_ACCEPT_LICENSE_AGREEMENT=yes \
            --env NEO4J_AUTH=neo4j/CHANGE_ME \
            --publish=7474:7474  --publish=7687:7687 \
            --volume=$HOME/haskell/surbgirq/data:/data \
            --user="$(id -u):$(id -g)" \
            neo4j-4-enterprise:latest 

```

This will setup web-interface at http://localhost:7474 and Bolt server at localhost:7687.

Username: `neo4j`

Password: CHANGE_ME


Cypher-shell
cypher-shell -u neo4j -p CHANGE_ME

cat sample.cypher | cypher-shell -u neo4j -p CHANGE_ME


### Connect to docker terminal and run cypher-shell
    docker exec -i -t 665b4a1e17b6 /bin/bash

### Share folder with docker container    
    -v ~/haskell/surbgirq/data:/data

docker run  --env=NEO4J_ACCEPT_LICENSE_AGREEMENT=yes \
             --env NEO4J_AUTH=neo4j/CHANGE_ME \
             --publish=7474:7474  --publish=7687:7687 \
             --volume=$HOME/haskell/surbgirq/data:/data \
             --user="$(id -u):$(id -g)" \
	    --env NEO4J_dbms_connector_https_advertised__address="0.0.0.0:7473" \
	    --env NEO4J_dbms_connector_http_advertised__address="0.0.0.0:7474" \
	    --env NEO4J_dbms_connector_bolt_advertised__address="192.0.2.10:7687" \
	    neo4j:4.0.4-enterprise



