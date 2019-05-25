{-# LANGUAGE ApplicativeDo   #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TemplateHaskell #-}
module Settings where

import           Options.Applicative

import           Data.Aeson          (FromJSON)
import           Data.Monoid         ((<>))

import           Common.Aeson
import           Common.Yaml
import           Types

-------------------------------------------------------------------------------
--

data CmdOptions = CmdOptions
               { cmdConfigPath :: FilePath
               , cmdExtraLog   :: Maybe FilePath
               }

getSettings :: (FromJSON a)
            => String                   -- ^ Application header
            -> (a -> [ScribeSpec] -> a) -- ^ Extra logs adder
            -> IO a                     -- ^ Reading resulg
getSettings cmdHeader cmdExtraLogAdder = do
  cmd <- customExecParser (prefs showHelpOnError)
            $ info (helper <*> parser)
              (  fullDesc
              <> header cmdHeader
              <> progDesc ""
              )
  case cmd of
    CmdOptions{..} -> do
      settings     <- readYaml cmdConfigPath
      extraLog     <- mapM readYaml cmdExtraLog
      let appSettings = maybe settings (cmdExtraLogAdder settings) extraLog
      return appSettings


parser :: Parser CmdOptions
parser = do
  cmdConfigPath <- strArgument
    (  metavar "PATH"
    <> help "Path to configuration"
    <> value "config/surbgirq-web.yaml"
    <> showDefault
    )
  cmdExtraLog <- optional $ strOption
    (  long "extra-log"
    <> metavar "PATH"
    <> help "Path to extra log config"
    )
  return CmdOptions{..}
