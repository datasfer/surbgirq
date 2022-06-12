{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}

module Surbgirq.Types.Girq where

import Data.Aeson
import GHC.Generics

import Data.Aeson (Value)
import Data.Text  (Text)

import qualified Data.Text as T
import qualified Text.Read as T

------------------------------------------------------------
--
------------------------------------------------------------

data Girq =
          -- Հնգամատյան (Tora - օրենք)

          Genesis
          -- ^ 1. Ծննդոց
          | Exodus
          -- ^ 2. Ելից գիրք
          | Leviticus
          -- ^ 3. Ղևտական (Ղևտացվոց գիրք)
          | Numbers
          -- ^ 4. Թվեր
          | Deuteronomy
          -- ^ 5. Երկրորդ օրենք (Երկրորդումն օրինաց)

          --
          | Joshua
          -- ^ 6. Հեսու Նավե (Հեսուի գիրք)
          | Judges
          -- ^ 7. Դատավորներ
          | Ruth
          -- ^ 8. Հռութ
          | Kings1
          -- ^ 9. Ա Թագավորություններ
          | Kings2
          -- ^ 10. Բ Թագավորություններ
          | Kings3
          -- ^ 11. Գ Թագավորություններ
          | Kings4
          -- ^ 12. Դ Թագավորություններ

          | Chronicles1
          -- ^ 13. Ա Մնացորդաց
          | Chronicles2
          -- ^ 14. Բ Մնացորդաց
          | Ezra1
          -- ^ 15. Ա Եզրաս
          | Ezra2
          -- ^ 16. Բ Եզրաս
          | Nehemiah
          -- ^ 17. Նեեմի
          | Esther
          -- ^ 18. Եսթեր
          | Judith
          -- ^ 19. Հուդիթ
          | Tobith
          -- ^ 20. Տոբիթ
          | Maccabees1
          -- ^ 21. Ա Մակաբայեցիներ
          | Maccabees2
          -- ^ 22. Բ Մակաբայեցիներ
          | Maccabees3
          -- ^ 23. Գ Մակաբայեցիներ
          | Psalms
          -- ^ 24. Սաղմոս (Դավթի Սաղմոսներ)
          | Proverbs
          -- ^ 25. Առակներ
          | Ecclesiastes
          -- ^ 26. Ժողովող
          | Songs
          -- ^ 27. Երգ Երգոց
          | Wisdom
          -- ^ 28. Իմաստություն Սողոմոնի
          | Sirach -- Sirak
          -- ^ 29. Սիրաքի իմաստություն
          | Job
          -- ^ 30. Հոբ

          | Esai -- Isaiah
          -- ^ 31. Եսայու Մարգարեություն
          | Hosea
          -- ^ 32. Օսէէի Մարգարեություն
          | Amos
          -- ^ 33. Ամոսի Մարգարեություն
          | Micah --
          -- ^ 34. Միքիայի Մարգարեություն
          | Hovel -- Joel
          -- ^ 35. Հովելի Մարգարեություն
          | Abdiu -- Obadiah
          -- ^ 36. Աբդիույի Մարգարեություն
          | Hovnan -- Jonah
          -- ^ 37. Հովնանի Մարգարեություն
          | Navum -- Nahum
          -- ^ 38. Նավումի Մարգարեություն
          | Habakkuk --
          -- ^ 39. Ամբակումի Մարգարեություն
          | Sohonia -- Zephaniah
          -- ^ 40. Սոփոնիայի Մարգարեություն
          | Angei -- Haggai
          -- ^ 41. Անգեի Մարգարեություն
          | Zaqaria -- Zechariah
          -- ^ 42. Զաքարիայի Մարգարեություն
          | Maxaqia -- Malachi
          -- ^ 43. Մաղաքիայի Մարգարեություն
          | Jeremiah
          -- ^ 44. Երեմիայի Մարգարեություն
          | Baruq -- Baruk
          -- ^ 45. Բարուքի Մարգարեություն
          | Voxb
          -- ^ 46. Ողբ (Երեմիա Մարգարեի ողբը)
          | Daniel
          -- ^ 47. Դանիելի Մարգարեություն
          | Ezekiel
          -- ^ 48. Եզեկիելի Մարգարեություն


          -- Նոր Կտակարան
          | Matthew
          -- ^ 1. Ավետարան ըստ Մատթեոսի
          | Mark
          -- ^ 2. Ավետարան ըստ Մարկոսի
          | Luke
          -- ^ 3. Ավետարան ըստ Ղուկասի
          | John
          -- ^ 4. Ավետարան ըստ Հովհաննեսի
          | Acts
          -- ^ 5. Գործք առաքելոց
          | James
          | Peter1
          | Peter2
          | John1
          | John2
          | John3
          | Jude
          | Romans
          | Corinthians1
          | Corinthians2
          | Galatians
          | Ephesians
          | Philippians
          | Colossians
          | Thessalonians1
          | Thessalonians2
          | Hebrews
          | Timothy1
          | Timothy2
          | Titus
          | Philemon
          | Revelation

          | Narek

            deriving(Show, Eq, Generic, Read, Enum, Ord)



