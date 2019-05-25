{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module Bex.Back.Store.Types where

import GHC.Generics

import Data.Text (Text, pack)
import GHC.Int   (Int64)

import qualified Database.SQLite.Simple as SQL

import Database.SQLite.Simple          (ResultError(..), SQLData(..))
import Database.SQLite.Simple.Internal (Field(..))
import Database.SQLite.Simple.Ok       (Ok(..))

import Database.SQLite.Simple.FromField
import Database.SQLite.Simple.FromRow
import Database.SQLite.Simple.ToField
import Database.SQLite.Simple.ToRow


------------------------------------------------------------
--
------------------------------------------------------------


-- | the data to keep mapping from tx hash to block height.
-- this type will be used to write/read to the external db.
data HashToBlock = HashToBlock {
      hashtoblock'type    :: HashType
    -- ^ tx hash
    , hashtoblock'height  :: Int64
    -- ^ hash type
    , hashtoblock'hash    :: Text
    -- ^ coresponding block height
    , hashtoblock'txCount :: Int
    -- ^ tx count of block
    , hashtoblock'time    :: Int64
    -- ^ block creation time
    , hashtoblock'flag    :: Int
    -- ^ flag accumulateing the tx types
    } deriving (Show, Generic)

-- | the type of object we get the hash
data HashType = TxEntity
              | BlockEntity
              deriving (Show, Read, Eq, Generic)



-- | need this instance to read from sqlite db
instance FromRow HashToBlock where
  fromRow = do
      h <- field
      n <- field
      ts <- field
      c <- field
      t <- field
      f <- field
      return $ HashToBlock t n h c ts f

-- | need this instance to use in db query as parameter
-- the triple order should match the table column order
instance ToRow HashToBlock where
  toRow HashToBlock{..} = toRow (hashtoblock'hash, hashtoblock'height, hashtoblock'time, hashtoblock'txCount, hashtoblock'type, hashtoblock'flag)

instance ToRow HashType where
    toRow h = [toField h]

-- instance FromRow HashType
instance ToField HashType where
    toField TxEntity    = toField (pack "Tx")
    toField BlockEntity = toField (pack "Block")

instance FromField HashType where
    fromField (Field (SQLText "Tx") _) = Ok TxEntity
    fromField (Field (SQLText "tx") _) = Ok TxEntity
    fromField (Field (SQLText "Block") _) = Ok BlockEntity
    fromField (Field (SQLText "block") _) = Ok BlockEntity
    fromField f = returnError ConversionFailed f "Invalid value for hash type"


mkBlockHash :: Int64 -> Text -> Int -> Int64 -> Int -> HashToBlock
mkBlockHash = HashToBlock BlockEntity

mkTxHash :: Int64 -> Text -> Int -> Int64 -> Int -> HashToBlock
mkTxHash = HashToBlock TxEntity
