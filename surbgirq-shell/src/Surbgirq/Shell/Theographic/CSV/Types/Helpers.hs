{-# LANGUAGE DeriveGeneric       #-}
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Surbgirq.Shell.Theographic.CSV.Types.Helpers where


import GHC.Generics

import Data.ByteString (ByteString)
import Data.Text       (Text)

import qualified Data.HashMap.Lazy as HM

-- cassava
import Data.Csv
    ( DefaultOrdered(headerOrder)
    , FromField(parseField)
    , FromNamedRecord(parseNamedRecord)
    , NamedRecord
    , Parser
    , (.:)
    , (.=)
    )



(.:?) :: FromField a => NamedRecord -> ByteString -> Parser (Maybe a)
(.:?) m name = maybe (pure Nothing) parseField $ HM.lookup name m

-- instance FromField URI where
--   parseField f = parseField f >>= maybe (fail "invalid URL") pure . parseURI

-- instance FromField Date where
--   parseField x = parseField x >>= f where
--     f (splitAt 4 -> (ys, splitAt 2 -> (ms, ds)))
--       | length ds == 2
--       , Just [y,m,d] <- mapM readMay [ys,ms,ds]
--       = pure $ Date y m d
--     f d = fail $ "invalid date: " ++ d

-- instance FromField Time where
--   parseField x = parseField x >>= f where
--     f (mapM readMay . splitOn ":" -> Just [h,m,s])
--       = pure $ Time h m s
--     f s = fail $ "invalid time: " ++ s



enumParseField :: forall a. (Enum a, Bounded a) => ByteString -> Parser a
enumParseField xs = parseField xs >>= conv where
  mx = fromEnum (maxBound :: a)
  conv n
    | n > mx    = fail ("out of range: " ++ show n)
    | otherwise = pure (toEnum n)

-- instance FromField LocationType  where parseField = enumParseField

