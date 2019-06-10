{-# LANGUAGE OverloadedStrings #-}


module Surbgirq.Neo4j.Book where

import Database.Bolt
import Surbgirq.Neo4j.Types


getBooks :: BoltActionT IO [Record]
getBooks = do
        resp <- query "MATCH (book:Book) RETURN book;"
        return resp


getBookNodes :: BoltActionT IO [BookNode]
getBookNodes = do
        rs <- query "MATCH (book:Book) RETURN book;"
        nodes <- traverse (`at` "book") rs
        bs <- traverse exact nodes
        return bs



