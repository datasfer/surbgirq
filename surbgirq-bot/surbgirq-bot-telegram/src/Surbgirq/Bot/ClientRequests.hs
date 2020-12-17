{-# LANGUAGE DataKinds #-}

{-|
Module      : Surbgirq.Bot.Server
Description : endpoint handlers to call the local neo4j db acccess api

Implement local graphdb rest api calls
-}

module Surbgirq.Bot.ClientRequests (
   getBooksHandler
 , getVerseRangeHandler
 , getOneVerseHandler
 , getBookSectionsHandler
 , getChapterSectionsHandler
 , getChapterOneSectionHandler
 , getChapterVerseNumberHandler

 -- , bookChapterNums
 -- , bookChapterSectionNums
 -- , bookChapterVerseNums
 ) where


import Network.HTTP.Client     (Manager, defaultManagerSettings, newManager)
import Network.HTTP.Client.TLS (tlsManagerSettings)
import Servant.Client

import Surbgirq.API.GraphDBClient
import Surbgirq.Types

------------------------------------------------------------
--
------------------------------------------------------------



getBooksHandler :: TranslationID -> IO [Book]
getBooksHandler translation = do
  env <-  mkClientEnv <$> newManager defaultManagerSettings <*> parseBaseUrl "http://localhost:33010"
  mgr <-  newManager tlsManagerSettings
  mres <- flip runClientM env $ getAllBooks' translation -- mgr
  case mres of
    Left e  -> error $ show e -- throwIO $ ClientError e
    Right a -> pure a



getVerseRangeHandler :: TranslationID -> Girq -> ChapterNum -> VerseNum -> Maybe VerseNum -> IO [Verse]
getVerseRangeHandler translation girq ch v1 v2 = do
  env <-  mkClientEnv <$> newManager defaultManagerSettings <*> parseBaseUrl "http://localhost:33010"
  mgr <-  newManager tlsManagerSettings
  mres <- flip runClientM env $ getVerseRange' translation girq ch v1 v2 -- mgr
  case mres of
    Left e  -> error $ show e -- throwIO $ ClientError e
    Right a -> pure a


getOneVerseHandler :: TranslationID -> Girq -> ChapterNum -> VerseNum -> IO [Verse]
getOneVerseHandler translation girq ch v1 = do
  env <-  mkClientEnv <$> newManager defaultManagerSettings <*> parseBaseUrl "http://localhost:33010"
  mgr <-  newManager tlsManagerSettings
  mres <- flip runClientM env $ getOneVerse' translation girq ch v1
  case mres of
    Left e  -> error $ show e -- throwIO $ ClientError e
    Right a -> pure a



-- | Sections
getBookSectionsHandler :: TranslationID -> Girq -> IO [Section]
getBookSectionsHandler translation girq = do
  env <-  mkClientEnv <$> newManager defaultManagerSettings <*> parseBaseUrl "http://localhost:33010"
  mgr <-  newManager tlsManagerSettings
  mres <- flip runClientM env $ getBookSections' translation girq
  case mres of
    Left e  -> error $ show e -- throwIO $ ClientError e
    Right a -> pure a

getChapterSectionsHandler :: TranslationID -> Girq -> ChapterNum -> IO [Section]
getChapterSectionsHandler translation girq ch = do
  env <-  mkClientEnv <$> newManager defaultManagerSettings <*> parseBaseUrl "http://localhost:33010"
  mgr <-  newManager tlsManagerSettings
  mres <- flip runClientM env $ getChapterSections' translation girq ch
  case mres of
    Left e  -> error $ show e -- throwIO $ ClientError e
    Right a -> pure a


getChapterOneSectionHandler :: TranslationID -> Girq -> ChapterNum -> SectionNum -> IO [Section]
getChapterOneSectionHandler translation girq ch sec = do
  let dialect = Ashxarhabar
  env <-  mkClientEnv <$> newManager defaultManagerSettings <*> parseBaseUrl "http://localhost:33010"
  mgr <-  newManager tlsManagerSettings
  mres <- flip runClientM env $ getChapterOneSection' translation girq ch sec
  case mres of
    Left e  -> error $ show e -- throwIO $ ClientError e
    Right a -> pure a

getChapterVerseNumberHandler :: Girq -> ChapterNum -> IO Int
getChapterVerseNumberHandler girq ch = do
  env <-  mkClientEnv <$> newManager defaultManagerSettings <*> parseBaseUrl "http://localhost:33010"
  mgr <-  newManager tlsManagerSettings
  mres <- flip runClientM env $ getChapterVerseNumber' girq ch
  case mres of
    Left e  -> error $ show e
    Right a -> pure a







