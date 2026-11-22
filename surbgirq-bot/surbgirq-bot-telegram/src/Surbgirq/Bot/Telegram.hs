{-# LANGUAGE AllowAmbiguousTypes        #-}
{-# LANGUAGE DataKinds                  #-}
{-# LANGUAGE DeriveFunctor              #-}
{-# LANGUAGE DeriveGeneric              #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE QuasiQuotes                #-}
{-# LANGUAGE RecordWildCards            #-}
{-# LANGUAGE TypeOperators              #-}
{-# LANGUAGE ViewPatterns               #-}
module Surbgirq.Bot.Telegram
    ( startApp
    , app
    ) where
import Control.Monad                 (replicateM)
import Data.Char                     (isNumber)
import Data.List                     (intercalate, intersperse)
import Data.List.Split               (chunksOf)
import Data.Text                     (Text, empty)
import Data.Version                  (makeVersion, showVersion)
import GHC.Generics                  hiding (from)
import Network.HTTP.Client           (Manager, newManager)
import Network.HTTP.Client.TLS       (tlsManagerSettings)
import Text.InterpolatedString.Perl6 (qc)
import Text.Read                     (readMaybe)

import Data.IORef

import qualified Data.Text      as T
import qualified Data.Text.Lazy as TL

import Lucid

import Control.Concurrent.STM
import Control.Monad.Except
import Control.Monad.Reader
import Data.Aeson
import Data.Default
import Data.Maybe
import Data.Monoid
import Network.Wai
import Network.Wai.Handler.Warp
import Servant
import Servant.Client                (ClientEnv)
import Servant.Server
import System.Environment
import Text.Regex.Posix

import Surbgirq.Bot.App
import Surbgirq.Bot.Server.TelegramAPI
import Surbgirq.Bot.Types

------------------------------------------------------------
--
------------------------------------------------------------


-- if Settings.telegram_base_url != "https://api.telegram.org/bot":
--         r = requests.get(f"https://api.telegram.org/bot{Settings.telegram_token}/logOut")
--         logger.info("Using local bot API, logout result: %s", r.text)
-- print "API endpoint: %s", bot.base_url

--
-- https://api.telegram.org/botREMOVED-TELEGRAM-TOKEN/logOut
startApp :: ClientEnv -> String -> String -> Int -> IO ()
startApp graphApi' dbName botApiUrl port = do
  putStrLn "Surbgirq bot started..."
  manager' <- newManager tlsManagerSettings
  fbManager <- newManager tlsManagerSettings
  ref <- liftIO $ newIORef (0 :: Int)
  state <- newTVarIO def

  let telegramToken' = "REMOVED-TELEGRAM-TOKEN"
      fbVerifyToken = "123456"
      fbPageToken = "REMOVED-FACEBOOK-TOKEN"

      config = BotConfig
        { telegramToken = Token $ T.pack $ "bot" <> telegramToken'
        , botApiHost = T.pack botApiUrl
        , botApiPort = port
        , apiCachTime = Just 333 --  amount of time in seconds that the result may be cached on the server.
        , graphApi = graphApi'
        , facebookVerifyToken = fbVerifyToken
        , facebookPageToken = fbPageToken
        , manager = manager'
        , facebookManager = fbManager
        , ref = ref
        , state = state
        }
  putStrLn $ concat ["BOT API endpoint: ", botApiUrl, ":", show port]

  run 5000 $ app config
