{-# LANGUAGE DataKinds #-}

{-|
Module      : Surbgirq.Back.Server.Rest.Book
Description : Provide high level information of the Book

Implement Book meta info related endpoints handlers
-}

module Surbgirq.Bot.Server (
   getBooksHandler
 , getVerseRangeHandler
 -- , bookChapterNums
 -- , bookChapterSectionNums
 -- , bookChapterVerseNums
 ) where


import Network.HTTP.Client     (Manager, defaultManagerSettings, newManager)
import Network.HTTP.Client.TLS (tlsManagerSettings)
import Servant.Client


-- import Surbgirq.API.Client
import Surbgirq.API.GraphDBClient

import Surbgirq.Types





getBooksHandler :: IO [Book]
getBooksHandler = do
  env <-  mkClientEnv <$> newManager defaultManagerSettings <*> parseBaseUrl "http://localhost:33010"
  mgr <-  newManager tlsManagerSettings
  mres <- flip runClientM env $ getAllBooks' -- mgr
  case mres of
    Left e  -> error $ show e -- throwIO $ ClientError e
    Right a -> pure a



getVerseRangeHandler :: Girq -> ChapterNum -> VerseNum -> VerseNum -> IO [Verse]
getVerseRangeHandler girq ch v1 v2 = do
  env <-  mkClientEnv <$> newManager defaultManagerSettings <*> parseBaseUrl "http://localhost:33010"
  mgr <-  newManager tlsManagerSettings
  mres <- flip runClientM env $ getVerseRange' girq ch v1 v2 -- mgr
  case mres of
    Left e  -> error $ show e -- throwIO $ ClientError e
    Right a -> pure a
