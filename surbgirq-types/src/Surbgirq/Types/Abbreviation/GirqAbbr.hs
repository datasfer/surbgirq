{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}


module Surbgirq.Types.Abbreviation.GirqAbbr
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
import qualified Data.Text       as T


import Surbgirq.Types.Girq
import Surbgirq.Types.Scripture
-- newtype  AbbrMap = Map.Map Text Girq

------------------------------------------------------------
--
------------------------------------------------------------

findByAbbr :: Text -> Maybe (Girq, TranslationID)
findByAbbr name = listToMaybe $ catMaybes $ map (\ (girq, bs) -> findAbbr name girq bs) abbr
                                           -- concatMap (\ (AbbrBook t xs) -> any (==name) xs) abbr
  where
    findAbbr :: Text -> Girq -> [AbbrBook] -> Maybe (Girq, TranslationID)
    findAbbr _ _ [] = Nothing
    findAbbr name girq (AbbrBook t bs:xs) | any (\b -> T.toLower b == T.toLower name) bs = Just (girq, t)
                                          | otherwise = findAbbr name girq xs

data AbbrBook = AbbrBook TranslationID [Text]

-- (Մարկ. 1.1-8, Ղուկ. 3.1-18, Յովհ. 1.19-28, Մատթ. 1.1-3)
abbr :: [(Girq, [AbbrBook])]
abbr = [ -- * New Testament
         (Matthew, mat), (Mark, mark), (Luke, luke), (John, john)
       , (Acts, acts), (James, james), (Peter1, peter1), (Peter2, peter2)
       , (John1, john1), (John2, john2), (John3, john3), (Jude, jude)
       , (Romans, romans), (Corinthians1, cor1), (Corinthians2, cor2), (Galatians, gal)
       , (Ephesians, ephesians), (Philippians, philippians), (Colossians, colossians), (Thessalonians1, thess1)
       , (Thessalonians2, thess2), (Hebrews, hebrews), (Timothy1, tim1), (Timothy2, tim2)
       , (Titus, titus), (Philemon, philemon), (Revelation, rev)

       -- * Old Testament
       , (Genesis, gen)
       -- ^ 1. Ծննդոց
       , (Exodus, exod)
       -- ^ 2. Ելից գիրք
       , (Leviticus, lev)
       -- ^ 3. Ղևտական (Ղևտացվոց գիրք)
       , (Numbers, num)
       -- ^ 4. Թվեր
       , (Deuteronomy, deut)
       -- ^ 5. Երկրորդ օրենք (Երկրորդումն օրինաց)
       , (Joshua, joshua)
       -- ^ 6. Հեսու Նավե (Հեսուի գիրք)
       , (Judges, judg)
       -- ^ 7. Դատավորներ
       , (Ruth, ruth)
       -- ^ 8. Հռութ
       , (Kings1, kings1)
       -- ^ 9. Ա Թագավորություններ
       , (Kings2, kings2)
       -- ^ 10. Բ Թագավորություններ
       , (Kings3, kings3)
       -- ^ 11. Գ Թագավորություններ
       , (Kings4, kings4)
       -- ^ 12. Դ Թագավորություններ
       , (Chronicles1, chron1)
       -- ^ 13. Ա Մնացորդաց
       , (Chronicles2, chron2)
       -- ^ 14. Բ Մնացորդաց
       , (Ezra1, ezra1)
       -- ^ 15. Ա Եզրաս
       , (Ezra2, ezra2)
       -- ^ 16. Բ Եզրաս
       , (Nehemiah, neh)
       -- ^ 17. Նեեմի
       , (Esther, esth)
       -- ^ 18. Եսթեր
       , (Judith, judith)
       -- ^ 19. Հուդիթ
       , (Tobith, tob)
       -- ^ 20. Տոբիթ
       , (Maccabees1, mac1)
       -- ^ 21. Ա Մակաբայեցիներ
       , (Maccabees2, mac2)
       -- ^ 22. Բ Մակաբայեցիներ
       , (Maccabees3, mac3)
       -- ^ 23. Գ Մակաբայեցիներ
       , (Psalms, psalms)
       -- ^ 24. Սաղմոս (Դավթի Սաղմոսներ)
       , (Proverbs, proverbs)
       -- ^ 25. Առակներ
       , (Ecclesiastes, eccles)
       -- ^ 26. Ժողովող
       , (Songs, songs)
       -- ^ 27. Երգ Երգոց
       , (Wisdom, wisdoms)
       -- ^ 28. Իմաստություն Սողոմոնի
       , (Sirach, sirak)
       -- ^ 29. Սիրաքի իմաստություն
       , (Job, job)
       -- ^ 30. Հոբ
       , (Esai, esai)
       -- ^ 31. Եսայու Մարգարեություն
       , (Hosea, hosea)
       -- ^ 32. Օսէէի Մարգարեություն
       , (Amos, amos)
       -- ^ 33. Ամոսի Մարգարեություն
       , (Micah, micah)
       -- ^ 34. Միքիայի Մարգարեություն
       , (Hovel, joel)
       -- ^ 35. Հովելի Մարգարեություն
       , (Abdiu, obad)
       -- ^ 36. Աբդիույի Մարգարեություն
       , (Hovnan, jonah)
       -- ^ 37. Հովնանի Մարգարեություն
       , (Navum, nahum)
       -- ^ 38. Նավումի Մարգարեություն
       , (Habakkuk, hab)
       -- ^ 39. Ամբակումի Մարգարեություն
       , (Sohonia, zeph)
       -- ^ 40. Սոփոնիայի Մարգարեություն
       , (Angei, hag) -- Haggai
       -- ^ 41. Անգեի Մարգարեություն
       , (Zaqaria, zech)
       -- ^ 42. Զաքարիայի Մարգարեություն
       , (Maxaqia, malachi)
       -- ^ 43. Մաղաքիայի Մարգարեություն
       , (Jeremiah, jer)
       -- ^ 44. Երեմիայի Մարգարեություն
       , (Baruq, bar)
       -- ^ 45. Բարուքի Մարգարեություն
       , (Voxb, lam)
       -- ^ 46. Ողբ (Երեմիա Մարգարեի ողբը)
       , (Daniel, dan)
       -- ^ 47. Դանիելի Մարգարեություն
       , (Ezekiel, ezek)
       -- ^ 48. Եզեկիելի Մարգարեություն
       ,  (Narek, narek)
       -- ^ Narek
       ]



