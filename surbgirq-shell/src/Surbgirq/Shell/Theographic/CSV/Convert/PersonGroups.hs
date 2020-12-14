{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}

module Surbgirq.Shell.Theographic.CSV.Convert.PersonGroups where

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

convertPersonGroups :: String -> FilePath -> FilePath -> IO ()
convertPersonGroups del dataFolder outFileRoot = do
   -- Books
   let booksFile = dataFolder </> "PersonGroups.csv"
   houtBooks <- openFile (outFileRoot </> "personGroups.csv") WriteMode
   houtRelation <- openFile (outFileRoot </> "Testament_BookRel.csv") WriteMode
   TIO.hPutStrLn houtBooks [qc|id:ID(KJV-BOOK-ID){del}bookOrder{del}osisref{del}shortName{del}slug{del}title{del}:LABEL|]
   TIO.hPutStrLn houtRelation [qc|:START_ID(TESTAMENT-ID){del}:END_ID(KJV-BOOK-ID){del}:TYPE|]
   readEntity booksFile >>= \ v ->
       V.forM_  v $ \ (BookCsv{..}) -> do
           let bookID = osisName
               bookRow = [qc|{bookID}{del}{bookOrder}{del}{osisName}{del}{shortName}{del}{slug}{del}{bookName}{del}Book|]
               relRow = [qc|{toTestamentId testament}{del}{bookID}{del}CONTAINS|]
           TIO.hPutStrLn houtBooks bookRow
           TIO.hPutStrLn houtRelation relRow

   hClose houtBooks
   hClose houtRelation

