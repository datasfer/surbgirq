{-# LANGUAGE ApplicativeDo     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}


import Options.Applicative
import System.FilePath
import System.IO

import Data.Monoid ((<>))

import qualified Data.Text.IO as TIO

import Surbgirq.Shell.Files       (useUtf8)
import Surbgirq.Shell.Theographic

-- | stack exec -- theographic --csv -i ./data/theodata/CSV -o ./data/csv"
main :: IO ()
main = do
  useUtf8

  cmd <- customExecParser (prefs showHelpOnError) $
         info (helper <*> parser) $
         fullDesc <> progDesc "Convert theograpic csv to output format formats."
                  <> header   "Theographic data converter."
                  <> footer   ("the generated csv/json will then converted to csv to feed neo4j."
                              <> "e.g. theographic  --csv --csv  -i ./data/theodata/CSV -o ./data"
                              )

  case cmd of
    Command{..} ->
       case cmd'inFormat of
         JSON -> do
                TIO.putStrLn "Not implented yet"

         CSV -> do
                TIO.putStrLn "Start converting theograpic csv to feed neo4j import..."
                convertKjvCsv cmd'inPath cmd'outPath
                TIO.putStrLn "Converting success!"


data Command = Command
    { cmd'inFormat :: InFormat
    , cmd'inPath   :: FilePath
    , cmd'outPath  :: FilePath
    }

data InFormat = JSON
              | CSV


-- | Parsing Input formats
jsonInput :: Parser InFormat
jsonInput = flag' JSON
  (  long "json"
  <> short 'j'
  <> help "JSON input" )

csvInput :: Parser InFormat
csvInput = flag' CSV
  (  long "csv"
  <> short 'c'
  <> help "CSV input" )




inFormat :: Parser InFormat
inFormat = jsonInput <|> csvInput

parser :: Parser Command
parser = do
  cmd'inFormat <- inFormat
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

