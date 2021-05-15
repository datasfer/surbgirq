{-# LANGUAGE OverloadedStrings #-}

{-|
Module      : Surbgirq.API.Instances
Description : Instances for http url

Instances for parse and convert to url
-}

module Surbgirq.API.Instances() where

import Data.Bifunctor
import Text.Read
import Web.HttpApiData

import Data.Char  (toLower, toUpper)
import Data.Maybe (fromMaybe)
import Data.Text  (append, pack, unpack)

import Surbgirq.Types

-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------

instance ToHttpApiData Girq where
  toUrlPiece = pack . capitalized .show

instance ToHttpApiData Dialect where
  toUrlPiece = pack . capitalized . show

instance ToHttpApiData TranslationID where
  toUrlPiece = pack . show

instance FromHttpApiData Girq where
--  parseUrlPiece = fmap read . parseUrlPiece
--   parseUrlPiece = read . capitalized . parseUrlPiece
   parseUrlPiece s = case findByAbbr s of
                       Just (g, _) -> Right g
                       Nothing     -> Left $ append "Could not parse Girq:" s
                     -- in fromMaybe Matthew mGirq
                       --           case readEither . capitalized $ unpack s of
                       -- Left err -> error err
                       -- Right g  -> g

instance ToHttpApiData ChapterNum where
  toUrlPiece (ChapterNum n) = toUrlPiece n
  {-# INLINE toUrlPiece #-}

instance FromHttpApiData ChapterNum where
  parseUrlPiece = fmap ChapterNum . parseUrlPiece
  {-# INLINE parseUrlPiece #-}

instance ToHttpApiData SectionNum where
  toUrlPiece (SectionNum n) = toUrlPiece n
  {-# INLINE toUrlPiece #-}

instance FromHttpApiData SectionNum where
  parseUrlPiece = fmap SectionNum . parseUrlPiece
  {-# INLINE parseUrlPiece #-}


instance FromHttpApiData TranslationID where
   parseUrlPiece s = case findTransByAbbr s of
                       Just t  -> Right t
                       Nothing -> Left $ append "Could not parse TranslationID:" s
  -- parseUrlPiece = fmap read . parseUrlPiece -- . pack
  -- parseUrlPiece s = case fmap read $ parseUrlPiece s of
  --                      Left err          -> error $  unpack err
  --                      Right translation -> translation

instance ToHttpApiData VerseNum where
  toUrlPiece (VerseNum n) = toUrlPiece n
  {-# INLINE toUrlPiece #-}

instance FromHttpApiData VerseNum where
  parseUrlPiece = fmap VerseNum . parseUrlPiece
  {-# INLINE parseUrlPiece #-}


-- | Make first letter upper case
-- will parse matthew as well
capitalized :: String -> String
capitalized []          = []
capitalized (head:tail) = toUpper head : tail

-- | Make first letter lower case
lowerized :: String -> String
lowerized []          = []
lowerized (head:tail) = toLower head : tail
