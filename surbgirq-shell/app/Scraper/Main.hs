{-# LANGUAGE ApplicativeDo       #-}
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE QuasiQuotes         #-}
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main where


import Control.Exception    (bracket)
import Control.Monad.Except (MonadError, MonadIO, catchError, liftIO)
import Data.Monoid          ((<>))

import Options.Applicative

import Common.Aeson
import Common.Yaml

import Data.Aeson
import Data.Char
import Data.Maybe (fromMaybe)
import Data.Text  (Text, pack)

import qualified Data.Text               as T
import qualified Data.Text.Encoding      as TE
import qualified Data.Text.IO            as TIO
import qualified Data.Text.Lazy          as TL
import qualified Data.Text.Lazy.Builder  as TB
import           Data.Text.Lazy.Encoding as TLE


import System.Directory
import System.FilePath.Posix         (takeBaseName, takeDirectory)
import System.IO
import Text.InterpolatedString.Perl6 (qc)

import Control.Monad
import Data.List
import System.FilePath

import Common.Yaml
import Surbgirq.Shell.CSV.Generate
import Surbgirq.Shell.Scraper
import Surbgirq.Shell.Store.Neo4j
import Surbgirq.Shell.Types
import Surbgirq.Types.Girq
-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------

-- | stack exec -- html-scraper --v1805  --yaml  -i ./data/html/v1805 -o ./data/yaml
main :: IO ()
main = do
  cmd <- customExecParser (prefs showHelpOnError) $
         info (helper <*> parser) $
         fullDesc <> progDesc "Scrap html to yamlor json formats."
                  <> header   "Surbgirq text scraper from html."
                  <> footer   ("the generated yaml/json will then converted to csv to feed neo4j."
                              <> "e.g. html-scraper --v1805  --yaml  -i ./data/html/v1805 -o ./data/yaml"
                              )

  case cmd of
    Command{..} ->
             case cmd'book of
               Z1805 ->
                 case cmd'outFormat of
                   YAML -> do
                          TIO.putStrLn "Start scrapping Grabar scriptures to Yaml..."
                          parseZohrapHtml cmd'inPath cmd'outPath
                          TIO.putStrLn "Scrapping success!"
                   _ -> TIO.putStrLn "format not supported"
               V1805 ->
                 case cmd'outFormat of
                   YAML -> do
                          TIO.putStrLn "Start scrapping Grabar scriptures to Yaml..."
                          parseGrabarBibleHtml cmd'inPath cmd'outPath
                          TIO.putStrLn "Scrapping success!"
                   JSON -> do
                          TIO.putStrLn "Start scrapping Grabar scriptures to Json..."
                          parseGrabarBibleHtml cmd'inPath cmd'outPath
                          TIO.putStrLn "Scrapping success!"
                   CSV -> do
                          TIO.putStrLn "Start scrapping Grabar scriptures to Csv..."
                          parseGrabarBibleHtml cmd'inPath cmd'outPath
                          TIO.putStrLn "Scrapping success!"
               E1994 ->
                 case cmd'outFormat of
                   YAML -> do
                          TIO.putStrLn "Start scrapping e 1994 scriptures to Yaml..."
                          parseE1994BibleHtml cmd'inPath cmd'outPath
                          TIO.putStrLn "Scrapping success!"
                   JSON -> do
                          TIO.putStrLn "Start scrapping e 1994 scriptures to Json..."
                          parseE1994BibleHtml cmd'inPath cmd'outPath
                          TIO.putStrLn "Scrapping success!"
                   CSV -> do
                          TIO.putStrLn "Start scrapping e 1994 scriptures to Csv..."
                          parseE1994BibleHtml cmd'inPath cmd'outPath
                          TIO.putStrLn "Scrapping success!"
               AR94 ->
                 case cmd'outFormat of
                   YAML -> do
                          TIO.putStrLn "Start scrapping Grabar scriptures to Yaml..."
                          parseAR94Html cmd'inPath cmd'outPath
                          TIO.putStrLn "Scrapping success!"
                   _ -> TIO.putStrLn "format not supported"




-- Cmd line commands parsing
data BookTranslation = V1805
                     | E1994
                     | AR94
                     | Z1805
data Command = Command
    { cmd'book      :: BookTranslation
    , cmd'outFormat :: OutFormat
    , cmd'inPath    :: FilePath
    , cmd'outPath   :: FilePath
    }

data OutFormat =  YAML
                | JSON
                | CSV

-- | Parsing Book translations
v1805Input :: Parser BookTranslation
v1805Input = flag' V1805
  (  long "v1805"
  <> short 'v'
  <> help "grabar 1805 translation" )

-- | Parsing Book translations

z1805Input :: Parser BookTranslation
z1805Input = flag' V1805
  (  long "z1805"
  <> short 'z'
  <> help "grabar 1805 translation, another parsing" )

e1994Input :: Parser BookTranslation
e1994Input = flag' E1994
  (  long "e1994"
  <> short 'e'
  <> help "ashxarhabar 1994 translation" )

ar94Input :: Parser BookTranslation
ar94Input = flag' AR94
  (  long "ar94"
  <> short 'r'
  <> help "ashxarhabar 1994 translation jupiter processed" )

-- | Parsing formats
yamlOut :: Parser OutFormat
yamlOut = flag' YAML
  (  long "yaml"
  <> short 'y'
  <> help "Yaml output" )

jsonOut :: Parser OutFormat
jsonOut = flag' JSON
  (  long "json"
  <> short 'j'
  <> help "JSON output" )

csvOut :: Parser OutFormat
csvOut = flag' CSV
  (  long "csv"
  <> short 'c'
  <> help "CSV output" )



outFormat :: Parser OutFormat
outFormat = yamlOut <|> jsonOut <|> csvOut

bookInput :: Parser BookTranslation
bookInput = v1805Input <|> e1994Input <|> z1805Input <|> ar94Input

parser :: Parser Command
parser = do
  cmd'book <- bookInput
  cmd'outFormat <- outFormat
  cmd'inPath <- strOption
    (  metavar "PATH"
    <> long "input"
    <> short 'i'
    <> help "Path to html folder"
    <> value "data/yaml"
    <> showDefault
    )
  cmd'outPath <- strOption
    (  metavar "PATH"
    <> long "output"
    <> short 'o'
    <> help "Path to store results"
    <> value ""
    )
  return Command{..}



-- | options generic
-- import Options.Generic

-- data Command w = Command
--     { format :: OutFormat <?> "output format yaml/json/csv"
--     , inPath    :: FilePath <?> "html texts directory"
--     , outPath   :: FilePath <?> "output directory"
--     }
--      deriving (Generic)

-- instance ParseRecord (Command Wrapped) where
--         parseRecord = parseRecordWithModifiers modifiers

-- deriving instance Show (Command Unwrapped)

-- data OutFormat =  YAML
--                 | JSON
--                 | CSV
--      deriving (Generic, Read)

-- modifiers :: Modifiers
-- modifiers = defaultModifiers
--     { shortNameModifier = firstLetter
--     }



-- instance ParseFields OutFormat
-- instance ParseField OutFormat
-- instance ParseRecord OutFormat
-- deriving instance Show OutFormat

-- main = do
--     x <- unwrapRecord "Test program"
--     print (x :: Command Unwrapped)