mkAbbrBook trans names = AbbrBook trans names

kjvBooks = mkAbbrBook KJVT
v1805Books = mkAbbrBook V1805T
e1994Books = mkAbbrBook E1994T
sinodalBooks = mkAbbrBook E1994T

narek :: [AbbrBook]
narek = [ mkAbbrBook Narek_Xer narek_Xer
        , mkAbbrBook Narek_Grabar narek_Grabar
        , mkAbbrBook Narek_Gev narek_Gev
        , mkAbbrBook Narek_Goch narek_Goch
        ]
  where
    narek_Grabar = ["Նարեկացի"]
    narek_Xer    = ["Նարեկ", "Narek"]
    narek_Gev    = ["Նարեկ-Գեւ"]
    narek_Goch   = ["Նարեկ-Գոչ"]



mat :: [AbbrBook]
mat = [e1994Books matAm, sinodalBooks matRu,  kjvBooks matEn]
  where
    matAm = ["Մատթ.", "Մատթէոս",  "Մատթ", "Մատ", "Մատ.", "Մտ", "Մատթեոս"]
    matEn = ["Matthew", "Mt", "Mat", "Matt","mat", "matt", "mt"]
    matRu = ["Матфея", "Мф"]

mark :: [AbbrBook]
mark = [e1994Books markAm, sinodalBooks markRu, kjvBooks markEn]
  where
    markAm = ["Մրկ.", "Մարկոս", "Մարկ.", "Մարկ", "Մր"]
    markEn = ["Mark", "Mk"]
    markRu = ["Марка", "Мк"]

luke :: [AbbrBook]
luke = [e1994Books lukeAm, sinodalBooks lukeRu, kjvBooks lukeEn]
  where
    lukeAm = ["Ղուկ.", "Ղուկաս", "Ղուկ", "Ղկ"]
    lukeEn = ["Lk", "Luke", "Luk"]
    lukeRu = ["Луки", "Лк"]

john :: [AbbrBook]
john = [e1994Books johnAm, sinodalBooks johnRu, kjvBooks johnEn]
  where
    johnAm = ["Յովհ.", "Յովհաննէս", "Հովհաննես","Հհ", "Հովհ", "Հովհ.", "Յովհ", "Յհ", "Հովհաննես"]
    johnEn = ["John", "Jn"]
    johnRu = ["Иоанн", "Ин"]
acts :: [AbbrBook]
acts = [e1994Books actsAm, sinodalBooks actsRu, kjvBooks actsEn]
  where
    actsAm = ["Գործք", "Գրծ"]
    actsRu = ["Деяния", "Деян"]
    actsEn = ["Acts"]

james :: [AbbrBook]
james = [mkAbbrBook E1994T jamesAm, mkAbbrBook E1994T jamesRu, kjvBooks jamesEn]
  where
    jamesAm = ["Յակոբոս", "Յկ", "Հակոբոս", "Հկ"]
    jamesRu = ["Иаков", " Иакова", "Иак"]
    jamesEn = ["James", "Jas"]


peter1 :: [AbbrBook]
peter1 = [mkAbbrBook E1994T peter1Am, mkAbbrBook E1994T peter1Ru, kjvBooks peter1En]
  where
    peter1Am = ["Ա Պտ", "ԱՊետրոս", "ԱՊտ", "Ա.Պտ", "ՊտԱ"]
    peter1Ru = ["1Петр"]
    peter1En = ["1Peter", "1 Peter",  "1Pet", "Pet1", "Peter1"]

peter2 :: [AbbrBook]
peter2 = [mkAbbrBook E1994T peter2Am, mkAbbrBook E1994T peter2Ru, kjvBooks peter2En]
  where
    peter2Am = ["Բ Պտ", "ԲՊետրոս", "ԲՊտ", "Բ.Պտ"]
    peter2Ru = ["2Петр"]
    peter2En = ["2Peter", "2 Peter", "2Pet", "Pet2", "Peter2"]

john1 :: [AbbrBook]
john1 = [mkAbbrBook E1994T john1Am, mkAbbrBook E1994T john1Ru, kjvBooks john1En]
  where
    john1Am = ["Ա Յովհ.", "ԱՅովհաննէս", "ԱՅովհ", "ԱՅհ", "Ա.Յհ", "Ա Հովհ.", "ԱՀովհաննես", "ԱՀովհ", "ԱՀհ", "Ա.Հհ"]
    john1Ru = ["Иоанн", "1Ин"]
    john1En = ["John1", "1John", "1 John", "1Jn", "Jn1"]

