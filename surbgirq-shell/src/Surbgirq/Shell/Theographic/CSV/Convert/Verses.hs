{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}

module Surbgirq.Shell.Theographic.CSV.Convert.Verses where

import Control.Monad
import Data.List.Split
import System.FilePath
import System.IO

import Text.InterpolatedString.Perl6 (qc)

import qualified Data.Text.IO as TIO
import qualified Data.Vector  as V

import Surbgirq.Shell.Theographic.CSV.Convert.Helpers
import Surbgirq.Shell.Theographic.CSV.Types


------------------------------------------------------------
--
------------------------------------------------------------

-- | KJV text conversation from theographic data
convertVerses :: String -> FilePath -> FilePath -> IO ()
convertVerses del dataFolder outFileRoot = do
   -- Verses
   let versesFile = dataFolder </> "Verses.csv"
   houtVerses <- openFile (outFileRoot </> "verses.csv") WriteMode
   houtRelation <- openFile (outFileRoot </> "Chapter_VerseRel.csv") WriteMode
   houtVersePersonRel <- openFile (outFileRoot </> "Verse_PersonRel.csv") WriteMode
   houtVersePlaceRel <- openFile (outFileRoot </> "Verse_PlaceRel.csv") WriteMode
   houtVerseEventRel <- openFile (outFileRoot </> "Verse_EventRel.csv") WriteMode
   TIO.hPutStrLn houtVerses [qc|id:ID(KJV-VERSE-ID){del}verse:long{del}fullRef{del}osisRef{del}shortRef{del}mdText{del}verseText{del}title{del}:LABEL|]
   TIO.hPutStrLn houtRelation [qc|:START_ID(KJV-CHAPTER-ID){del}:END_ID(KJV-VERSE-ID){del}:TYPE|]
   TIO.hPutStrLn houtVersePersonRel [qc|:START_ID(KJV-VERSE-ID){del}:END_ID(KJV-PERSON-ID){del}:TYPE|]
   TIO.hPutStrLn houtVersePlaceRel [qc|:START_ID(KJV-VERSE-ID){del}:END_ID(KJV-PLACE-ID){del}:TYPE|]

   TIO.hPutStrLn houtVerseEventRel [qc|:START_ID(KJV-VERSE-ID){del}:END_ID(KJV-EVENT-ID){del}:TYPE|]

   readEntity versesFile >>= \ v ->
       V.forM_  v $ \ (VerseCsv{..}) -> do
           let verseID = verse'verseID
               shortRef = case splitOn "." verse'osisRef of
                            [book, ch, v] -> [qc|{book} {ch}:{v}|]
                            _             -> error verse'osisRef
               verseTitle = shortRef
               verseRow = [qc|{verseID}{del}{verse'verseNum}{del}{verse'osisRef}{del}{verse'osisRef}{del}{shortRef}{del}"{verse'mdText}"{del}"{verse'verseText}"{del}{verseTitle}{del}Verse|]
               relRow = [qc|{verse'chapter}{del}{verseID}{del}CONTAINS|]
           TIO.hPutStrLn houtVerses verseRow
           TIO.hPutStrLn houtRelation relRow

           when (length verse'eventsDescribed > 0 ) $ do
               let describeRel = [qc|{verseID}{del}{verse'eventsDescribed}{del}DESCRIBES|]
               TIO.hPutStrLn houtVerseEventRel describeRel

           when (verse'peopleCount > 0) $ do
              let ps = splitOn "," verse'people
              forM_  ps $ \ person -> do
                 let versePersonRel = [qc|{verseID}{del}{person}{del}MENTIONS|]
                 TIO.hPutStrLn houtVersePersonRel versePersonRel
           when (verse'placesCount > 0) $ do
              let ps = splitOn "," verse'places
              forM_  ps $ \ place -> do
                 let versePlaceRel = [qc|{verseID}{del}{place}{del}MENTIONS|]
                 TIO.hPutStrLn houtVersePlaceRel versePlaceRel
   hClose houtVerses
   hClose houtVersePersonRel
   hClose houtVersePlaceRel
   hClose houtVerseEventRel
   hClose houtRelation
