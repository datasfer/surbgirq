{-# LANGUAGE ApplicativeDo     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}

module Surbgirq.Shell.Commands where

import Data.Monoid         ((<>))
import Options.Applicative

import Common.Aeson
import Common.Yaml

someFunc :: IO ()
someFunc = putStrLn "someFunc"


data Command = Command
    { cmd'book    :: BookKind
    , cmd'config  :: FilePath
    , cmd'inPath  :: FilePath
    , cmd'outPath :: FilePath
    }


data BookKind = Bible
              | Narek


bibleInput :: Parser BookKind
bibleInput = flag' Bible
  (  long "bible"
  <> short 'b'
  <> help "Bible Scriptures processing" )

narekInput :: Parser BookKind
narekInput = flag' Narek
  (  long "narek"
  <> short 'n'
  <> help "Narek Scriptures processing" )

bookInput :: Parser BookKind
bookInput = bibleInput <|> narekInput

parser :: Parser Command
parser = do
  cmd'book <- bookInput
  cmd'config <- strOption
    (  metavar "PATH"
    <> long "config"
    <> short 'c'
    <> help "Config file, list of books and etc..x"
    <> value "data/yaml/config.yaml"
    <> showDefault
    )
  cmd'inPath <- strOption
    (  metavar "PATH"
    <> long "input"
    <> short 'i'
    <> help "Path to scripture folder"
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
