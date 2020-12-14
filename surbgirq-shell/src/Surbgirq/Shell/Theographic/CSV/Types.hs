{-# LANGUAGE DeriveGeneric       #-}
{-# LANGUAGE FlexibleInstances   #-}
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}

module Surbgirq.Shell.Theographic.CSV.Types
    (
      module Surbgirq.Shell.Theographic.CSV.Types
    , module X
    )where



import Surbgirq.Shell.Theographic.CSV.Types.Book        as X
import Surbgirq.Shell.Theographic.CSV.Types.Chapter     as X
import Surbgirq.Shell.Theographic.CSV.Types.Easton      as X
import Surbgirq.Shell.Theographic.CSV.Types.Event       as X
import Surbgirq.Shell.Theographic.CSV.Types.Period      as X
import Surbgirq.Shell.Theographic.CSV.Types.Person      as X
import Surbgirq.Shell.Theographic.CSV.Types.PersonGroup as X
import Surbgirq.Shell.Theographic.CSV.Types.Place       as X
import Surbgirq.Shell.Theographic.CSV.Types.Testament   as X
import Surbgirq.Shell.Theographic.CSV.Types.Token       as X
import Surbgirq.Shell.Theographic.CSV.Types.Verse       as X

import GHC.Generics

import Data.Text (Text)

-- cassava
import           Data.ByteString   (ByteString)
import           Data.Csv
    ( DefaultOrdered(headerOrder)
    , FromField(parseField)
    , FromNamedRecord(parseNamedRecord)
    , Header
    , NamedRecord
    , Parser
    , ToField(toField)
    , ToNamedRecord(toNamedRecord)
    , record
    , (.:)
    , (.=)
    )
import qualified Data.Csv          as Cassava
import qualified Data.HashMap.Lazy as HM
-- import Network.URI (parseURI, URI)
import           Data.List.Split
import qualified Data.Text       as T



















