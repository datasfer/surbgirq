{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}

module Main where

import Control.Concurrent.STM
import Control.Monad.IO.Class
import Network.Wai.Middleware.Static

import Data.Default (def)
import Data.Monoid  ((<>))

import qualified Network.Wai.Handler.Warp as Warp

import Surbgirq.Service
-- import Surbgirq.State
import Settings
import Sigterm
import Types
-------------------------------------------------------------------------------
--

main :: IO ()
main = do
  installSigtermHandler
  SurbgirqSettings{..} <- getSurbgirqSettigns
  let port = serverPort surbgirq'server
      staticPath = serverStaticDir surbgirq'server
      newsPath = serverNewsDir surbgirq'server
      dbName = sqliteStore'dbName $ storeSpec'sqlite surbgirq'stores
  putStrLn $ mconcat ["Start crosschain on port: ", show  port] -- , " with db: ", dbName]
--  state <- newTVarIO def
--  withDatabase dbName $ \c ->
  Warp.run port $ staticPolicy (noDots >-> addBase staticPath) $ app (ServerEnv undefined )






getSurbgirqSettigns :: IO SurbgirqSettings
getSurbgirqSettigns =
  getSettings "Surbgirq "
                  (\s logs -> s { surbgirq'logs =
                                  let q1 = surbgirq'logs s
                                  in  q1 { logSpec'logFiles = logSpec'logFiles q1 ++ logs }
                              })
