{-# LANGUAGE ApplicativeDo     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}

module Main where

import Control.Monad.IO.Class
import Network.Wai.Middleware.Static
import Options.Applicative

import Data.Aeson               (FromJSON)
import Data.Monoid              ((<>))
import Network.Wai.Handler.Warp (HostPreference)

import qualified Network.Wai.Handler.Warp             as Warp
import           Network.Wai.Middleware.RequestLogger (logStdoutDev)

import Common.Aeson
import Common.Yaml
import Data.Maybe

import Settings
import Sigterm
import Types
import VerseExplorer


main :: IO ()
main = do
  installSigtermHandler
  ExplorerSettings{..} <- getExplorerSettings "Verse Explorer web server ..."
  let port = serverPort explorer'server
      staticPath = serverStaticDir explorer'server
  putStrLn $ mconcat ["Start verse explorer on port: ", show port]
  Warp.run port $ staticPolicy (noDots >-> addBase staticPath) $ app



data CmdPath = CmdPath
    { cmdConfigPath :: FilePath
    }

getExplorerSettings :: (FromJSON a) => String -> IO a
getExplorerSettings cmdHeader = do
  cmd <- customExecParser (prefs showHelpOnError)
            $ info (helper <*> parser1)
              (  fullDesc
              <> header cmdHeader
              <> progDesc ""
              )
  case cmd of
    CmdPath{..} -> do
      botSettings     <- readYaml cmdConfigPath
      return botSettings


parser1 :: Parser CmdPath
parser1 = do
  cmdConfigPath <- strArgument
    (  metavar "PATH"
    <> help "Path to verse explorer front-end settings"
    <> value "config/verse-explorer.yaml"
    <> showDefault
    )
  return CmdPath{..}

