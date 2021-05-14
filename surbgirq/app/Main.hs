{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}

module Main where

import Control.Concurrent.STM
import Control.Monad.IO.Class
import Network.Wai.Middleware.Static

import Data.Default (def)
import Data.Monoid  ((<>))
import Data.Pool    (createPool)

import Database.Bolt

import qualified Network.Wai.Handler.Warp as Warp

-- import Surbgirq.Service
-- import Surbgirq.State
import Settings
import Sigterm
import Types
-------------------------------------------------------------------------------
--
------------------------------------------------------------
-- Start REST API
------------------------------------------------------------

main :: IO ()
main = do
  installSigtermHandler
  SurbgirqSettings{..} <- getSurbgirqSettings
  let port = serverPort surbgirq'server
      staticPath = serverStaticDir surbgirq'server
      dbName = sqliteConfig'dbName $ storeSpec'sqlite surbgirq'stores
      neo4jConfig = storeSpec'neo4j surbgirq'stores

  pool <- createPool (connect (boltCfg neo4jConfig)) close 4 500 1
  putStrLn $ mconcat ["Start surbgirq on port: ", show  port] -- , " with db: ", dbName]
--  state <- newTVarIO def
--  withDatabase dbName $ \c ->
  -- Warp.run port $ staticPolicy (noDots >-> addBase staticPath) $ app (ServerEnv pool undefined)



boltCfg :: Neo4jConfig -> BoltCfg
boltCfg Neo4jConfig {..} = def { user = neo4jConfig'user, password = neo4jConfig'pass }


getSurbgirqSettings :: IO SurbgirqSettings
getSurbgirqSettings =
  getSettings "Surbgirq "
    (\s logs -> s { surbgirq'logs =
                        let q1 = surbgirq'logs s
                        in  q1 { logSpec'logFiles = logSpec'logFiles q1 ++ logs }
                  })