-- ^ Պողոս առաքյալի նամակը Հռոմեացիներին
-- ^ Պողոս առաքյալի առաջին նամակը Կորնթացիներին (Ա Կորնթացիներ)
-- ^ Պողոս առաքյալի երկրորդ նամակը Կորնթացիներին (Բ Կորնթացիներ)
-- ^ Պողոս առաքյալի նամակը գաղատացիներին
-- ^ Պողոս առաքյալի նամակը եփեսացիներին
-- ^ Պողոս առաքյալի նամակը փիլիպեցիներին
-- ^ Պողոս առաքյալի նամակը կողոսացիներին
-- ^ Պողոս առաքյալի առաջին նամակը թեսաղոնիկեցիներին (Ա Թեսաղոնիկեցիս)
-- ^ Պողոս առաքյալի երկրորդ նամակը թեսաղոնիկեցիներին (Բ Թեսաղոնիկեցիս)
-- ^ Պողոս առաքյալի առաջին նամակը Տիմոթեոսին (Ա Տիմոթեոս)
-- ^ Պողոս առաքյալի երկրորդ նամակը Տիմոթեոսին (Բ Տիմոթեոս)
-- ^ Պողոս առաքյալի նամակը Տիտոսին
-- ^ Պողոս առաքյալի նամակը Փիլիմոնին
-- ^ Նամակ եբրայեցիներին
-- ^ Հակոբոս Առաքյալի ընդհանրական նամակը
-- ^ Պետրոս Առաքյալի առաջին ընդհանրական նամակը (Ա Պետրոս)
-- ^ Պետրոս Առաքյալի երկրորդ ընդհանրական նամակը (Բ Պետրոս)
-- ^ Հովհաննես Առաքյալի առաջին ընդհանրական նամակը (Ա Հովհաննես)
-- ^ Հովհաննես Առաքյալի երկրորդ ընդհանրական նամակը (Բ Հովհաննես)
-- ^ Հովհաննես Առաքյալի երրորդ ընդհանրական նամակը (Գ Հովհաննես)
-- ^ Հուդայի ընդհանրական նամակը
-- ^ Հայտնություն Հովհաննեսի

data Group = Pentateuch
            -- ^ Մովսեսի հնգամատյանը
            | Historical
            -- ^ Պատմական
            | Sermon
            -- ^ Ուսուցողական
            | Prophet
            -- ^ Մարգարեություն
            | Evangelie
            -- ^ Ավետարան
            | OtherBook
              -- ^ Պողոս առաքյալի թղթերը
              -- ^ Թղթեր
              deriving (Show, Eq, Ord)


-- | Book -> Scripture -> Chapter -> Section -> Paragraph -> Verse -> Words


