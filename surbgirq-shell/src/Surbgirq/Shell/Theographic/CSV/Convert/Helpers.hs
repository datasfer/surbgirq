module Surbgirq.Shell.Theographic.CSV.Convert.Helpers where


import Data.Csv    (FromNamedRecord(parseNamedRecord))
import Data.Vector (Vector)

import qualified Data.ByteString.Lazy as BL
import qualified Data.Csv             as Cassava

import Surbgirq.Shell.Theographic.CSV.Types

------------------------------------------------------------
--
------------------------------------------------------------

-- | "./data/theodata/CSV/Books.csv"
readEntity :: (FromNamedRecord a) => FilePath -> IO (Vector a)
readEntity booksFile = do
  csvData <- BL.readFile booksFile
  return $ case Cassava.decodeByName csvData of
        Left err      -> error err
        Right  (_, v) -> v

toTestamentId NewTestament = "new"
toTestamentId OldTestament = "old"
toTestamentId _            = "new"
