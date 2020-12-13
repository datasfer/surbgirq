{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}

module Surbgirq.Shell.Theographic.CSV.Convert.Events where

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

-- | Events
-- convertEvents :: String -> FilePath -> FilePath -> IO ()
-- convertEvents del dataFolder outFileRoot = do
--    let eventsFile = dataFolder </> "Events.csv"
--    houtEvents <- openFile (outFileRoot </> "events.csv") WriteMode
--    TIO.hPutStrLn houtEvents
--           [qc|id:ID(KJV-EVENT-ID){del}title{del}precision{del}sequence{del}sortKey{del}startDate{del}:LABEL|]
--    readEntity eventsFile >>= \ v ->
--        V.forM_  v $ \ (EventCsv{..}) -> do
--            let placeID = place'placeID
--                info = place'featureType -- }-{place'featureSubType}
--                source = case place'recogitoUri of
--                             [] -> "http://www.openbible.info/geo/"
--                             _  -> place'recogitoUri
--                placeRow = [qc|{placeID}{del}{place'displayTitle}{del}{place'precision}{del}{info}{del}{place'comment}{del}{source}{del}{place'slug}{del}{place'displayTitle}{del}Place|]
--            TIO.hPutStrLn houtPlaces placeRow

--    hClose houtPlaces
