{-# LANGUAGE TemplateHaskell              #-}
{-# LANGUAGE OverloadedStrings              #-}
{-# LANGUAGE ApplicativeDo   #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TemplateHaskell #-}

module Surbgirq.Shell.Commands where

import Data.Monoid                      ((<>))
import Options.Applicative

import Common.Aeson
import Common.Yaml
    
someFunc :: IO ()
someFunc = putStrLn "someFunc"


data Command = Command
    { prmChapterFile   :: FilePath
    , prmScriptureFile :: FilePath
    , prmConfigPath    :: FilePath
    }


parser :: Parser Command
parser = do
  prmChapterFile <- strOption
    (  long "path-to-chapter"
    <> help "Path to chapter file"
    <> value "data/yaml/matthew/01.yaml"
    <> showDefault
    )
  prmScriptureFile <- strOption
    (  long "path-to-scripture"
    <> help "Path to scripture file"
    <> value "data/yaml/matthew/01.yaml"
    <> showDefault
    )
  prmConfigPath <- strOption
    (  metavar "PATH"
    <> help "Path to configuration"
    <> value ""
    )
  return Command{..}
