{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}

module Surbgirq.Shell.Theographic.CSV.Convert.Chapters where

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

convertChapters :: String -> FilePath -> FilePath -> IO ()
convertChapters del dataFolder outFileRoot = do
   -- Chapters
   let chaptersFile = dataFolder </> "Chapters.csv"
   houtChapters <- openOutFile (outFileRoot </> "chapters.csv")
   houtRelation <- openOutFile (outFileRoot </> "Book_ChapterRel.csv")
   houtPersonChapterRel <- openOutFile (outFileRoot </> "Person_ChapterRel.csv")
   TIO.hPutStrLn houtChapters [qc|id:ID(KJV-CHAPTER-ID){del}book{del}num:long{del}osisref{del}slug{del}title{del}:LABEL|]
   TIO.hPutStrLn houtRelation [qc|:START_ID(KJV-BOOK-ID){del}:END_ID(KJV-CHAPTER-ID){del}:TYPE|]
   TIO.hPutStrLn houtPersonChapterRel [qc|:START_ID(KJV-CHAPTER-ID){del}:END_ID(KJV-PERSON-ID){del}:TYPE|]

   readEntity chaptersFile >>= \ v ->
       V.forM_  v $ \ (ChapterCsv{..}) -> do
           let chapterID = [qc|{chapter'osisRef}|]
               chapterTitle = [qc|{chapter'book} {chapter'chapterNum}|]
               chapterRow = [qc|{chapterID}{del}{chapter'book}{del}{chapter'chapterNum}{del}{chapter'osisRef}{del}{chapter'slug}{del}{chapterTitle}{del}Chapter|]
               personChRel = [qc|{chapterID}{del}{chapter'writer}{del}WROTE|]
               relRow = [qc|{chapter'book}{del}{chapterID}{del}CONTAINS|]
           TIO.hPutStrLn houtChapters chapterRow
           TIO.hPutStrLn houtRelation relRow

   hClose houtChapters
   hClose houtRelation