-- books_order =
--     ["tMt", 'tMk', 'tLk', 'tJn', 'tActs', 'tRom', 't1Cor', 't2Cor', 'tGal', 'tEph', 'tPhil', 'tCol', 't1Thess', 't2Thess', 't1Tim', 't2Tim', 'tTit', 'tPhilem', 'tHeb', 'tJas', 't1Pet', 't2Pet', 't1Jn', 't2Jn', 't3Jn', 'tJude', 'tRev', 'tGen', 'tEx', 'tLev', 'tNum', 'tDeut', 'tJosh', 'tJudg', 'tRuth', 't1Kings', 't2Kings', 't3Kings', 't4Kings', 't1Chron', 't2Chron', 'tEzra', 'tNeh', 'tEsther', 'tJob', 'tPs', 'tProv', 'tEccles', 'tSong', 'tIs', 'tJer', 'tLam', 'tEzek', 'tDan', 'tHos', 'tJoel', 'tAmos', 'tObad', 'tJon', 'tMic', 'tNahum', 'tHab', 'tZeph', 'tHag', 'tZech', 'tMal', 'tTob', 'tJudith', 'tWis', 'tSir', 'tBar', 't1Mac', 't2Mac', 't3Mac', 't1Esdras'];
--  	var books_count = {'tMt':28, 'tMk':16, 'tLk':24, 'tJn':21, 'tActs':28, 'tRom':16, 't1Cor':16, 't2Cor':13, 'tGal':6, 'tEph':6, 'tPhil':4, 'tCol':4, 't1Thess':5, 't2Thess':3, 't1Tim':6, 't2Tim':4, 'tTit':3, 'tPhilem':1, 'tHeb':13, 'tJas':5, 't1Pet':5, 't2Pet':3, 't1Jn':5, 't2Jn':1, 't3Jn':1, 'tJude':1, 'tRev':22, 'tGen':50, 'tEx':40, 'tLev':27, 'tNum':36, 'tDeut':34, 'tJosh':24, 'tJudg':21, 'tRuth':4, 't1Kings':31, 't2Kings':24, 't3Kings':22, 't4Kings':25, 't1Chron':29, 't2Chron':36, 'tEzra':10, 'tNeh':13, 'tEsther':9, 'tJob':42, 'tPs':150, 'tProv':31, 'tEccles':12, 'tSong':8, 'tIs':66, 'tJer':52, 'tLam':5, 'tEzek':48, 'tDan':14, 'tHos':14, 'tJoel':3, 'tAmos':9, 'tObad':1, 'tJon':4, 'tMic':7, 'tNahum':3, 'tHab':3, 'tZeph':3, 'tHag':2, 'tZech':14, 'tMal':4, 'tTob':14, 'tJudith':16, 'tWis':19, 'tSir':44, 'tBar':5, 't1Mac':16, 't2Mac':15, 't3Mac':7, 't1Esdras':9};
--  	var books_names = {'tMt':'Մատթէոս / Matthew (tMt)', 'tMk':'Մարկոս / Mark (tMk)', 'tLk':'Ղուկաս / Luke (tLk)', 'tJn':'Յովհաննէս / John (tJn)', 'tActs':'Գործք / Acts (tActs)',
-- 	 '--1':'թղթեր / epistles', 'tRom':'Հռոմէացիներ / Romans (tRom)', 't1Cor':'Ա Կորնթացիներ / 1 Corinthians (t1Cor)', 't2Cor':'Բ Կորնթացիներ / 2 Corinthians (t2Cor)', 'tGal':'Գաղատացիներին / Galatians (tGal)', 'tEph':'Եփեսացիներ / Ephesians (tEph)', 'tPhil':'Փիլիպեցիներ / Philippians (tPhil)', 'tCol':'Կողոսացիներ / Colossians (tCol)', 't1Thess':'Ա Թեսաղոնիկեցիներ / 1 Thessalonians (t1Thess)', 't2Thess':'Բ Թեսաղոնիկեցիներ / 2 Thessalonians (t2Thess)', 't1Tim':'Ա Տիմոթէոս / 1 Timothy (t1Tim)', 't2Tim':'Բ Տիմոթէոս / 2 Timothy (t2Tim)', 'tTit':'Տիտոս / Titus (tTit)', 'tPhilem':'Փիլիմոն / Philemon (tPhilem)', 'tHeb':'Թուղթ Եբրայեցիներին / Hebrews (tHeb)', 'tJas':'Յակոբոս / James (tJas)', 't1Pet':'Ա Պետրոս / 1 Peter (t1Pet)', 't2Pet':'Բ Պետրոս / 2 Peter (t2Pet)', 't1Jn':'Ա Յովհաննէս / 1 John (t1Jn)', 't2Jn':'Բ Յովհաննէս / 2 John (t2Jn)', 't3Jn':'Գ Յովհաննէս / 3 John (t3Jn)', 'tJude':'Յուդա Առաքեալի Թուղթը / Jude (tJude)',
-- 	 '--2':'-','tRev':'Յայտնութիւն / Revelation (tRev)',
-- 	 '--3':'հնգամատեան / law','tGen':'Ծննդոց / Genesis (tGen)', 'tEx':'Ելք / Exodus (tEx)', 'tLev':'Ղեւտական / Leviticus (tLev)', 'tNum':'Թուեր / Numbers (tNum)', 'tDeut':'Երկրորդ Օրէնք / Deuteronomy (tDeut)',
-- 	 '--4':'պատմական / history','tJosh':'Յեսու / Joshua (tJosh)', 'tJudg':'Դատաւորներ / Judges (tJudg)', 'tRuth':'Հռութ / Ruth (tRuth)', 't1Kings':'Թագաւորութիւններ Ա / 1 Samuel (t1Kings)', 't2Kings':'Թագաւորութիւններ Բ / 2 Samuel (t2Kings)', 't3Kings':'Թագաւորութիւններ Գ / 1 Kings (t3Kings)', 't4Kings':'Թագաւորութիւններ Դ / 2 Kings (t4Kings)', 't1Chron':'Ա Մնացորդաց / 1 Chronicles (t1Chron)', 't2Chron':'Բ Մնացորդաց / 2 Chronicles (t2Chron)', 'tEzra':'Բ Եզրաս / Ezra (tEzra)', 'tNeh':'Նէեմի / Nehemiah (tNeh)', 'tEsther':'Եսթեր / Esther (tEsther)',
-- 	 '--5':'պոեմներ / poetry', 'tJob':'Յոբ / Job (tJob)', 'tPs':'Սաղմոս / Psalms (tPs)', 'tProv':'Առակներ / Proverbs (tProv)', 'tEccles':'Ժողովող / Ecclesiastes (tEccles)', 'tSong':'Երգ Երգոց / Song of Solomon (tSong)',
-- 	 '--6':'ավագ մերգարեներ / magor prophets','tIs':'Եսայի / Isaiah (tIs)', 'tJer':'Երեմիա / Jeremiah (tJer)', 'tLam':'Ողբ / Lamentations (tLam)', 'tEzek':'Եզեկիէլ / Ezekiel (tEzek)', 'tDan':'Դանիէլ / Daniel (tDan)',
-- 	 '--7':'մարգարեներ / minor prophets','tHos':'Օսէէ / Hosea (tHos)', 'tJoel':'Յովել / Joel (tJoel)', 'tAmos':'Ամոս / Amos (tAmos)', 'tObad':'Աբդիու / Obadiah (tObad)', 'tJon':'Յովնան / Jonah (tJon)', 'tMic':'Միքիա / Micah (tMic)', 'tNahum':'Նաւում / Nahum (tNahum)', 'tHab':'Ամբակում / Habakkuk (tHab)', 'tZeph':'Սոփոնիա / Zephaniah (tZeph)', 'tHag':'Անգէ / Haggai (tHag)', 'tZech':'Զաքարիա / Zechariah (tZech)', 'tMal':'Մաղաքիա / Malachi (tMal)',
-- 	 '--8':'երկրոդականոն / deuterocanonical', 'tTob':'Տոբիթ / Tobit (tTob)', 'tJudith':'Յուդիթ / Judith (tJudith)', 'tWis':'Իմաստութիւն Սողոմոնի / Wisdoms (tWis)', 'tSir':'Սիրաք / Sirak (tSir)', 'tBar':'Բարուք / Baruk (tBar)', 't1Mac':'Ա Մակաբայեցիներ / 1 Maccabees (t1Mac)', 't2Mac':'Բ Մակաբայեցիներ / 2 Maccabees (t2Mac)', 't3Mac':'Գ Մակաբայեցիներ / 3 Maccabees (t3Mac)', 't1Esdras':'Ա Եզրաս / Esdras (t1Esdras)'};
--     var books_name_am = {'tMt':'Մատթէոս', 'tMk':'Մարկոս', 'tLk':'Ղուկաս', 'tJn':'Յովհաննէս', 'tActs':'Գործք',
-- 	 '--1':'թղթեր', 't1Cor':'Ա Կորնթացիներ', 't2Cor':'Բ Կորնթացիներ', 'tGal':'Գաղատացիներին', 'tEph':'Եփեսացիներ', 'tPhil':'Փիլիպեցիներ', 'tCol':'Կողոսացիներ', 't1Thess':'Ա Թեսաղոնիկեցիներ', 't2Thess':'Բ Թեսաղոնիկեցիներ', 't1Tim':'Ա Տիմոթէոս', 't2Tim':'Բ Տիմոթէոս', 'tTit':'Տիտոս', 'tPhilem':'Փիլիմոն', 'tHeb':'Թուղթ Եբրայեցիներին', 'tJas':'Յակոբոս', 't1Pet':'Ա Պետրոս', 't2Pet':'Բ Պետրոս', 't1Jn':'Ա Յովհաննէս', 't2Jn':'Բ Յովհաննէս', 't3Jn':'Գ Յովհաննէս', 'tJude':'Յուդա Առաքեալի Թուղթը',
-- 	 '--2':'-','tRev':'Յայտնութիւն',
-- 	 '--3':'հնգամատեան', 'tEx':'Ելք', 'tLev':'Ղեւտական', 'tNum':'Թուեր', 'tDeut':'Երկրորդ Օրէնք',
-- 	 '--4':'պատմական', 'tJudg':'Դատաւորներ', 'tRuth':'Հռութ', 't1Kings':'Թագաւորութիւններ Ա', 't2Kings':'Թագաւորութիւններ Բ', 't3Kings':'Թագաւորութիւններ Գ', 't4Kings':'Թագաւորութիւններ Դ', 't1Chron':'Ա Մնացորդաց', 't2Chron':'Բ Մնացորդաց', 'tEzra':'Բ Եզրաս', 'tNeh':'Նէեմի', 'tEsther':'Եսթեր',
-- 	 '--5':'պոեմներ', 'tPs':'Սաղմոս', 'tProv':'Առակներ', 'tEccles':'Ժողովող', 'tSong':'Երգ Երգոց',
-- 	 '--6':'ավագ մերգարեներ', 'tJer':'Երեմիա', 'tLam':'Ողբ', 'tEzek':'Եզեկիէլ', 'tDan':'Դանիէլ',
-- 	 '--7':'մարգարեներ', 'tJoel':'Յովել', 'tAmos':'Ամոս', 'tObad':'Աբդիու', 'tJon':'Յովնան', 'tMic':'Միքիա', 'tNahum':'Նաւում', 'tHab':'Ամբակում', 'tZeph':'Սոփոնիա', 'tHag':'Անգէ', 'tZech':'Զաքարիա', 'tMal':'Մաղաքիա',
-- 	 '--8':'երկրոդականոն', 'tJudith':'Յուդիթ', 'tWis':'Իմաստութիւն Սողոմոնի', 'tSir':'Սիրաք', 'tBar':'Բարուք', 't1Mac':'Ա Մակաբայեցիներ', 't2Mac':'Բ Մակաբայեցիներ', 't3Mac':'Գ Մակաբայեցիներ', 't1Esdras':'Ա Եզրաս'};

