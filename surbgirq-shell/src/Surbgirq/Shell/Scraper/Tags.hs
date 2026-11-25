{-# LANGUAGE OverloadedStrings #-}
-- | The three HTML-tag matches the scrapers need, on 'Text', with no regular-expression library.
--
-- They replace four PCRE patterns (pcre-heavy, PCRE1 in UTF-8 mode) and give exactly their results, on any text:
--
-- * @'splitAtElements' name@ is @split [re|\<\\s*name[^>]*>(.*?)\<\\s*\/\\s*name>|]@;
-- * @'removeElements' name@ joins those pieces again, so it drops each such element with what it holds;
-- * 'linksWithWordBefore' is @scan [re|(?:\\S+\\s)?\\S*\<\\s*a[^>]*>(.*?)\<\\s*\/\\s*a>|]@.
--
-- So, as with the patterns:
--
-- * an element opens with @\<@, any spaces, the name (case matters), then anything up to the first @>@. A longer tag
--   name that starts with the name opens one too: @\<spanx>@ for @span@, @\<abbr>@ for @a@;
-- * it ends at the first closing tag (@\<\/name>@, spaces allowed around the @\/@), on the same line: with no closing
--   tag before the next line feed, no element starts at that @\<@. Elements don't nest;
-- * the first element is the leftmost one, and the search for the next one starts where it ended;
-- * a space is one of the six ASCII white-space characters (tab, line feed, vertical tab, form feed, carriage return,
--   space). A no-break space counts as a letter.
module Surbgirq.Shell.Scraper.Tags
    ( splitAtElements
    , removeElements
    , linksWithWordBefore
    ) where

import Control.Applicative ((<|>))
import Data.Maybe          (listToMaybe, mapMaybe)
import Data.Text           (Text)

import qualified Data.Text as T

-- | The text between the elements named @name@ (@\<name …>…\<\/name>@): the text before the first one, between each
-- two, and after the last one, empty pieces included. A text with no such element comes back whole.
splitAtElements :: Text -> Text -> [Text]
splitAtElements name t = case leftmost (elementAt name) t of
    Just (before, _, (_, after)) -> before : splitAtElements name after
    Nothing                      -> [t]

-- | The text without its elements named @name@, and without what they hold.
removeElements :: Text -> Text -> Text
removeElements name = T.concat . splitAtElements name

-- | Each link (@\<a …>…\<\/a>@) with the text in front of it: the word joined to the link, and the word before that
-- one if a single space separates them. Each comes as the whole match and the link's text. Of two links that touch,
-- the first is part of the second one's word, as with the pattern.
linksWithWordBefore :: Text -> [(Text, Text)]
linksWithWordBefore t = case leftmost linkWithWordBeforeAt t of
    Just (_, from, (linkText, after)) ->
        (T.take (T.length from - T.length after) from, linkText) : linksWithWordBefore after
    Nothing                           -> []

-- | Where @matchAt@ first matches, trying each position from the left as PCRE does: the text before that position,
-- the text from it, and the match.
leftmost :: (Text -> Maybe a) -> Text -> Maybe (Text, Text, a)
leftmost matchAt t = go 0 t
  where
    go n rest = case matchAt rest of
        Just m  -> Just (T.take n t, rest, m)
        Nothing -> do
            (_, rest') <- T.uncons rest
            go (n + 1) rest'

-- | An element named @name@ at the start of the text: what it holds, and the text after it.
elementAt :: Text -> Text -> Maybe (Text, Text)
elementAt name t = do
    afterLt <- T.stripPrefix "<" t
    afterName <- T.stripPrefix name (T.dropWhile isAsciiSpace afterLt)
    content <- T.stripPrefix ">" (T.dropWhile (/= '>') afterName)
    let close n rest = case closingTagAt name rest of
            Just after -> Just (T.take n content, after)
            Nothing    -> case T.uncons rest of
                Just (c, rest') | c /= '\n' -> close (n + 1) rest'
                _                           -> Nothing
    close (0 :: Int) content

-- | A closing tag @\<\/name>@ at the start of the text: the text after it.
closingTagAt :: Text -> Text -> Maybe Text
closingTagAt name t = do
    afterLt <- T.stripPrefix "<" t
    afterSlash <- T.stripPrefix "/" (T.dropWhile isAsciiSpace afterLt)
    afterName <- T.stripPrefix name (T.dropWhile isAsciiSpace afterSlash)
    T.stripPrefix ">" afterName

-- | @(?:\\S+\\s)?\\S*@ and a link, at the start of the text: the link's text, and the text after the link. The word
-- with its one space is tried first, then a link in the first word itself.
linkWithWordBeforeAt :: Text -> Maybe (Text, Text)
linkWithWordBeforeAt t = withWordBefore <|> linkInWord t
  where
    (word, rest) = T.break isAsciiSpace t
    withWordBefore
        | T.null word = Nothing
        | otherwise   = T.uncons rest >>= linkInWord . snd

-- | @\\S*@ and a link: of the links that start in the run of non-spaces, the one furthest to the right, since @\\S*@
-- is greedy.
linkInWord :: Text -> Maybe (Text, Text)
linkInWord t = listToMaybe (mapMaybe (elementAt "a") tagStarts)
  where
    run = T.takeWhile (not . isAsciiSpace) t
    tagStarts = reverse [T.drop i t | (i, '<') <- zip [0 :: Int ..] (T.unpack run)]

-- | PCRE's @\\s@ without Unicode properties: tab, line feed, vertical tab, form feed, carriage return and space.
isAsciiSpace :: Char -> Bool
isAsciiSpace c = c == ' ' || ('\t' <= c && c <= '\r')
