{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}

module Surbgirq.Shell.Theographic.CSV.Convert.Periods where

import Data.List.Split
import System.FilePath
import System.IO

import Control.Monad                 (forM_, when)
import Text.InterpolatedString.Perl6 (qc)

import qualified Crypto.Hash          as Crypto
import qualified Crypto.MAC.HMAC      as Crypto
import qualified Data.Digest.Pure.SHA as SHA
import qualified Data.Text            as T
import qualified Data.Text.Encoding   as TSE
import qualified Data.Text.IO         as TIO
import qualified Data.Vector          as V

import Surbgirq.Shell.Theographic.CSV.Convert.Helpers
import Surbgirq.Shell.Theographic.CSV.Types


------------------------------------------------------------
--
------------------------------------------------------------

-- | Events
convertPeriods :: String -> FilePath -> FilePath -> IO ()
convertPeriods del dataFolder outFileRoot = do
   let periodFile = dataFolder </> "Periods.csv"
   houtPeriods <- openFile (outFileRoot </> "periods.csv") WriteMode
   houtEventYearRel <- openFile (outFileRoot </> "Event_YearRel.csv") WriteMode
   TIO.hPutStrLn houtPeriods
          [qc|id:ID(KJV-EVENT-ID){del}formattedYear{del}isoYear{del}year{del}:LABEL|]
   readEntity periodFile >>= \ v -> do
       V.forM_  v $ \ (period@PeriodCsv{..}) -> do
           let
               bs =  TSE.encodeUtf8 . T.pack  $ show period
               periodID =  show (Crypto.hash bs :: Crypto.Digest Crypto.SHA3_512)
               periodRow = [qc|{periodID}{del}{period'formattedYear}{del}{period'isoYear}{del}{period'isoYear}{del}Year|]
               es = splitOn "," $ strip period'events
               n = length $ filter (\x -> (length $ strip x) > 0) es
           when (n > 0) $ do
              forM_  es $ \ event -> do
                 let eventYearRel = [qc|{strip event}{del}{periodID}{del}OCCURRED_IN|]
                 TIO.hPutStrLn houtEventYearRel eventYearRel


           TIO.hPutStrLn houtPeriods periodRow

   hClose houtPeriods
   hClose houtEventYearRel
