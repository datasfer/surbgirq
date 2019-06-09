{-# LANGUAGE TemplateHaskell              #-}
{-# LANGUAGE OverloadedStrings              #-}

module Surbgirq.Neo4j.Types where

import           Data.Text                      ( Text )

-- import           Database.Bolt.Extras.Template
import Surbgirq.Types


data HAS_CH = HAS_CH
data HAS_VERSE = HAS_VERSE



-- fromList [("b",S (Structure {signature = 78, fields = [I 0,L [T "Book"],M (fromList [("title",T "matthew")])]}))]
-- fromList [("b",S (Structure {signature = 78, fields = [I 41,L [T "Book"],M (fromList [("title",T "matthew")])]}))]
-- fromList [("b",
--S (Structure {signature = 78, fields = [I 640
--                                       ,L [T "Book",T "Matthew",T "New"]
--                                       ,M (fromList [("title",T "Matthew")])
--                                       ]   } )
