{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE QuasiQuotes         #-}
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}

module Surbgirq.Shell.Theographic.CSV.Converter
    ( module Surbgirq.Shell.Theographic.CSV.Converter
    , module X)
        where



import Surbgirq.Shell.Theographic.CSV.Convert.Books        as X
import Surbgirq.Shell.Theographic.CSV.Convert.Chapters     as X
import Surbgirq.Shell.Theographic.CSV.Convert.Eastons      as X
import Surbgirq.Shell.Theographic.CSV.Convert.Events       as X
import Surbgirq.Shell.Theographic.CSV.Convert.Periods      as X
import Surbgirq.Shell.Theographic.CSV.Convert.PersonGroups as X
import Surbgirq.Shell.Theographic.CSV.Convert.Persons      as X
import Surbgirq.Shell.Theographic.CSV.Convert.Places       as X
import Surbgirq.Shell.Theographic.CSV.Convert.Verses       as X

-- base
import           Control.Exception (IOException)
import qualified Control.Exception as Exception
import qualified Data.Foldable     as Foldable

import Data.List.Split
-- bytestring
import           Data.ByteString.Lazy (ByteString)
import qualified Data.ByteString.Lazy as ByteString

-- cassava
import           Data.Csv
    ( DefaultOrdered(headerOrder)
    , FromField(parseField)
    , FromNamedRecord(parseNamedRecord)
    , HasHeader(..)
    , Header
    , ToField(toField)
    , ToNamedRecord(toNamedRecord)
    , (.:)
    , (.=)
    )
import qualified Data.Csv as Cassava

-- text
import Data.Text                     (Text)
import Text.InterpolatedString.Perl6 (qc)

import qualified Data.ByteString.Lazy as BL
import qualified Data.Text.IO         as TIO
import qualified Data.Vector          as V


import Control.Monad
import System.Directory
import System.FilePath
import System.IO

import Surbgirq.Shell.Theographic.CSV.Types

del :: String
del  = ";"

arrayDel :: String
arrayDel = "|"

-- | inPath: "./data/theodata/CSV"  outPath: ./data/csv
--  convertKjvCsv "./data/theodata/CSV" "./data/csv"
convertKjvCsv :: FilePath -> FilePath -> IO ()
convertKjvCsv inPath outPath = do
   let outRootPath = outPath </> "scriptures"
       outFileRoot = outRootPath </>  "./bible/en/kjv"
       dataFolder = inPath

   createDirectoryIfMissing True outRootPath

   exists <- doesDirectoryExist dataFolder
     -- check if books input directory exists
   when exists $ do
       createDirectoryIfMissing True outFileRoot


   convertPeriods del dataFolder outFileRoot
   convertPlaces del dataFolder outFileRoot
   convertBooks del dataFolder outFileRoot
   convertEvents del dataFolder outFileRoot
   convertChapters del dataFolder outFileRoot
   convertVerses del dataFolder outFileRoot
   convertPersons del dataFolder outFileRoot
   convertEastons del dataFolder outFileRoot







demoP :: IO ()
demoP = do
    csvData <- BL.readFile "./data/theodata/CSV/Persons.csv"
    case Cassava.decodeByName csvData of
        Left err -> putStrLn err
        Right  (_, v) -> V.forM_  v $ \ (PersonCsv{..}) -> do
                    print [qc|{person'mother} -- {person'father} = {person'personLookup}|]


demoW :: IO ()
demoW = do
    csvData <- BL.readFile "./data/theodata/CSV/WordIndex.csv"
    case Cassava.decodeByName csvData of
        Left err -> putStrLn err
        Right  (_, v) -> V.forM_  v $ \ (WordCsv{..}) -> do
                    print [qc|{word'WordID} {word'Word}|]

demoV :: IO ()
demoV = do
    csvData <- BL.readFile "./data/theodata/CSV/Verses.csv"
    case Cassava.decodeByName csvData of
        Left err -> putStrLn err
        Right  (_, v) -> V.forM_  v $ \ (VerseCsv{..}) -> do
                    print [qc|{verse'osisRef} {verse'book}|]


demo1 :: IO ()
demo1 = do
    csvData <- BL.readFile "./data/theodata/CSV/Books.csv"
    case Cassava.decode HasHeader  csvData of
        Left err -> putStrLn err
        -- Right v -> print $ (V.toList v :: [String])
        Right  v -> do
          print "============================Start====================="
          V.forM_ v $ \a -> do
                    let xs = V.toList a :: [Text] -- (osisName,bookOrder) ->
                    print xs


