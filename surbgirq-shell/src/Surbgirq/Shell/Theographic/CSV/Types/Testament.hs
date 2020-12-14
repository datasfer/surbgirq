{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}

module Surbgirq.Shell.Theographic.CSV.Types.Testament where


import GHC.Generics

import Data.Text (Text)

-- cassava
import Data.Csv
    ( DefaultOrdered(headerOrder)
    , FromField(parseField)
    , FromNamedRecord(parseNamedRecord)
    , (.:)
    , (.=)
    )


data Testament
  = NewTestament
  | OldTestament
  | Other Text
   deriving (Eq, Show)

instance FromField Testament where
  parseField s | s == "Old Testament" = pure OldTestament
               | s == "New Testament" = pure NewTestament
               | otherwise = Other <$> parseField s