-- 	var books_names_en = {'tMt':'Matthew', 'tMk':'Mark', 'tLk':'Luke', 'tJn':'John', 'tActs':'Acts',
-- 	 '--1':'epistles', 'tRom':'Romans', 't1Cor':'1 Corinthians', 't2Cor':'2 Corinthians', 'tGal':'Galatians', 'tEph':'Ephesians', 'tPhil':'Philippians', 'tCol':'Colossians', 't1Thess':'1 Thessalonians', 't2Thess':'2 Thessalonians', 't1Tim':'1 Timothy', 't2Tim':'2 Timothy', 'tTit':'Titus', 'tPhilem':'Philemon', 'tHeb':'Hebrews', 'tJas':'James', 't1Pet':'1 Peter', 't2Pet':'2 Peter', 't1Jn':'1 John', 't2Jn':'2 John', 't3Jn':'3 John', 'tJude':'Jude',
-- 	 '--2':'Revelation',
-- 	 '--3':'law','tGen':'Genesis', 'tEx':'Exodus', 'tLev':'Leviticus', 'tNum':'Numbers', 'tDeut':'Deuteronomy',
-- 	 '--4':'history','tJosh':'Joshua', 'tJudg':'Judges', 'tRuth':'Ruth', 't1Kings':'1 Samuel', 't2Kings':'2 Samuel', 't3Kings':'1 Kings', 't4Kings':'2 Kings', 't1Chron':'1 Chronicles', 't2Chron':'2 Chronicles', 'tEzra':'Ezra', 'tNeh':'Nehemiah', 'tEsther':'Esther',
-- 	 '--5':'poetry', 'tJob':'Job', 'tPs':'Psalms', 'tProv':'Proverbs', 'tEccles':'Ecclesiastes', 'tSong':'Song of Solomon',
-- 	 '--6':'magor prophets','tIs':'Isaiah', 'tJer':'Jeremiah', 'tLam':'Lamentations', 'tEzek':'Ezekiel', 'tDan':'Daniel',
-- 	 '--7':'minor prophets','tHos':'Hosea', 'tJoel':'Joel', 'tAmos':'Amos', 'tObad':'Obadiah', 'tJon':'Jonah', 'tMic':'Micah', 'tNahum':'Nahum', 'tHab':'Habakkuk', 'tZeph':'Zephaniah', 'tHag':'Haggai', 'tZech':'Zechariah', 'tMal':'Malachi',
-- 	 '--8':'deuterocanonical', 'tTob':'Tobit', 'tJudith':'Judith', 'tWis':'Wisdoms', 'tSir':'Sirak', 'tBar':'Baruk', 't1Mac':'1 Maccabees', 't2Mac':'2 Maccabees', 't3Mac':'3 Maccabees', 't1Esdras':'Esdras'};


