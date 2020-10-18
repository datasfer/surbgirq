{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE QuasiQuotes         #-}
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE ApplicativeDo     #-}

module Main where


import Control.Exception    (bracket)
import Control.Monad.Except (MonadError, MonadIO, catchError, liftIO)
import Data.Monoid         ((<>))

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
import Surbgirq.Shell.Store.Neo4j
import Surbgirq.Shell.Types
import Surbgirq.Types.Girq
import Surbgirq.Shell.Scraper
-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------

-- |  stack exec -- grabar1805-scraper  --yaml  -i ./data/html/v1805 -o ./data/yaml
main :: IO ()
main = do
  cmd <- customExecParser (prefs showHelpOnError) $
         info (helper <*> parser) $
         fullDesc <> progDesc "Scrap html to yamlor json formats."
                  <> header   "Surbgirq text scraper from html."
                  <> footer   ("the generated yaml/json will then converted to csv to feed neo4j."
                              <> "e.g. grabar1805-scraper  --yaml  -i ./data/html/v1805 -o ./data/yaml"
                              )

  case cmd of
    Command{..} -> 
                 case cmd'outFormat of
                   YAML -> do
                          TIO.putStrLn "Start scrapping Bible scriptures from html to Yaml..."
                          parseGrabarBibleHtml cmd'inPath cmd'outPath
                          TIO.putStrLn "Scrapping success!"
                   JSON -> do
                          TIO.putStrLn "Start scrapping Bible scriptures from html to Json..."
                          parseGrabarBibleHtml cmd'inPath cmd'outPath
                          TIO.putStrLn "Scrapping success!"
                   CSV -> do
                          TIO.putStrLn "Start scrapping Bible scriptures from html to Csv..."
                          parseGrabarBibleHtml cmd'inPath cmd'outPath
                          TIO.putStrLn "Scrapping success!"


-- Cmd line commands parsing                                  
data Command = Command
    { cmd'outFormat :: OutFormat
    , cmd'inPath    :: FilePath
    , cmd'outPath   :: FilePath
    }

data OutFormat =  YAML
                | JSON
                | CSV



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
  <> short 'v'
  <> help "CSV output" )

outFormat :: Parser OutFormat
outFormat = yamlOut <|> jsonOut <|> csvOut

parser :: Parser Command
parser = do
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
