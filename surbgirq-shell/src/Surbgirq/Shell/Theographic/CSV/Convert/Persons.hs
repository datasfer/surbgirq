{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}

module Surbgirq.Shell.Theographic.CSV.Convert.Persons where

import Control.Monad
import Data.List.Split
import System.FilePath
import System.IO

import Text.InterpolatedString.Perl6 (qc)

import qualified Data.Text.IO as TIO
import qualified Data.Vector  as V

import Surbgirq.Shell.Files (openOutFile)
import Surbgirq.Shell.Theographic.CSV.Convert.Helpers
import Surbgirq.Shell.Theographic.CSV.Types


------------------------------------------------------------
--
------------------------------------------------------------

convertPersons :: String -> FilePath -> FilePath -> IO ()
convertPersons del dataFolder outFileRoot = do
   -- Persons
   let personsFile = dataFolder </> "Persons.csv"
   houtPersons <- openOutFile (outFileRoot </> "persons.csv")
--   houtRelation <- openFile (outFileRoot </> "Chapter_VerseRel.csv") WriteMode
   TIO.hPutStrLn houtPersons [qc|id:ID(KJV-PERSON-ID){del}name{del}gender{del}slug{del}status{del}title{del}:LABEL|]
--   TIO.hPutStrLn houtRelation [qc|:START_ID(KJV-CHAPTER-ID){del}:END_ID(KJV-VERSE-ID){del}:TYPE|]

   readEntity personsFile >>= \ v ->
       V.forM_  v $ \ (PersonCsv{..}) -> do
           let personID = person'personLookup
               -- shortRef = case splitOn "." verse'osisRef of
               --              [book, ch, v] -> [qc|{book} {ch}:{v}|]
               --              _             -> error verse'osisRef
               personRow = [qc|{personID}{del}{person'name}{del}{person'gender}{del}{person'slug}{del}{person'status}{del}{person'name}{del}Person|]
--               relRow = [qc|{verse'chapter}{del}{verseID}{del}CONTAINS|]
  --         TIO.hPutStrLn houtRelation relRow
           TIO.hPutStrLn houtPersons personRow
   hClose houtPersons
   -- Words
   -- let wordsFile = dataFolder </> "WordIndex.csv"
   -- readEntity wordsFile >>= \ v ->
   --     V.forM_  v $ \ (WordCsv{..}) -> print [qc|{word'BookID} {word'Word} |]