john2 :: [AbbrBook]
john2 = [mkAbbrBook E1994T john2Am, mkAbbrBook E1994T john2Ru, kjvBooks john2En]
  where
    john2Am = ["Բ Յովհ", "ԲՅովհաննէս", "ԲՅովհ", "ԲՅհ", "Բ.Յհ", "Բ Հովհ", "ԲՀովհաննես", "ԲՀովհ", "ԲՀհ", "Բ.Հհ"]
    john2Ru = ["Иоанн", "2Ин"]
    john2En = ["John2", "2John", "2 John", "2Jn", "Jn2"]

john3 :: [AbbrBook]
john3 = [mkAbbrBook E1994T john3Am, mkAbbrBook E1994T john3Ru, kjvBooks john3En]
  where
    john3Am = ["Գ Յովհ", "ԳՅովհաննէս", "ԳՅովհ", "ԳՅհ", "Գ.Յհ", "Գ Հովհ", "ԳՀովհաննես", "ԳՀովհ", "ԳՀհ", "Գ.Հհ"]
    john3Ru = ["Иоанн", "3Ин"]
    john3En = ["John3", "3John", "3 John",  "3Jn", "Jn3"]


jude :: [AbbrBook]
jude = [mkAbbrBook E1994T judeAm, mkAbbrBook E1994T judeRu, kjvBooks judeEn]
  where
    judeAm = ["Յուդա", "Յդ", "Հուդա", "Հդ", "Հուդա առաքյալի ընդհանրական նամակը"]
    judeRu = ["Иуда", "Иуд"]
    judeEn = ["Jude"]

romans :: [AbbrBook]
romans = [mkAbbrBook E1994T romansAm, mkAbbrBook E1994T romansRu, kjvBooks romansEn]
  where
    romansAm = ["Հռոմէացիներին", "Հռոմեացիներին", "Հռոմ", "Հռ"]
    romansRu = ["Римлянам", "Рим"]
    romansEn = ["Romans", "Rom"]

cor1 :: [AbbrBook]
cor1 = [mkAbbrBook E1994T cor1Am, mkAbbrBook E1994T cor1Ru, kjvBooks cor1En]
  where
    cor1Am = ["ԱԿորնթացիներ", "ԱԿորնթացիներին", "ԿորնթացիներԱ", "ԱԿր", "Ա.Կր", "ԿրԱ"]
    cor1Ru = ["1Коринфянам", "1Коринфян", "Коринфянам1", "Коринфян1", "1Кор", "Кор1"]
    cor1En = ["1Corinthians", "1 Corinthians", "1Cor", "Corinthians1", "Cor1"]

cor2 :: [AbbrBook]
cor2 = [mkAbbrBook E1994T cor2Am, mkAbbrBook E1994T cor2Ru, kjvBooks cor2En]
  where
    cor2Am = ["ԲԿորնթացիներ", "ԲԿորնթացիներին", "ԿորնթացիներԲ", "ԲԿր", "Բ.Կր", "ԿրԲ"]
    cor2Ru = ["2Коринфянам", "2Коринфян", "Коринфянам2", "Коринфян2", "2Кор", "Кор2"]
    cor2En = ["2Corinthians", "2 Corinthians", "2Cor", "Corinthians2", "Cor2"]

gal :: [AbbrBook]
gal = [mkAbbrBook E1994T galAm, mkAbbrBook E1994T galRu, kjvBooks galEn]
  where
    galAm = ["Գաղատացիներին", "Գաղ", "Գաղատ", "Գղ"]
    galRu = ["Галатам", "Гал"]
    galEn = ["Galatians", "Gal"]

ephesians :: [AbbrBook]
ephesians = [mkAbbrBook E1994T ephAm, mkAbbrBook E1994T ephRu, kjvBooks ephEn]
  where
    ephAm = ["Եփեսացիներ", "Եփեսացիներին", "Եփես", "Եփ"]
    ephRu = ["Ефесянам", "Еф"]
    ephEn = ["Ephesians", "Eph"]


philippians :: [AbbrBook]
philippians = [mkAbbrBook E1994T philAm, mkAbbrBook E1994T philRu, kjvBooks philEn]
  where
    philAm = ["Փիլիպեցիներ", "Փիլիպեցիներին", "Փիլիպպեցիներ", "Փիլիպպեցիներին", "Փիլիպ", "Փլպ", "Փիլ", "Փպ"]
    philRu = ["Филиппийцам", "Филип", "Фил", "Флп"]
    philEn = ["Philippians", "Phil"]

colossians :: [AbbrBook]
colossians = [mkAbbrBook E1994T colAm, mkAbbrBook E1994T colRu, kjvBooks colEn]
  where
    colAm = ["Կողոսացիներ", "Կողոսացիներին", "Կողոս", "Կող", "Կղ"]
    colRu = ["Колоссянам", "Кол"]
    colEn = ["Colossians", "Col"]

