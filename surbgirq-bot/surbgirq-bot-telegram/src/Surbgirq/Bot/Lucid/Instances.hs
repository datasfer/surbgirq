{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}
module Surbgirq.Bot.Lucid.Instances where

import Data.List
import Lucid

import Data.Text (append, pack, unpack)

import qualified Data.Aeson as A


import Surbgirq.Types



instance ToHtml [Book]  where
    toHtml [] = mempty
    toHtml xs = mapM_ toHtml xs
    toHtmlRaw = toHtml


instance ToHtml Book  where
    toHtml Book{..} = do
        let space2 = addSpace 2
            b = (toHtml . pack $ show book'number) <> space2 <> (bold_ $ toHtml book'title) <> space2 <> (toHtml $ pack  $ show book'book)
        withNewLine b
    --   _b
    -- { book'Id          :: Int -- node <id>
    -- , book'bookId      :: Text
    -- , book'labels      :: [Text]
    -- , book'book        :: Girq
    -- , book'title       :: Text
    -- , book'number      :: Int
    -- , book'chapters    :: Int
    -- , book'testament   :: Testament
    -- , book'translation :: Text

    toHtmlRaw = toHtml


instance ToHtml [Verse]  where
    toHtml [] = mempty
    toHtml xs = mapM_ toHtml xs
    toHtmlRaw = toHtml


instance ToHtml Verse  where
    toHtml Verse{..} = do
        let space2 = addSpace 2
            b = (toHtml . pack $ show verse'verse) <> space2 <> (bold_ $ toHtml verse'content) <> space2 <> (toHtml $ pack  $ show verse'book)
        withNewLine b
    toHtmlRaw = toHtml




-- | Telegram support html tags list
-- https://core.telegram.org/bots/api#markdownv2-style
-- <b>bold</b>, <strong>bold</strong>
-- <i>italic</i>, <em>italic</em>
-- <u>underline</u>, <ins>underline</ins>
-- <s>strikethrough</s>, <strike>strikethrough</strike>, <del>strikethrough</del>
-- <b>bold <i>italic bold <s>italic bold strikethrough</s> <u>underline italic bold</u></i> bold</b>
-- <a href="http://www.example.com/">inline URL</a>
-- <a href="tg://user?id=123456789">inline mention of a user</a>
-- <code>inline fixed-width code</code>
-- <pre>pre-formatted fixed-width code block</pre>
-- <pre><code class="language-python">pre-formatted fixed-width code block written in the Python programming language</code></pre>


-- | Missing tags implementation

-- | The @strikethrough@ 's' tag.
s_ :: Term arg result => arg -> result
s_ = term "s"

-- | The @underline@ 'u' tag.
u_ :: Term arg result => arg -> result
u_ = term "u"


-- | The @bold@ 'b' tag.
bold_ :: Term arg result => arg -> result
bold_ = term "b"



addSpace n = (toHtml $ pack $ replicate n ' ')

withNewLine t = t <> (toHtml $ pack  "\n")
