{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}

module Surbgirq.Shell.Theographic.CSV.Convert.Eastons where

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


convertEastons :: String -> FilePath -> FilePath -> IO ()
convertEastons del dataFolder outFileRoot = do
   -- Books
   let booksFile = dataFolder </> "Easton.csv"
   houtEastons <- openFile (outFileRoot </> "eastons.csv") WriteMode
   houtRelation <- openFile (outFileRoot </> "Commentary_EastonRel.csv") WriteMode
   TIO.hPutStrLn houtEastons [qc|id:ID(KJV-EASTONS-ID){del}term{del}dictText{del}:LABEL|]
   TIO.hPutStrLn houtRelation [qc|:START_ID(COMMENTARY-ID){del}:END_ID(KJV-EASTONS-ID){del}:TYPE|]
   readEntity booksFile >>= \ v ->
       V.forM_  v $ \ (EastonCsv{..}) -> do
           let eastonID = [qc|{easton'termID} {easton'index}|]
               eastonRow = [qc|{eastonID}{del}{easton'termLabel}{del}"{easton'dictText}"{del}Easton's|]
               relRow = [qc|eastons{del}{eastonID}{del}CONTAINS|]
           TIO.hPutStrLn houtEastons eastonRow
           TIO.hPutStrLn houtRelation relRow

   hClose houtEastons
   hClose houtRelation

