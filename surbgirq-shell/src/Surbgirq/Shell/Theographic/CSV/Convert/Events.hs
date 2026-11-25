{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}

module Surbgirq.Shell.Theographic.CSV.Convert.Events where

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

-- | Events
convertEvents :: String -> FilePath -> FilePath -> IO ()
convertEvents del dataFolder outFileRoot = do
   let eventsFile = dataFolder </> "Events.csv"
   houtEvents <- openOutFile (outFileRoot </> "events.csv")
   TIO.hPutStrLn houtEvents
          [qc|id:ID(KJV-EVENT-ID){del}title{del}duration{del}sortKey{del}startDate{del}:LABEL|]
   readEntity eventsFile >>= \ v -> do
       V.forM_  v $ \ (EventCsv{..}) -> do
           let eventID = event'title
               eventRow = [qc|{eventID}{del}{event'title}{del}{event'duration}{del}{event'sortKey}{del}{event'startDate}{del}Event|]
           TIO.hPutStrLn houtEvents eventRow

   hClose houtEvents
