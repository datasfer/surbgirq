{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedLabels  #-}
{-# LANGUAGE OverloadedStrings #-}

module Surbgirq.Shell.Store.SQLite.Selda where


import Database.Selda
import Database.Selda.SQLite

import Surbgirq.Shell.Store.Types


instance SqlRow EngLemma

engLemma :: Table EngLemma
engLemma = table "englemma" [#lemmaID :- autoPrimary]



instance SqlRow WordForm

wordFrom :: Table WordForm
wordFrom = table "wordform" [#formID :- autoPrimary]



instance SqlRow Armat

armats :: Table Armat
armats = table "armat" [ #armatID :- autoPrimary]

instance SqlRow ArmatForm

armatforms :: Table ArmatForm
armatforms = table "armatform" [ #armatFormID :- autoPrimary
    , #relArmat :- (foreignKey armats #armatID)
    ]


getFormsWithArmats = do
    armatForm <- select armatforms
    armat <- leftJoin (\armat -> armat ! #armatID .== armatForm ! #relArmat)
                        (select armats)
    return (armatForm :*: armat)



getArmat :: Int -> Query s (Row s Armat)
getArmat id = do
    armat <- select armats
    restrict (armat ! #armatID .== (literal $ toId id))
    return armat

getCustomers :: Query s (Row s Armat)
getCustomers = do
    armats <- select armats
    return armats