thess1 :: [AbbrBook]
thess1 = [mkAbbrBook E1994T thess1Am, mkAbbrBook E1994T thess1Ru, kjvBooks thess1En]
  where
    thess1Am = ["Ա Թեսաղոնիկեցիներին", "Ա Թեսաղոնիկեցիներ", "Ա Թս", "ԱԹեսաղոնիկեցիներ", "ԱԹեսաղոնիկեցիներին", "ԹեսաղոնիկեցիներԱ", "ԱԹեսաղ", "ԹեսաղԱ", "ԱԹս", "Ա.Թս", "ԹսԱ"]
    thess1Ru = ["1Фессалоникийцам", "1Фес", "Фессалоникийцам1", "Фес1"]
    thess1En = ["1Thessalonians", "1 Thessalonians", "1Thess", "Thessalonians1", "Thess1"]

thess2 :: [AbbrBook]
thess2 = [mkAbbrBook E1994T thess2Am, mkAbbrBook E1994T thess2Ru, kjvBooks thess2En]
  where
    thess2Am = ["Բ Թեսաղոնիկեցիներինին", "Բ Թեսաղոնիկեցիներ", "Բ Թս", "ԲԹեսաղոնիկեցիներ", "ԹեսաղոնիկեցիներԲ", "ԲԹեսաղ", "ԹեսաղԲ", "ԲԹս", "Բ.Թս", "ԹսԲ"]
    thess2Ru = ["2Фессалоникийцам", "2Фес", "Фессалоникийцам2", "Фес2"]
    thess2En = ["2Thessalonians", "2 Thessalonians", "2Thess", "Thessalonians2", "Thess2"]

hebrews :: [AbbrBook]
hebrews = [mkAbbrBook E1994T hebAm, mkAbbrBook E1994T hebRu, kjvBooks hebEn]
  where
    hebAm = ["Եբրայեցիներին", "Եբրայեցիներ", "Եբր", "Եբ"]
    hebRu = ["Евреям", "Евр"]
    hebEn = ["Hebrews", "Heb"]

tim1 :: [AbbrBook]
tim1 = [mkAbbrBook E1994T tim1Am, mkAbbrBook E1994T tim1Ru, kjvBooks tim1En]
  where
    tim1Am = [ "Ա Տիմոթէոսին", "Ա Տիմոթէոս", "ԱՏիմոթէոս", "ԱՏիմ", "ՏիմԱ", "ՏիմոթէոսԱ", "ԱՏմ", "Ա.Տմ", "ՏմԱ"
             , "1Տիմոթէոս", "1Տիմ", "Տիմ1", "Տիմոթէոս1", "1Տմ", "Տմ1"]
    tim1Ru = ["1Тимофею", "1Тим", "Тимофею1", "Тим1"]
    tim1En = ["1Timothy", "1 Timothy", "1Tim", "Timothy1", "Tim1"]

tim2 :: [AbbrBook]
tim2 = [mkAbbrBook E1994T tim2Am, mkAbbrBook E1994T tim2Ru, kjvBooks tim2En]
  where
    tim2Am = [ "Բ Տիմոթէոսին", "Բ Տիմոթէոս", "ԲՏիմոթէոս", "ԲՏիմ", "ՏիմԲ", "ՏիմոթէոսԲ", "ԲՏմ", "ՏմԲ"
             , "2Տիմոթէոս", "2Տիմ", "Տիմ2", "Տիմոթէոս2", "2Տմ", "Տմ2"]
    tim2Ru = ["2Тимофею", "2Тим", "Тимофею2", "Тим2"]
    tim2En = ["2Timothy", "2 Timothy", "2Tim", "Timothy2", "Tim2"]

titus :: [AbbrBook]
titus = [mkAbbrBook E1994T titusAm, mkAbbrBook E1994T titusRu, kjvBooks titusEn]
  where
    titusAm = ["Տիտոս", "Տիտոսին", "Տիտուս", "Տիտ", "Տտ"]
    titusRu = ["Титу", "Тит"]
    titusEn = ["Titus", "Tit"]

philemon :: [AbbrBook]
philemon = [mkAbbrBook E1994T phlmAm, mkAbbrBook E1994T phlmRu, kjvBooks phlmEn]
  where
    phlmAm = ["Փիլիմոնին", "Փիլիմոն", "Փլմ", "Փմ"]
    phlmRu = ["Филимону", "Флм"]
    phlmEn = ["Philemon", "Phlm"]

rev :: [AbbrBook]
rev = [mkAbbrBook E1994T revAm, mkAbbrBook E1994T revRu, kjvBooks revEn]
  where
    revAm = ["Յայտնութիւն", "Յայտ", "Յտ", "Հայտնություն", "Հտ"]
    revRu = ["Апокалипсис","Откровение", "Откр"]
    revEn = ["Revelation", "Rev"]

-- | Old testament
gen :: [AbbrBook]
gen = [e1994Books genAm, sinodalBooks genRu, kjvBooks genEn]
  where
    genAm = ["Ծննդոց", "Ծննդ", "Ծննդ."]
    genRu = ["Бытия","Быт"]
    genEn = ["Genesis", "Gen"]


exod :: [AbbrBook]
exod = [e1994Books exodAm, sinodalBooks exodRu, kjvBooks exodEn]
  where
    exodAm = ["Ելք", "Ելից"]
    exodRu = ["Исход","Исх"]
    exodEn = ["Exodus", "Exod", "Ex" ]

