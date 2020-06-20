{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedLabels  #-}
{-# LANGUAGE OverloadedStrings #-}

module Surbgirq.Shell.Store.SQLite.Selda where


import Database.Selda
import Database.Selda.SQLite

import Surbgirq.Shell.Store.Types


instance SqlRow EngLemma

engLemmaTable :: Table EngLemma
-- engLemma = table "englemma" [#lemmaID :- autoPrimary]
engLemmaTable = table "englemma" [#lemmaID :- primary]



instance SqlRow WordForm

wordFormTable :: Table WordForm
wordFormTable = table "wordform" [#formID :- primary]



instance SqlRow Armat

armatTable :: Table Armat
armatTable = table "armat" [ #armatID :- primary]

instance SqlRow ArmatForm

armatformTable :: Table ArmatForm
armatformTable = table "armatform" [ #armatFormID :- primary
    , #relArmat :- (foreignKey armatTable #armatID)
    ]


getFormsWithArmats = do
    armatForm <- select armatformTable
    armat <- leftJoin (\armat -> armat ! #armatID .== armatForm ! #relArmat)
                        (select armatTable)
    return (armatForm :*: armat)


{-
getArmat :: Int -> Query s (Row s Armat)
getArmat id = do
    armat <- select armats
    restrict (armat ! #armatID .== tid ) --(literal $ toId id))
    return armat
-}
getCustomers :: Query s (Row s Armat)
getCustomers = do
    armats <- select armatTable
    return armats
