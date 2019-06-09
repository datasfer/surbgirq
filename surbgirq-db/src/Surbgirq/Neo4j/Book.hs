{-# LANGUAGE OverloadedStrings   #-}


module Surbgirq.Neo4j.Book where

import Database.Bolt 



getBooks :: BoltActionT IO [Record]
getBooks = do
        resp <- query "MATCH (book:Book) RETURN book;"
        return resp