lev :: [AbbrBook]
lev = [e1994Books levAm, v1805Books levGr,  sinodalBooks levRu, kjvBooks levEn]
  where
    levGr = []
    levAm = ["Ղևտական","Ղեւտական", "Ղևտացվոց", "Ղեւտացվոց", "Ղևտ", "Ղեւտ" ]
    levRu = ["Левит","Лев"]
    levEn = ["Leviticus", "Lev"]

num :: [AbbrBook]
num = [e1994Books numAm, v1805Books numGr,  sinodalBooks numRu, kjvBooks numEn]
  where
    numGr = []
    numAm = ["Թվեր", "Թուեր"]
    numRu = ["Чисел","Числ"]
    numEn = ["Numbers", "Nums", "Num"]

deut :: [AbbrBook]
deut = [e1994Books deutAm, v1805Books deutGr, sinodalBooks deutRu, kjvBooks deutEn]
  where
    deutGr = ["Ա Օրէնք"]
    deutAm = ["Ա Օրենք", "Ա Օր", "Երկրորդ Օրենք", "2Օրենք", "2Օր", "Օրենք2", "Օր2"]
    deutRu = ["Второзаконие","Втор"]
    deutEn = ["Deuteronomy", "Deut", "Deuteronomium"]


joshua :: [AbbrBook]
joshua = [e1994Books joshuaAm, v1805Books joshuaGr,  sinodalBooks joshuaRu, kjvBooks joshuaEn]
  where
    joshuaGr = []
    joshuaAm = ["Հեսու" ]
    joshuaRu = ["Навин", "Иисус Навин", "ИсНав"]
    joshuaEn = ["Joshua", "Josh"]


judg :: [AbbrBook]
judg = [e1994Books judgAm, v1805Books judgGr, sinodalBooks judgRu, kjvBooks judgEn]
  where
    judgGr = ["Դատաւորներ"]
    judgAm = ["Դատավորներ", "Դատավոր", "Դատ"]
    judgRu = ["Судей","Суд"]
    judgEn = ["Judges", "Judg"]


ruth :: [AbbrBook]
ruth = [e1994Books ruthAm, v1805Books ruthGr, sinodalBooks ruthRu, kjvBooks ruthEn]
  where
    ruthGr = []
    ruthAm = ["Հռութ"]
    ruthRu = ["Книга Руфь", "Руфь","Руф"]
    ruthEn = ["Ruth"]

kings1 :: [AbbrBook]
kings1 = [e1994Books kgsAm, v1805Books kgsGr, sinodalBooks kgsRu, kjvBooks kgsEn]
    where
    kgsGr = ["Թագաւորութիւններ Ա"]
    kgsAm = ["Ա Թագ", "ԱԹագ", "ԹագԱ", "Թագ Ա"]
    kgsRu = ["Первая книга Царств","1 Цар", "1Цар", "Цар1"]
    kgsEn = ["1Kings", "1 Kings", "1Samuel", "1 Samuel", "1Sam", "Kings1"]


kings2 :: [AbbrBook]
kings2 = [e1994Books kgsAm, v1805Books kgsGr, sinodalBooks kgsRu, kjvBooks kgsEn]
  where
    kgsGr = ["Թագաւորութիւններ Բ"]
    kgsAm = ["Բ Թագ", "ԲԹագ", "ԹագԲ", "Թագ Բ"]
    kgsRu = ["Вторая книга Царств","2 Цар", "2Цар", "Цар2"]
    kgsEn = ["2Kings", "2 Kings", "2Samuel", "2 Samuel", "2Sam", "Kings2"]


kings3 :: [AbbrBook]
kings3 = [e1994Books kgsAm, v1805Books kgsGr, sinodalBooks kgsRu, kjvBooks kgsEn]
  where
    kgsGr = ["Թագաւորութիւններ Գ"]
    kgsAm = ["Գ Թագ", "ԳԹագ", "ԹագԳ", "Թագ Գ"]
    kgsRu = ["Третья книга Царств","3 Цар", "3Цар", "Цар3"]
    kgsEn = ["3Kings", "3 Kings", "3Samuel", "3 Samuel", "3Sam", "Kings3"]


kings4 :: [AbbrBook]
kings4 = [e1994Books kgsAm, v1805Books kgsGr, sinodalBooks kgsRu, kjvBooks kgsEn]
  where
    kgsGr = ["Թագաւորութիւններ Դ"]
    kgsAm = ["Դ Թագ", "ԴԹագ", "ԹագԴ", "Թագ Դ"]
    kgsRu = ["Четвертая книга Царств","4 Цар", "4Цар", "Цар4"]
    kgsEn = ["4Kings", "4 Kings", "4 Samuel", "4Samuel", "4Sam", "Kings4"]


chron1 :: [AbbrBook]
chron1 = [e1994Books chronAm, v1805Books chronGr, sinodalBooks chronRu, kjvBooks chronEn]
  where
    chronGr = ["Ա Մնացորդաց"]
    chronAm = ["Ա Մնաց", "Ա Մն", "Մն Ա" ]
    chronRu = ["Первая книга Паралипоменон","1 Пар", "1Пар", "Пар1"]
    chronEn = ["1 Chron", "1Chronicles", "1 Chronicles", "Chronicles1"]


