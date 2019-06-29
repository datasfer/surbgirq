{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedLabels  #-}
{-# LANGUAGE OverloadedStrings #-}

module Surbgirq.Shell.Store.SQLite.Selda where


import Database.Selda
import Database.Selda.SQLite

import Surbgirq.Shell.Store.Types


instance SqlRow EngLemma

engLemma :: Table EngLemma
engLemma = table "englemma" []



instance SqlRow WordForm

wordFrom :: Table WordForm
wordFrom = table "wordform" []

