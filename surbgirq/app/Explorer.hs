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
import Surbgirq.Bot.ClientRequests (graphApiClient)
import Surbgirq.Types              (findTransByAbbr)
import System.Exit                 (die)
import Types
import VerseExplorer

import qualified Data.Text as T


main :: IO ()
main = do
  installSigtermHandler
  ExplorerSettings{..} <- getExplorerSettings "Verse Explorer web server ..."
  let host = serverHost explorer'server
      port = serverPort explorer'server
      staticPath = serverStaticDir explorer'server
      warpSettings = Warp.setHost host $ Warp.setPort port Warp.defaultSettings
  graphApi <- graphApiClient explorer'graphApiUrl
  defaultBible <- maybe (die $ "EXPLORER_DEFAULT_BIBLE is not a translation the explorer knows: \""
                               <> T.unpack explorer'defaultBible <> "\" (an ID such as v1805-T or e1994-T)")
                        pure (findTransByAbbr (T.strip explorer'defaultBible))
  putStrLn $ mconcat [ "Verse explorer: listening on ", show host, " port ", show port
                     , "; the graph API at ", explorer'graphApiUrl, "; front page: ", show defaultBible ]
  Warp.runSettings warpSettings $ staticPolicy (noDots >-> addBase staticPath) $ app graphApi defaultBible



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

