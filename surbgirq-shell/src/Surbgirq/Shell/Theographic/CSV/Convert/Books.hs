{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}

module Surbgirq.Shell.Theographic.CSV.Convert.Books where

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

convertBooks :: String -> FilePath -> FilePath -> IO ()
convertBooks del dataFolder outFileRoot = do
   -- Books
   let booksFile = dataFolder </> "Books.csv"
   houtBooks <- openFile (outFileRoot </> "books.csv") WriteMode
   houtRelation <- openFile (outFileRoot </> "Testament_BookRel.csv") WriteMode
   houtTransRel <- openFile (outFileRoot </> "Translation_KJVRel.csv") WriteMode
   TIO.hPutStrLn houtBooks [qc|id:ID(KJV-BOOK-ID){del}book{del}bookOrder{del}osisref{del}shortName{del}slug{del}title{del}testament{del}:LABEL|]
   TIO.hPutStrLn houtRelation [qc|:START_ID(TESTAMENT-ID){del}:END_ID(KJV-BOOK-ID){del}:TYPE|]
   TIO.hPutStrLn houtTransRel [qc|:START_ID(TRANSLATION-ID){del}:END_ID(KJV-BOOK-ID){del}:TYPE|]
   readEntity booksFile >>= \ v ->
       V.forM_  v $ \ (BookCsv{..}) -> do
           let bookID = osisName
               testamentID = toTestamentId testament
               bookRow = [qc|{bookID}{del}{bookName}{del}{bookOrder}{del}{osisName}{del}{shortName}{del}{slug}{del}{bookName}{del}{testamentID}{del}Book|]

           TIO.hPutStrLn houtBooks bookRow
           TIO.hPutStrLn houtRelation [qc|{testamentID}{del}{bookID}{del}CONTAINS|]
           TIO.hPutStrLn houtTransRel [qc|kjv-T{del}{bookID}{del}CONTAINS|]

   hClose houtBooks
   hClose houtRelation
   hClose houtTransRel

