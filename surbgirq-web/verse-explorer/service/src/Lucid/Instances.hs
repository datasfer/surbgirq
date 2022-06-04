{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}
module Lucid.Instances where

import Data.List
import Lucid
import Lucid.Base
import Lucid.Helper
import Lucid.Html5

import Data.Text (Text)

import qualified Data.Text as T

import Surbgirq.Types
import VerseExplorer.Types

-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------
instance ToHtml About where
    toHtml (About txt) = mkPage $ toHtml txt
    toHtmlRaw = toHtml

instance ToHtml SearchFound where
    toHtml FoundNothing    = mkPage $ "Not found"
    toHtml (FoundVerse xs) = mkPage $ "s"
    toHtmlRaw = toHtml

instance ToHtml [Book] where
    toHtml [] = mkPage mempty
    toHtml xs = do
      mkPage $ div_ [] $ do
        div_ [class_ "tx-list",  style_ "display: flex"] $ do
          girqTable $ sortOn book'number $ filter (\Book{..} -> book'testament == New) xs
          girqTable $ sortOn book'number $ filter (\Book{..} -> book'testament == Old) xs
    toHtmlRaw = toHtml





girqTable :: Monad m => [Book] -> HtmlT m ()
girqTable bs =
      table_ [ id_ "books", class_ "table table-hover"] $ do
        thead_ $
           tr_ $ do
            th_ "#"
            th_ "Book"
            th_ "Title"
            th_ "Testament"
        tbody_ $ do
          mapM_ bookItemRow bs

bookItemRow :: Monad m => Book -> HtmlT m ()
bookItemRow b@Book{..} = do
  tr_ [id_ $ T.pack $ show book'book] $ do
    td_ [] (toHtml $ show book'number)
    td_ [] (a_ [href_ (htoUrl b)] (toHtml $ show book'book))
    td_ [] (toHtml $ book'title)
    td_ [] (toHtml $ show book'testament)


instance ToHtml [Verse] where
    toHtml [] = mkPage mempty
    toHtml xs = do
      mkPage $ div_ [] $ do
        let v@Verse{..} = head xs
        h2_ [] (toHtml $ T.concat [verse'bookTitle, "(", verse'translation, ")"] )
        chNumsList v 50
        h3_ [] (toHtml $ show verse'chapter)
        div_ [class_ "verse-list",  style_ "display: flex"] $ do
          verseTable  xs
    toHtmlRaw = toHtml

chNumsList :: Monad m => Verse -> Int  -> HtmlT m ()
chNumsList verse n =
      table_ [ id_ "ch_nums", makeAttribute "border" "0"] $ do
        tbody_ $ do
          tr_ [] $ mapM_ chNumRow [1..25]
          tr_ [] $ mapM_ chNumRow [26..n]
  where
    chNumRow :: Monad m => Int -> HtmlT m ()
    chNumRow i = td_ [] (a_ [href_ (chNumtoUrl verse i)] (toHtml $ show i))


verseTable :: Monad m => [Verse] -> HtmlT m ()
verseTable vs =
      table_ [ id_ "verses", makeAttribute "border" "0"] $ do
        tbody_ $ do
          mapM_ verseItemRow vs

verseItemRow :: Monad m => Verse -> HtmlT m ()
verseItemRow b@Verse{..} = do
  tr_ [id_ $ T.pack $ show verse'verse] $ do
    td_ [] (sup_ [] $ toHtml $ show verse'verse)
    td_ [] (toHtml $ verse'content)
    -- td_ [] (a_ [href_ (htoUrl b)] (toHtml $ show book'book))
    -- td_ [] (toHtml $ book'title)
    -- td_ [] (toHtml $ show book'testament)


instance ToHtml [Section] where
    toHtml [] = mkPage mempty
    toHtml _  = mempty
    toHtmlRaw = toHtml


htoUrl :: Book -> Text
htoUrl Book{..} = T.pack $ concat [ "/scripture/"
                                  , T.unpack book'translation
                                  , "/books/"
                                  , show book'book
                                  , "/chapters/"
                                  , "1"
                                  , "/verses/1?v2=100" ]

chNumtoUrl :: Verse -> Int -> Text
chNumtoUrl Verse{..} i =
    T.pack $ concat [ "/scripture/"
                    , T.unpack verse'translation
                    , "/books/"
                    , show verse'book
                    , "/chapters/"
                    , show i
                    , "/verses/1?v2=100" ]


--        :<|> "scripture" :> Capture "translation" TranslationID
--                  :> "books" :> Capture "girq" Girq
--                  :> "chapters" :> Capture "ch" ChapterNum
--                  :> "verses" :> Capture "verseFrom" VerseNum
-- --                 :> "to" :> Capture "verseTo" VerseNum
--                  :> QueryParam "v2" VerseNum
--                  :> Get '[JSON] [Verse]