chron2 :: [AbbrBook]
chron2 = [e1994Books chronAm, v1805Books chronGr, sinodalBooks chronRu, kjvBooks chronEn]
  where
    chronGr = ["Բ Մնացորդաց"]
    chronAm = ["Բ Մնաց", "Բ Մն", "Մն Բ" ]
    chronRu = ["Вторая книга Паралипоменон","2 Пар", "2Пар", "Пар2"]
    chronEn = ["2 Chron", "2Chronicles", "2 Chronicles", "Chronicles2"]



ezra1 :: [AbbrBook]
ezra1 = [e1994Books ezraAm, v1805Books ezraGr, sinodalBooks ezraRu, kjvBooks ezraEn]
  where
    ezraGr = [""]
    ezraAm = ["Ա Եզրաս", "Ա Եզր"]
    ezraRu = ["Первая книга Ездры","1 Езд", "1Езд", "Езд1"]
    ezraEn = ["1Ezra", "1Esdras", "Ezra1", "Ezra 1"]


ezra2 :: [AbbrBook]
ezra2 = [e1994Books ezraAm, v1805Books ezraGr, sinodalBooks ezraRu, kjvBooks ezraEn]
  where
    ezraGr = [""]
    ezraAm = ["Բ Եզրաս", "Բ Եզր", "ԲԵզր", "ԵզրԲ", "Եզր Բ" ]
    ezraRu = ["Вторая книга Ездры","2 Езд", "2Езд", "Езд2"]
    ezraEn = ["2Ezra","Ezra", "2Esdras", "Ezra 2", "Ezra2"]

neh :: [AbbrBook]
neh = [e1994Books nehAm, v1805Books nehGr, sinodalBooks nehRu, kjvBooks nehEn]
  where
    nehGr = [""]
    nehAm = ["Նէեմի", "Նմ"]
    nehRu = ["Книга Неемии","Нееми", "Неем"]
    nehEn = ["Nehemiah", "Neh"]

esth :: [AbbrBook]
esth = [e1994Books esthAm, v1805Books esthGr, sinodalBooks esthRu, kjvBooks esthEn]
  where
    esthGr = [""]
    esthAm = ["Եսթեր", "Եսթ"]
    esthRu = ["Книга Есфирь","Есфирь", "Есф", "Есфир"]
    esthEn = ["Esther", "Esth"]


judith :: [AbbrBook]
judith = [e1994Books judithAm, v1805Books judithGr, sinodalBooks judithRu, kjvBooks judithEn]
  where
    judithGr = [""]
    judithAm = ["Յուդիթ", "Յդթ"]
    judithRu = ["Книга Иудифь","Иудифь", "Иудиф"]
    judithEn = ["Judith", "Jdh"]


tob :: [AbbrBook]
tob = [e1994Books tobAm, v1805Books tobGr, sinodalBooks tobRu, kjvBooks tobEn]
  where
    tobGr = [""]
    tobAm = ["Տոբիթ", "Տոբ"]
    tobRu = ["Книга Товита","Товит", "Тов"]
    tobEn = ["Tobit", "Tob", "Tobith"]


mac1 :: [AbbrBook]
mac1 = [e1994Books macAm, v1805Books macGr, sinodalBooks macRu, kjvBooks macEn]
  where
    macGr = [""]
    macAm = ["Ա Մակաբայեցիներ", "Ա Մկ", "ԱՄկ", "ՄկԱ" ]
    macRu = ["Первая книга Маккавейская","1 Макк", "1Макк", "Макк 1", "Макк1"]
    macEn = ["1 Maccabees",  "1 Mac", "Mac1", "1Mac", "Maccabees1", "Makabai1"]


mac2 :: [AbbrBook]
mac2 = [e1994Books macAm, v1805Books macGr, sinodalBooks macRu, kjvBooks macEn]
  where
    macGr = [""]
    macAm = ["Բ Մակաբայեցիներ", "Բ Մկ", "ԲՄկ", "ՄկԲ"]
    macRu = ["Первая книга Маккавейская","2 Макк", "2Макк", "Макк 2", "Макк2"]
    macEn = ["2 Maccabees", "2 Mac", "Mac2", "2Mac", "Maccabees2", "Makabai2"]

mac3 :: [AbbrBook]
mac3 = [e1994Books macAm, v1805Books macGr, sinodalBooks macRu, kjvBooks macEn]
  where
    macGr = [""]
    macAm = ["Դ Մակաբայեցիներ", "Դ Մկ", "ԴՄկ", "ՄկԴ"]
    macRu = ["Первая книга Маккавейская","3 Макк", "3Макк", "Макк 3", "Макк3"]
    macEn = ["3 Maccabees", "3 Mac", "Maccabees3", "Mac3", "3Mac", "Makabai3"]


psalms :: [AbbrBook]
psalms = [e1994Books psalmAm, v1805Books psalmGr, sinodalBooks psalmRu, kjvBooks psalmEn]
  where
    psalmGr = [""]
    psalmAm = ["Սաղմոս", "Սղ"]
    psalmRu = ["Псалтирь", "Пс"]
    psalmEn = ["Psalms", "Ps"]


proverbs :: [AbbrBook]
proverbs = [e1994Books proverbAm, v1805Books proverbGr, sinodalBooks proverbRu, kjvBooks proverbEn]
  where
    proverbGr = [""]
    proverbAm = ["Առակներ", "Առ"]
    proverbRu = ["Книга Притчей Соломоновых", "Притч"]
    proverbEn = ["Proverbs", "Prov"]

