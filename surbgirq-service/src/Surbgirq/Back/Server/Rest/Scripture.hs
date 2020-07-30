{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE OverloadedStrings #-}

{-|
Module      : Surbgirq.Back.Server.Rest.Scripture
Description : Provide detail information about Scriptures

Scriptures endpoints (Verse, Chapters, etc)
-}

module Surbgirq.Back.Server.Rest.Scripture(
   scriptureChapter
 , scriptureChapterAllSections
 , scriptureChapterSection

 -- * Verses
 , scriptureChapterAllVerses
 , scriptureVerse
 , scriptureVerseFromTo
 , scriptureVerseByRefText
 ) where

import Control.Monad.Reader
import Data.Time.Clock.POSIX

-- import Control.Monad.Trans.Reader (ask)
import Control.Monad.Trans (lift, liftIO)
import Data.Maybe          (fromMaybe)
import Data.Pool           (withResource)
import Data.String         (IsString(..))
import Data.Text           (Text, pack, unpack)
import GHC.Int             (Int64)
import Text.Read           (readMaybe)

import Text.InterpolatedString.Perl6 (qc)

import Database.Bolt hiding (pack)

import qualified Data.ByteString.Char8  as BC8
import qualified Data.Text              as T
import qualified Database.SQLite.Simple as SQL

import Surbgirq.API
import Surbgirq.Back.App.Env
import Surbgirq.Neo4j
import Surbgirq.Types
import Surbgirq.Utils
------------------------------------------------------------
--
------------------------------------------------------------

-- | execute a neo4j query
-- get the neo4j pool resource from env and run neo4j query
runQ :: BoltActionT IO a -> AppM a
runQ act = do env <- ask
              liftIO $ withResource (env'pool env) (`run` act)

-- | return the @chNum chapter of @girq book
scriptureChapter :: Girq -> ChapterNum -> AppM [Chapter]
scriptureChapter girq chNum = runQ $ queryChapter girq chNum


-- | return all sections of @chNum chapter of @girq book
scriptureChapterAllSections :: Girq -> ChapterNum -> AppM [Section]
scriptureChapterAllSections girq chNum = runQ $ queryAllSections girq chNum

-- | return the @secNum section of @chNum chapter of @girq booka
scriptureChapterSection :: Girq -> ChapterNum -> SectionNum -> AppM [Section]
scriptureChapterSection girq chNum secNum = runQ $ querySection girq chNum secNum

-- | return all verses of @chNum chapter of @girq book
scriptureChapterAllVerses :: Girq -> ChapterNum -> AppM [Verse]
scriptureChapterAllVerses girq chNum = runQ $ queryAllVerses girq chNum

-- | return the @verseNum verse of @chNum chapter of @girq booka
scriptureVerse :: Girq -> ChapterNum -> VerseNum -> AppM [Verse]
scriptureVerse girq chNum verseNum = runQ $ queryVerse girq chNum verseNum

-- | return the verses from @vFrom verse to @vTo verse of @chNum chapter of @girq booka
scriptureVerseFromTo :: Girq -> ChapterNum -> VerseNum -> VerseNum -> AppM [Verse]
scriptureVerseFromTo girq chNum vFrom vTo = runQ $ queryVerseInterval girq chNum vFrom vTo


-- | return verse(s) by ref text
scriptureVerseByRefText :: Text -> AppM [Verse]
scriptureVerseByRefText verseText =  do
  let vs = T.split (==' ') verseText
  liftIO $ print vs
  case vs of
    [girqText, chVerseText] -> let girq = findByAbbr girqText
                                   [v1, v2] = T.split (=='.') chVerseText
                                   chNum = readMaybe $ T.unpack v1
                               in case (girq, chNum) of
                                    (Just g, Just ch) -> scriptureVerseByRef g (ChapterNum ch) v2
                                    _  -> do
                                       liftIO $ print girq
                                       liftIO $ print chNum
                                       liftIO $ print v1
                                       liftIO $ print v2



                                       error "cuold not parse book or ch num from verRef text"

    _  -> error "invalid format for refText"

-- | TODO: add proper comment
scriptureVerseByRef :: Girq -> ChapterNum -> Text -> AppM [Verse]
scriptureVerseByRef g c verseRange =  do
      let vs = T.split (=='-') verseRange
      liftIO $ print verseRange
      liftIO $ print vs

      case vs of
        [v1,v2] -> do
          let v_from = readMaybe $ T.unpack v1
              v_to = readMaybe $ T.unpack v2
          case (v_from, v_to) of
               (Just a, Just b) -> runQ $ queryVerseInterval g c (VerseNum a) (VerseNum b)
               (Just a,    _)   -> runQ $ queryVerse g c (VerseNum a)
               (_,_)            -> error "invalid verse interval text param"
        [v1] -> do
          let v_from = readMaybe $ T.unpack v1
          case v_from of
               Just a -> runQ $ queryVerse g c (VerseNum a)
               _      -> error "could not parse verse number"

        _ -> error "invalid verse interval text param"





