{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}


module Surbgirq.Utils.Scripture.Abbr
    ( findByAbbr
    , toRefText
    )
    where

import Common.Aeson
import Data.Aeson   (Value)
import Data.Maybe
import Data.Text    (Text)
import GHC.Generics

import Prelude hiding (lookup)

import Data.Map.Strict               (Map)
import Text.InterpolatedString.Perl6 (qc)

import qualified Data.Map.Strict as Map


import Surbgirq.Types
import Surbgirq.Types

-- newtype  AbbrMap = Map.Map Text Girq


findByAbbr :: Text -> Maybe Girq
findByAbbr name = listToMaybe $ fst <$> filter (\ (girq, xs) ->  any (==name) xs) abbr


-- (Մարկ. 1.1-8, Ղուկ. 3.1-18, Յովհ. 1.19-28, Մատթ. 1.1-3)
abbr :: [(Girq, [Text])]
abbr = [ (Matthew, mat)
       , (Mark, mark)
       , (Luke, luke)
       , (John, ["Յովհաննէս", "Հովհաննես", "Հովհ", "Հովհ.", "Յովհ.", "Յովհ", "Յհ", "John", "john"])
       , (Acts, ["Գրծ", "Acts"])
       , (James, ["Յկ", "Jas", "James" ])
       , (Peter1, ["Ա Պտ", "Peter1", "1Pet", "Pet1"])
       , (Peter2, ["Բ Պտ", "Peter2", "2Pet"])
       , (John1, ["Ա Յհ", "ohn1", "1John"])
       , (John2, ["Բ Յհ", "ohn2", "2John"])
       , (John3, ["Գ Յհ", "ohn3", "3John"])
       , (Jude, ["Յդ", "Jude"])
       , (Romans, ["Հռ", "Romans",  "Rom"])
       , (Corinthians1, ["Ա Կր", "Corinthians1", "1Cor"])
       , (Corinthians2, ["Բ Կր", "Corinthians2", "2Cor"])
       , (Galatians, ["Գղ", "Galatians", "Gal"])
       , (Ephesians, ["Եփ", "Ephesians", "Eph"])
       , (Philippians, ["Փպ", "Philippians", "Phil"])
       , (Colossians, ["Կղ", "Colossians", "Col"])
       , (Thessalonians1, ["Ա Թս", "Thessalonians1"])
       , (Thessalonians2, ["Բ Թս", "Thessalonians2"])
       , (Hebrews, ["Եբ", "Hebrews", "Heb"])
       , (Timothy1, ["Ա Տմ", "1Tim", "Timothy1"])
       , (Timothy2, ["Բ Տմ", "2Tim", "Timothy2"])
       , (Titus, ["Տտ", "Titus"])
       , (Philemon, ["Փմ", "Phlm", "Philemon"])
       , (Revelation, ["Յտ", "Rev", "Revelation"])
       -- * Old Testament
       , (Genesis, ["Gen", "Gen", "Ծննդոց", "Ծննդ", "Ծննդ.", "Gen"])
       -- ^ 1. Ծննդոց
       , (Exodus, ["Ելք", "Exodus", "Exod", "Ex" ])
       -- ^ 2. Ելից գիրք
       , (Leviticus, ["Ղևտական", "Ղևտացվոց", "Ղևտ", "Ղեւտ", "Leviticus", "Lev" ])
       -- ^ 3. Ղևտական (Ղևտացվոց գիրք)
       , (Numbers, ["Թվեր", "Թուեր", "Numbers", "Nums", "Num"])
       -- ^ 4. Թվեր
       , (Deuteronomium, ["օրենք2", "օր2", "Deuteronomy", "Deut"])
       -- ^ 5. Երկրորդ օրենք (Երկրորդումն օրինաց)
       , (Joshua, ["Հեսու", "Joshua", "Josh"])
       -- ^ 6. Հեսու Նավե (Հեսուի գիրք)
       , (Judges, ["Դատավորներ", "Դատավոր", "Դատ", "Judges", "Judg" ])
       -- ^ 7. Դատավորներ
       , (Ruth, ["Հռութ", "Ruth"])
       -- ^ 8. Հռութ
       , (Kings1, ["ԱԹագ", "ԹագԱ", "Kings1"])
       -- ^ 9. Ա Թագավորություններ
       , (Kings2, ["ԲԹագ", "ԹագԲ", "Kings2"])
       -- ^ 10. Բ Թագավորություններ
       , (Kings3, ["ԳԹագ", "ԹագԳ"])
       -- ^ 11. Գ Թագավորություններ
       , (Kings4, [])
       -- ^ 12. Դ Թագավորություններ
       , (Chronicles1, [])
       -- ^ 13. Ա Մնացորդաց
       , (Chronicles2, [])
       -- ^ 14. Բ Մնացորդաց
       , (Ezra1, [])
       -- ^ 15. Ա Եզրաս
       , (Ezra2, [])
       -- ^ 16. Բ Եզրաս
       , (Nehemiah, [])
       -- ^ 17. Նեեմի
       , (Esther, [])
       -- ^ 18. Եսթեր
       , (Judith, [])
       -- ^ 19. Հուդիթ
       , (Tobith, [])
       -- ^ 20. Տոբիթ
       , (Makabai1, [])
       -- ^ 21. Ա Մակաբայեցիներ
       , (Makabai2, [])
       -- ^ 22. Բ Մակաբայեցիներ
       , (Makabai3, [])
       -- ^ 23. Գ Մակաբայեցիներ
       , (Psalms, [])
       -- ^ 24. Սաղմոս (Դավթի Սաղմոսներ)
       , (Proverbs, [])
       -- ^ 25. Առակներ
       , (Ecclesiastes, [])
       -- ^ 26. Ժողովող
       , (Songs, [])
       -- ^ 27. Երգ Երգոց
       , (Wisdom, [])
       -- ^ 28. Իմաստություն Սողոմոնի
       , (Sirach, [])
       -- ^ 29. Սիրաքի իմաստություն
       , (Job, [])
       -- ^ 30. Հոբ
       , (Esai, [])
       -- ^ 31. Եսայու Մարգարեություն
       , (Hosea, [])
       -- ^ 32. Օսէէի Մարգարեություն
       , (Amos, [])
       -- ^ 33. Ամոսի Մարգարեություն
       , (Micah, [])
       -- ^ 34. Միքիայի Մարգարեություն
       , (Hovel, [])
       -- ^ 35. Հովելի Մարգարեություն
       , (Abdiu, [])
       -- ^ 36. Աբդիույի Մարգարեություն
       , (Hovnan, [])
       -- ^ 37. Հովնանի Մարգարեություն
       , (Navum, [])
       -- ^ 38. Նավումի Մարգարեություն
       , (Habakkuk, [])
       -- ^ 39. Ամբակումի Մարգարեություն
       , (Sohonia, [])
       -- ^ 40. Սոփոնիայի Մարգարեություն
       , (Angei, [])
       -- ^ 41. Անգեի Մարգարեություն
       , (Zaqaria, [])
       -- ^ 42. Զաքարիայի Մարգարեություն
       , (Maxaqia, [])
       -- ^ 43. Մաղաքիայի Մարգարեություն
       , (Jeremiah, [])
       -- ^ 44. Երեմիայի Մարգարեություն
       , (Baruq, [])
       -- ^ 45. Բարուքի Մարգարեություն
       , (Voxb, [])
       -- ^ 46. Ողբ (Երեմիա Մարգարեի ողբը)
       , (Daniel, [])
       -- ^ 47. Դանիելի Մարգարեություն
       , (Ezekiel, [])
       -- ^ 48. Եզեկիելի Մարգարեություն
       ]