eccles :: [AbbrBook]
eccles = [e1994Books ecclesAm, v1805Books ecclesGr, sinodalBooks ecclesRu, kjvBooks ecclesEn]
  where
    ecclesGr = [""]
    ecclesAm = ["Ժողովող", "Ժող"]
    ecclesRu = ["Книга Екклесиаста", "Екклесиаст", "Еккл"]
    ecclesEn = ["Ecclesiastes", "Eccles"]


songs :: [AbbrBook]
songs = [e1994Books songAm, v1805Books songGr, sinodalBooks songRu, kjvBooks songEn]
  where
    songGr = [""]
    songAm = ["Երգ Երգոց", "Երգոց"]
    songRu = ["Книга Песни Песней Соломона", "Песни Песней"]
    songEn = ["Song of Solomon", "Song", "Songs"]

wisdoms :: [AbbrBook]
wisdoms = [e1994Books wisdomAm, v1805Books wisdomGr, sinodalBooks wisdomRu, kjvBooks wisdomEn]
  where
    wisdomGr = [""]
    wisdomAm = ["Իմաստութիւն Սողոմոնի", "Իմաստութիւն"]
    wisdomRu = ["Книга Песни Песней Соломона", "Песни Песней"]
    wisdomEn = ["Wisdoms", "Wisdom", "Wis"]



sirak :: [AbbrBook]
sirak = [e1994Books sirakAm, v1805Books sirakGr, sinodalBooks sirakRu, kjvBooks sirakEn]
  where
    sirakGr = [""]
    sirakAm = ["Սիրաք", "Սր"]
    sirakRu = ["Книга Премудрости Иисуса сына Сирахова", "Сир"]
    sirakEn = ["Sirak", "Sirach", "Sir"]


job :: [AbbrBook]
job = [e1994Books jobAm, v1805Books jobGr, sinodalBooks jobRu, kjvBooks jobEn]
  where
    jobGr = [""]
    jobAm = ["Յոբ"]
    jobRu = ["Книга Иова", "Иов"]
    jobEn = ["Job"]


esai :: [AbbrBook]
esai = [e1994Books esaiAm, v1805Books esaiGr, sinodalBooks esaiRu, kjvBooks esaiEn]
  where
    esaiGr = [""]
    esaiAm = ["Եսայի", "Ես"]
    esaiRu = ["Книга пророка Исаии", "Ис"]
    esaiEn = ["Isaiah", "Is", "Isa", "Esai"]


hosea :: [AbbrBook]
hosea = [e1994Books hosAm, v1805Books hosGr, sinodalBooks hosRu, kjvBooks hosEn]
  where
    hosGr = [""]
    hosAm = ["Օսէէ", "Ովս"]
    hosRu = ["Книга пророка Осии", "Оси", "Ос"]
    hosEn = ["Hosea", "Hos"]


amos :: [AbbrBook]
amos = [e1994Books amosAm, v1805Books amosGr, sinodalBooks amosRu, kjvBooks amosEn]
  where
    amosGr = [""]
    amosAm = ["Ամոս", "Ամս"]
    amosRu = ["Книга пророка Амоса", "Ам"]
    amosEn = ["Amos"]

micah :: [AbbrBook]
micah = [e1994Books micahAm, v1805Books micahGr, sinodalBooks micahRu, kjvBooks micahEn]
  where
    micahGr = [""]
    micahAm = ["Միքիա", "Մք"]
    micahRu = ["Книга пророка Михея", "Мих"]
    micahEn = ["Micah", "Mic"]


joel :: [AbbrBook]
joel = [e1994Books joelAm, v1805Books joelGr, sinodalBooks joelRu, kjvBooks joelEn]
  where
    joelGr = [""]
    joelAm = ["Յովել", "Յվլ"]
    joelRu = ["Книга пророка Иоиля", "Иоил"]
    joelEn = ["Joel", "Hovel"]


obad :: [AbbrBook]
obad = [e1994Books obadAm, v1805Books obadGr, sinodalBooks obadRu, kjvBooks obadEn]
  where
    obadGr = [""]
    obadAm = ["Աբդիու", "Աբդ"]
    obadRu = ["Книга пророка Авдия", "Авд"]
    obadEn = ["Obadiah", "Obad", "Abdiu"]


jonah :: [AbbrBook]
jonah = [e1994Books jonahAm, v1805Books jonahGr, sinodalBooks jonahRu, kjvBooks jonahEn]
  where
    jonahGr = [""]
    jonahAm = ["Յովնան", "Յն"]
    jonahRu = ["Книга пророка Ионы", "Ион"]
    jonahEn = ["Jonah", "Jon", "Hovnan"]


nahum :: [AbbrBook]
nahum = [e1994Books nahumAm, v1805Books nahumGr, sinodalBooks nahumRu, kjvBooks nahumEn]
  where
    nahumGr = [""]
    nahumAm = ["Նաւում", "Նւ"]
    nahumRu = ["Книга пророка Наума", "Наум"]
    nahumEn = ["Nahum", "Nah", "Navum"]


hab :: [AbbrBook]
hab = [e1994Books habAm, v1805Books habGr, sinodalBooks habRu, kjvBooks habEn]
  where
    habGr = [""]
    habAm = ["Ամբակում", "Ամբ"]
    habRu = ["Книга пророка Аввакума", "Авв"]
    habEn = ["Habakkuk", "Hab"]


