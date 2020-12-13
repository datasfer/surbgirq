{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}

module Surbgirq.Shell.Theographic.CSV.Convert.Places where

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

-- | Places
convertPlaces :: String -> FilePath -> FilePath -> IO ()
convertPlaces del dataFolder outFileRoot = do
   let placesFile = dataFolder </> "Places.csv"
   houtPlaces <- openFile (outFileRoot </> "places.csv") WriteMode
   TIO.hPutStrLn houtPlaces
          [qc|id:ID(KJV-PLACE-ID){del}name{del}precision{del}type{del}comment{del}source{del}slug{del}title{del}:LABEL|]
   readEntity placesFile >>= \ v ->
       V.forM_  v $ \ (PlaceCsv{..}) -> do
           let placeID = place'placeLookup
               info = [qc|{place'featureType} {place'featureSubType}|]
               source = case strip place'recogitoUri of
                            [] -> "http://www.openbible.info/geo/"
                            _  -> strip place'recogitoUri
               placeRow = [qc|{placeID}{del}{place'displayTitle}{del}{place'precision}{del}{strip info}{del}"{strip place'comment}"{del}"{source}"{del}{place'slug}{del}{place'displayTitle}{del}Place|]
           TIO.hPutStrLn houtPlaces placeRow

   hClose houtPlaces