-- Աստվածաշնչի և Հին կտակարանի առաջին հինգ գրքերն են, կոչվում են նաև Հնգամատյան: Համաձայն քրիստոնեական վարդապետության`   դրանք գրվել են Մովսես մարգարեի կողմից:
-- Ծննդոց
-- Ելք
-- Ղևտական
-- Թվեր
-- Երկրորդ օրենք
-- Պատմական

-- Պատմական գրքերում ներկայացվում է Իսրայելի պատմությունը Ավետյաց երկիր մտնելուց մինչև Սելևկյան պետության դեմ մղվող ազատագրական պայքարը:
-- Հեսու
-- Դատավորներ
-- Հռութ
-- Թագավորություններ Ա
-- Թագավորություններ Բ
-- Թագավորություններ Գ
-- Թագավորություններ Դ
-- Ա Մնացորդաց
-- Բ Մնացորդաց
-- Ա Եզրաս
-- Բ Եզրաս
-- Նեեմի
-- Եսթեր
-- Իմաստության
-- Սաղմոս
-- Առակներ
-- Ժողովող
-- Երգ երգոց
-- Հոբ
-- Մարգարեական

-- Եսայի
-- Օսեե
-- Ամոս
-- Միքիա
-- Հովել
-- Աբդիա
-- Հովնան
-- Նավում
-- Ամբակում
-- Սոփոնիա
-- Անգե
-- Զաքարիա
-- Երեմիա
-- Ողբ
-- Դանիել
-- Եզեկիել
-- Աղբյուր
-- Ք.Հ. հանրագիտարան
