{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}


module Surbgirq.Types.Instances where

import Data.Maybe (fromMaybe)

import Surbgirq.Types.Abbr
import Surbgirq.Types.Girq

------------------------------------------------------------
--
------------------------------------------------------------

-- instance Read Girq where
--     readsPrec _ s = readsGirq s

-- readsGirq :: (Read a) => ReadS Girq
-- readsGirq s = let mGirq = findByAbbr girqText
--               in fromMaybe Matthew mGirq