mat :: [Text]
mat = matAm ++ matRu ++ matEn
  where
    matAm = ["Մատթէոս", "Մատթ.", "Մատթ", "Մտ"]
    matEn = ["Matthew", "Mt", "Mat", "Matt","mat", "matt", "mt"]
    matRu = []

mark :: [Text]
mark = markAm ++ markRu ++ markEn
  where
    markAm = ["Մարկոս", "Մարկ.", "Մարկ", "Մր"]
    markEn = ["Mark", "Mk"]
    markRu = []

luke :: [Text]
luke = lukeAm ++ lukeRu ++ lukeEn
  where
    lukeAm = ["Ղուկաս", "Ղուկ.", "Ղուկ", "Ղկ"]
    lukeEn = ["Lk", "Luke", "Luk"]
    lukeRu = []

john :: [Text]
john = johnAm ++ johnRu ++ johnEn
  where
    johnAm = ["Յովհաննէս", "Հովհաննես", "Հովհ", "Հովհ.",   "Յովհ.", "Յովհ", "Յհ"]
    johnEn = ["John"]
    johnRu = []


-- (  Մատթ. 3.1-12, Ղուկ. 3.1-18, Յովհ. 1.19-28
abbrBooksAm :: Map Girq String -- AbbrMap
abbrBooksAm = Map.fromList
            [ (Matthew, "Մատթ.")
            , (Mark, "Մարկ.")
            , (Luke, "Ղուկ.")
            , (John, "Յովհ.")]



toRefText VerseReference{..} =
   let girq = case Map.lookup verseRef'book abbrBooksAm of
                Nothing -> [qc|{verseRef'book}|]
                Just g  -> g
   in case (verseRef'from, verseRef'to) of
        (Nothing, Nothing)   -> [qc|{girq} {verseRef'chapter}|]
        (Just from, Nothing) -> [qc|{girq} {verseRef'chapter}:{from}|]
        (Just from, Just to) -> [qc|{girq} {verseRef'chapter}.{from}-{to}|]
        (Nothing, Just to)   ->  [qc|{girq} {verseRef'chapter}:{to}|]