zeph :: [AbbrBook]
zeph = [e1994Books zephAm, v1805Books zephGr, sinodalBooks zephRu, kjvBooks zephEn]
  where
    zephGr = [""]
    zephAm = ["Սոփոնիա", "Սփ"]
    zephRu = ["Книга пророка Софонии", "Соф"]
    zephEn = ["Zephaniah", "Zeph", "Sohonia"]


hag :: [AbbrBook]
hag = [e1994Books hagAm, v1805Books hagGr, sinodalBooks hagRu, kjvBooks hagEn]
  where
    hagGr = [""]
    hagAm = ["Անգէ", "Անգ"]
    hagRu = ["Книга пророка Аггея", "Агг"]
    hagEn = ["Haggai", "Hag", "Angei"]


zech :: [AbbrBook]
zech = [e1994Books zechAm, v1805Books zechGr, sinodalBooks zechRu, kjvBooks zechEn]
  where
    zechGr = [""]
    zechAm = ["Զաքարիա", "Զք"]
    zechRu = ["Книга пророка Захарии", "Зах"]
    zechEn = ["Zechariah", "Zech", "Zaqaria"]

malachi :: [AbbrBook]
malachi = [e1994Books malachiAm, v1805Books malachiGr, sinodalBooks malachiRu, kjvBooks malachiEn]
  where
    malachiGr = []
    malachiAm = ["Մաղաքիա", "Մղ"]
    malachiRu = ["Книга пророка Малахии", "Мал"]
    malachiEn = ["Malachi", "Mal", "Maxaqia"]


jer :: [AbbrBook]
jer = [e1994Books jerAm, v1805Books jerGr, sinodalBooks jerRu, kjvBooks jerEn]
  where
    jerGr = [""]
    jerAm = ["Երեմիա", "եր"]
    jerRu = ["Книга пророка Иеремии", "Иер"]
    jerEn = ["Jeremiah", "Jer"]


bar :: [AbbrBook]
bar = [e1994Books barAm, v1805Books barGr, sinodalBooks barRu, kjvBooks barEn]
  where
    barGr = [""]
    barAm = ["Բարուք", "Բրք"]
    barRu = ["Книга пророка Варуха", "Вар"]
    barEn = ["Baruk", "Bar", "Baruq"]


lam :: [AbbrBook]
lam = [e1994Books lamAm, v1805Books lamGr, sinodalBooks lamRu, kjvBooks lamEn]
  where
    lamGr = [""]
    lamAm = ["Ողբ"]
    lamRu = ["Книга плач Иеремии", "Плач"]
    lamEn = ["Lamentations", "Lam", "Voxb"]


dan :: [AbbrBook]
dan = [e1994Books danAm, v1805Books danGr, sinodalBooks danRu, kjvBooks danEn]
  where
    danGr = [""]
    danAm = ["Դանիէլ", "Դն"]
    danRu = ["Книга пророка Даниила", "Дан"]
    danEn = ["Daniel", "Dan"]


ezek :: [AbbrBook]
ezek = [e1994Books ezekAm, v1805Books ezekGr, sinodalBooks ezekRu, kjvBooks ezekEn]
  where
    ezekGr = [""]
    ezekAm = ["Եզեկիէլ", "Եզկ"]
    ezekRu = ["Книга пророка Иезекииля", "Иез"]
    ezekEn = ["Ezekiel", "Ezek"]














-- (Մատթ. 3.1-12, Ղուկ. 3.1-18, Յովհ. 1.19-28


-- | book name for verse
getBookName :: Girq -> TranslationID -> Maybe Text
getBookName girq translation =
    let xs  = filter (\(g,bs) -> g == girq) abbr
    in case xs of
         ((_, bookAbbrs):_) -> head $ getAbbrNames <$> filter (\(AbbrBook t _) -> t == translation) bookAbbrs
         []                 -> Nothing
  where
    getAbbrNames (AbbrBook _ ns) = listToMaybe $ ns

getTranslationName :: TranslationID -> Text
getTranslationName transID =
    case transID of
      E1994T       -> "«Էջմիածին» 1994թ."
      E2004T       -> "«Էջմիածին»(Նոր) 2004թ."
      V1805T       -> "«Վէնէտիկ» 1805թ."
      SinodalT     -> "sINODAL"
      KJVT         -> "KJV 1611թ."
      Narek_Grabar -> "Նարեկ"
      Narek_Xer    -> "Նարեկ"
      Narek_Gev    -> "Նարեկ"
      Narek_Goch   -> "Նարեկ"

toRefText :: TranslationID -> VerseReference -> Text
toRefText defTrans VerseReference{..} =
   let translation = fromMaybe defTrans verseRef'translation
       girq = case getBookName verseRef'book translation of
                Nothing -> [qc|{verseRef'book}|]
                Just g  -> g
       transName = fromMaybe "" (getTranslationName <$> verseRef'translation)
   in case (verseRef'from, verseRef'to) of
        (Nothing, Nothing)   -> [qc|{girq} {verseRef'chapter}, {transName}|]
        (Just from, Nothing) -> [qc|{girq} {verseRef'chapter}:{from}, {transName}|]
        (Just from, Just to) -> [qc|{girq} {verseRef'chapter}.{from}-{to}, {transName}|]
        (Nothing, Just to)   -> [qc|{girq} {verseRef'chapter}:{to}, {transName}|]
