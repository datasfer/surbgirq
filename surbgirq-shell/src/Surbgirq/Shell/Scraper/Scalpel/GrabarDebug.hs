{-# LANGUAGE ApplicativeDo     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}
{-# LANGUAGE QuasiQuotes         #-}
{-# LANGUAGE DeriveGeneric         #-}
{-# LANGUAGE QuasiQuotes, FlexibleContexts #-}

module Surbgirq.Shell.Scraper.Scalpel.GrabarDebug where

import Debug.Trace
    
import Data.Text(Text)
import Text.Read (readMaybe)
import Data.Maybe (fromMaybe)
import Data.Map(Map)
import Control.Monad.Except (MonadError, MonadIO, catchError, liftIO)

import Data.Char    

import Text.InterpolatedString.Perl6 (qc)

import System.Directory

import Data.IORef

import           Control.Applicative
import           Control.Monad
import           Control.Monad.IO.Class
import           Data.List
import           Data.List.Split
import qualified Data.Text           as T
import qualified Data.Text.Encoding  as TE
import qualified Data.Text.IO        as TIO
import qualified Data.Map.Strict as Map
import qualified Data.Aeson as A
    
import           System.IO
import           Text.HTML.Scalpel
import System.FilePath
import           GHC.IO.Encoding
import           GHC.Generics

import Text.RawString.QQ    
import Text.Regex.PCRE
import qualified           Text.Regex.PCRE.Heavy as PCRE
import Data.Yaml
import Surbgirq.Shell.Types


    
htmlData :: String
htmlData = "<section id='examples'>\
           \<h2 id='toc_marker-2-1' class='heading2'>Title1 </h2>\
           \<h3 class='heading3'>1</h3>\
           \<h4 class='heading4'>ՎԵՐՆԱԳԻՐ </h4>\
           \<p class='Body-Text'>verse 1-1</p>\
           \<p class='Body-Text'><span class='Numeral' id='1-2'>1&nbsp;</span>verse 1-2</p>\
           \<p class='Body-Text'><span class='Numeral' id='1-3'>1&nbsp;</span>verse 1-3</p>\
           \<h3 class='heading3'>1</h3>\
           \<h4 class='heading4'>ՎԵՐՆԱԳԻՐ </h4>\
           \<p class='Body-Text'><span class='Numeral' id='1-4'>1&nbsp;</span>verse 1-1</p>\
           \<p class='Body-Text'><span class='Numeral' id='1-5'>1&nbsp;</span>verse 1-2</p>\
           \<p class='Body-Text'><span class='Numeral' id='1-6'>1&nbsp;</span>verse 1-3</p>\
     \</section>"


data Item
    = BookTitle String
    | SectionTitle String
    | SectionNum String
    | VerseLine String
    deriving (Show, Eq)


allItems :: String -> IO (Maybe [Item])
allItems url = scrapeURL url items

items :: Scraper String [Item]
items = chroots ("section" @: ["id" @= "examples"]) item

item :: Scraper String Item
item = bookTitle <|> chNum <|> secTitle <|> verse1 -- (VerseLine <$> parseVerse)

bookTitle :: Scraper String Item
bookTitle = do
  title <- text $ "h2" @: [hasClass "heading2"]
  return $ BookTitle title

chNum :: Scraper String Item
chNum = do
  num <- text $ "h3" @: [hasClass "heading3"]
  return $ SectionNum num

secTitle :: Scraper String Item
secTitle = do
  title <- text $ "h4" @: [hasClass "heading4"]
  return $ SectionTitle title

verse1 :: Scraper String Item
verse1 = do
  title <- text $ "p"
  return $ VerseLine title

-- sections :: Scraper String [(Text, [(Text, [Text])])]
-- sections = do
--   chroots ("section" @: ["id" @= "examples"]) $ inSerial $ do
--     title <- seekNext $ text $ "h2" @: [hasClass "heading2"]
--     num <- seekNext $ text $ "h3" @: [hasClass "heading3"]

--     ss <- many $ do
--          section <- seekNext $ text "h4"

--          ps <- untilNext (matches "h4") (many $ seekNext $ T.pack <$>  parseVerse)
--          return (T.pack (section ++ num), ps)
--     return (T.pack (title ++ num), ss)

-- sections1 :: Scraper String [(Text, [(Text, [Text])])]
-- sections1 = do
--   chroots ("section" @: ["id" @= "examples"]) $ inSerial $ do
--     title <- seekNext $ text $ "h2" @: [hasClass "heading2"]
--     ss <- many $ do
--          section <- seekNext $ text "h4"
--          ps <- untilNext (matches "h4") (many $ seekNext $ T.pack <$>  parseVerse)
--          return (T.pack section, ps)
--     return (T.pack title, ss)



-- allSections :: String -> IO (Maybe [(T.Text, [[T.Text]])])
-- allSections url = scrapeURL url (sections <|> sections1)

data BookData = BookData
 { book'title :: Text
 , book'chapters :: [ChapterData]
 } deriving (Show, Generic)
data ChapterData = ChapterData
 { chapterNum :: Text
 , chapter'sections :: [SectionData]
 } deriving(Show, Generic)

data SectionData = SectionData
 { title :: Text
 , p_ref :: Text
 , verses :: [VerseData']
 } deriving(Show, Generic)

data VerseData = VerseData
 { verse'nums :: [Text]
 , verse'refs :: [Text]
 , verse'ref_word :: [(String, [String])]
 , verse'num :: Text
 , verse'verse :: Text
 , verse :: Text
 } deriving(Show, Generic)

data VerseData' = VerseData'
  { vv :: Text
  , vv'num :: [Int]
  , vv'vv :: Text
  , vv'vs :: [Verse]
 } deriving(Show, Generic)

data Book' = Book'
 { b'title :: Text
 , b'chapters :: [Chapter]
 } deriving (Show, Generic)

instance ToJSON Book'
instance ToJSON VerseData 
instance ToJSON VerseData'
instance ToJSON SectionData
instance ToJSON ChapterData
instance ToJSON BookData


parseBibleTest :: IO ()
parseBibleTest = do
  setLocaleEncoding utf8
  hSetEncoding stdout utf8
  htmlText <- readFile "./data/html/v1805/New/01.Matthew.html"
  let resM = scrapeStringLike htmlText parseFootnotesMap
      refMap = case resM of
                           Just m -> m
                           Nothing -> Map.empty

      ts = scrapeStringLike htmlText (parseBibleHtml_2 refMap)
  case ts of
    Just xs -> do
            print $ length xs
            encodeFile "grabarparseHtml.yaml" xs
            A.encodeFile "grabarparseHtml.json" xs
            hFile <- openFile "grabar.out" WriteMode
            -- print $  show xs
            --       TIO.putStrLn a
            -- [(String, [SectionData])]
--             forM_ xs $ \ Book'{..} -> do
--                  TIO.putStrLn $ T.pack  t      
--                  forM_ ys $ \ SectionData{..} -> do
--                      TIO.putStrLn $   title      
--                      forM_ verses $ \ VerseData'{..} -> do
--                        TIO.putStrLn $   "-->>"      
-- --                       TIO.putStrLn $   vv      
--                       --  forM_ vv'num TIO.putStrLn
--                        print $ show vv'num 
--                        TIO.putStrLn $ vv'vv      
--                        forM_ vv'vs $ \ Verse{..} -> do
--                          let ss = [qc|{verse'verse}. {verse'content}|]
--                          TIO.putStrLn ss
--                          TIO.hPutStrLn hFile ss
--                          forM_ verse'ref $ \ VerseRef{..} -> do

--                            let ss = case verseRef'type of
--                                       RefFootnote a b -> [qc|{verseRef'index}. {a} _ {b}|]
--                                       _ -> [qc|{verseRef'index}. {verseRef'type} |]
--                            TIO.putStrLn ss
--                            TIO.hPutStrLn hFile ss


            hClose hFile                                     

                -- (printSection hFile)
    Nothing -> error $ "failed parse html file "

 

parseBibleTestAll :: IO ()
parseBibleTestAll = do
  setLocaleEncoding utf8
  hSetEncoding stdout utf8
  let datDir = "./data/html/v1805/New" -- "./data/html/1994/New"
      outRootDir = "./data/html/v1805/export"

  createDirectoryIfMissing True outRootDir

  txtFiles <- listDirectory datDir `catchError` \_ -> do
                                          liftIO $ putStrLn (concat [datDir, " does not exist."])
                                          return []

  forM_ (sort txtFiles) $ \file -> when (doesFilenameMatch file) $ do
    let fullFilename = datDir </> file
    htmlText <- readFile fullFilename
    print fullFilename 
    let resM = scrapeStringLike htmlText parseFootnotesMap
        refMap = case resM of
                           Just m -> m
                           Nothing -> Map.empty

        ts = scrapeStringLike htmlText (parseBibleHtml_1 refMap)
    case ts of
      Just xs -> do
              print $ length xs
              encodeFile "grabarparseHtml.yaml" xs
              hFile <- openFile "grabar.out" WriteMode
              -- print $  show xs
              --       TIO.putStrLn a
              -- [(String, [SectionData])]
              forM_ xs $ \ (t, ys) -> do
                   TIO.putStrLn $ T.pack  t      
                   forM_ ys $ \ SectionData{..} -> do
                       TIO.putStrLn $   title      
                       forM_ verses $ \ VerseData'{..} -> do
                         TIO.putStrLn $   "-->>"      
  --                       TIO.putStrLn $   vv      
                        --  forM_ vv'num TIO.putStrLn
                         print $ show vv'num 
                         TIO.putStrLn $ vv'vv      
                         forM_ vv'vs $ \ Verse{..} -> do
                           let ss = [qc|{verse'verse}. {verse'content}|]
                           TIO.putStrLn ss
                           TIO.hPutStrLn hFile ss
                           forM_ verse'ref $ \ VerseRef{..} -> do

                             let ss = case verseRef'type of
                                        RefFootnote a b -> [qc|{verseRef'index}. {a} _ {b}|]
                                        _ -> [qc|{verseRef'index}. {verseRef'type} |]
                             TIO.putStrLn ss
                             TIO.hPutStrLn hFile ss


              hClose hFile                                     

                  -- (printSection hFile)
      Nothing -> error $ "failed parse html file "
  where
    doesFilenameMatch :: FilePath -> Bool
    doesFilenameMatch path = takeExtension path `elem` [ ".html", ".HTML"]


parseBibleHtml_2 :: Map Text Text -> Scraper String [Book']
parseBibleHtml_2 refM = chroots ("div" @: [hasClass "content"]) $ inSerial pp
  where
   pp =  do
    bookTitle <- seekNext $ T.pack <$> text "h1"
    chapters <- many $ do
       chapterTitle <- seekNext $  text "h2"
       let chTitle = T.pack $ dropWhile isDigit chapterTitle
           chNum = read $ takeWhile isDigit chapterTitle :: Int
       sections <- untilNext (matches "h2") $ many $ seekNext parse

       let secs = zipWith
                  (\n s@(Section{section'number = m}) -> s{section'number = n})
                  [1..] sections

           ss = map (\sec@Section{section'paragraphs = ps} ->
                  let ps' = zipWith (\n p@(Paragraph{paragraph'number = m}) -> p{paragraph'number = n})
                          [1..] ps
                  in sec{section'paragraphs = ps'}
                    ) secs                   
       return $ Chapeter chNum chTitle "" ss
    return $ Book' bookTitle chapters
   parse = do
     vv <- T.pack <$> innerHTML "p"
     rawVerseHtml <-  innerHTML $ "p" @: [hasClass "Body_Body-Text"]
     vNums <- chroots ("p" // "span" @: [hasClass "Num"]) $ parseVerseNum
     subTitle <- (chroot ("p" // "span" @: [hasClass "Drop"]) $ parseSubTitle) <|> return T.empty

     let from = trace (show vNums) $ head vNums
         to = last vNums
--         vs = filter (not . T.null) $ PCRE.split rr_1 $ T.pack verse
         vs = filter ( (>1) . T.length . T.strip) $ PCRE.split rr_1 $ T.pack rawVerseHtml
         
         rs :: [(String, [String])]     
         rs = PCRE.scan refRegex rawVerseHtml
      
         verseRefs = map toVerseRef rs

         xs = map ( \(n, verse) ->
                    let num = n
                        vR = filter (prRefBelongs verse) verseRefs
                        v = T.strip $ case vR of
                              [] -> verse
                              _  -> removeLinkTag verse
                    in Verse num v Nothing (map (updateRefs refM v) vR)
                       )
               (zip [from..to] vs)
     return $ Section subTitle 999 "" [Paragraph 33 xs] -- vv vNums (T.pack rawVerseHtml) xs

   removeLinkTag str = T.intercalate "" $ PCRE.split linkRegex str
    
   toVerseRef :: (String,[String]) -> VerseRef
   toVerseRef (footnote, [key]) = VerseRef 0 (RefFootnote (T.pack key) (removeLinkTag $ T.pack footnote) )

    -- predicate reference belongs to verse
   prRefBelongs :: Text -> VerseRef -> Bool
   prRefBelongs verse VerseRef{..} =
        case verseRef'type of
          -- check if footnote belongs to the verse
          RefFootnote key _ -> T.isInfixOf key verse
          _ -> False

   updateRefs :: Map Text Text -> Text -> VerseRef -> VerseRef
   updateRefs refMap verse ref@VerseRef{..} =
       let (rT, keyWord) = case verseRef'type of
                  RefFootnote key f -> (RefFootnote (refMap Map.! key) f, f)
                  _ -> error "Differ than Footnote type"
           ws = trace (T.unpack keyWord) $
                zip [1..] (T.words verse)
           
           [w1, w2] = -- trace (show (T.words keyWord)) $
                    trace (show ref) $
                     T.words keyWord

           ns1 = filter (\(index, w) -> ( w == w1) || T.init w == w1) ws
           -- remove the last puncuation T.init w
           ns2 = filter (\(index, w) -> ( w == w2) || T.init w == w2) ws 
           index = trace (show ns1) $  case (length ns1, length ns2) of
             (_, 1) -> getIndex $ head ns2
             (1, _) -> getIndex $ head ns1
             (0, 0)  -> 0
             (_ , _) -> findFootNoteIndex verse ns1 ns2
                    
       in VerseRef index rT 

   getIndex (i, _) = i       
   findFootNoteIndex :: Text -> [(Int, Text)] -> [(Int, Text)] -> Int
   findFootNoteIndex v firstWs secondWs =
       let is1 = map (\(i,_) -> i) firstWs
           is2 = map (\(i,_) -> i) secondWs
           zs = [ y  | x <- is1, y <- is2, x == y - 1] 
       in case zs of
            [] -> error $ T.unpack v -- T.unpack v
            _ -> trace (show zs) $ head zs
   parseSubTitle :: Scraper String Text
   parseSubTitle = T.pack <$> text "span"

    
parseBibleHtml_1 :: Map Text Text -> Scraper String [(String, [SectionData])]
parseBibleHtml_1 refM = chroots ("div" @: [hasClass "content"]) $ inSerial pp
  where
   pp =  do
    bookTitle <- seekNext $ text "h1"
    sections <- many $ do
       chapterTitle <- seekNext $T.pack <$>  text "h2"
       ps <- untilNext (matches "h2") $ many $ seekNext $ parse
       return $ SectionData chapterTitle "" ps
    return (bookTitle, sections)
   parse = do
     vv <- T.pack <$> innerHTML "p"
     rawVerseHtml <-  innerHTML $ "p" @: [hasClass "Body_Body-Text"]
     vNums <- chroots ("p" // "span" @: [hasClass "Num"]) $ parseVerseNum
     let from = trace (show vNums) $ head vNums
         to = last vNums
--         vs = filter (not . T.null) $ PCRE.split rr_1 $ T.pack verse
         vs = filter ( (>1) . T.length . T.strip) $ PCRE.split rr_1 $ T.pack rawVerseHtml
         
         rs :: [(String, [String])]     
         rs = PCRE.scan refRegex rawVerseHtml
      
         verseRefs = map toVerseRef rs

         xs = map ( \(n, verse) ->
                    let num = n
                        vR = filter (prRefBelongs verse) verseRefs
                        v = T.strip $ case vR of
                              [] -> verse
                              _  -> removeLinkTag verse
                    in Verse num v Nothing (map (updateRefs refM v) vR)
                       )
               (zip [from..to] vs)
     return $ VerseData' vv vNums (T.pack rawVerseHtml) xs

   removeLinkTag str = T.intercalate "" $ PCRE.split linkRegex str
    
   toVerseRef :: (String,[String]) -> VerseRef
   toVerseRef (footnote, [key]) = VerseRef 0 (RefFootnote (T.pack key) (removeLinkTag $ T.pack footnote) )

    -- predicate reference belongs to verse
   prRefBelongs :: Text -> VerseRef -> Bool
   prRefBelongs verse VerseRef{..} =
        case verseRef'type of
          -- check if footnote belongs to the verse
          RefFootnote key _ -> T.isInfixOf key verse
          _ -> False

   updateRefs :: Map Text Text -> Text -> VerseRef -> VerseRef
   updateRefs refMap verse ref@VerseRef{..} =
       let (rT, keyWord) = case verseRef'type of
                  RefFootnote key f -> (RefFootnote (refMap Map.! key) f, f)
                  _ -> error "Differ than Footnote type"
           ws = trace (T.unpack keyWord) $
                zip [1..] (T.words verse)
           
           [w1, w2] = -- trace (show (T.words keyWord)) $
                    trace (show ref) $
                     T.words keyWord

           ns1 = filter (\(index, w) -> ( w == w1) || T.init w == w1) ws
           -- remove the last puncuation T.init w
           ns2 = filter (\(index, w) -> ( w == w2) || T.init w == w2) ws 
           index = trace (show ns1) $  case (length ns1, length ns2) of
             (_, 1) -> getIndex $ head ns2
             (1, _) -> getIndex $ head ns1
             (0, 0)  -> 0
             (_ , _) -> findFootNoteIndex verse ns1 ns2
                    
       in VerseRef index rT 

   getIndex (i, _) = i       
   findFootNoteIndex :: Text -> [(Int, Text)] -> [(Int, Text)] -> Int
   findFootNoteIndex v firstWs secondWs =
       let is1 = map (\(i,_) -> i) firstWs
           is2 = map (\(i,_) -> i) secondWs
           zs = [ y  | x <- is1, y <- is2, x == y - 1] 
       in case zs of
            [] -> error $ T.unpack v -- T.unpack v
            _ -> trace (show zs) $ head zs
                 
       

parseFootnotesMap :: Scraper String (Map.Map Text Text)
parseFootnotesMap = do
    ps <- chroots ( ("div" @:  [hasClass "_idFootnotes"]) // "p") $ parseFootnote
    return $ Map.fromList (map makePair ps) 
  where
    -- removeLinkTag str = T.intercalate "" $ PCRE.split linkRegex str

    makePair (FootnoteData a b) = (a, removeNumPart b)

   -- "[4]\tՈմանք. Եւ զեղբարսն նորա։"
    removeNumPart refTxt =
        let t = case T.split (=='\t') refTxt of
                  [_,y] -> y
                  _ -> error [qc|{refTxt} - On footnone remove num|]
        in t
    parseFootnote :: Scraper String FootnoteData
    parseFootnote = do
           txt <- T.pack <$> text ("p") -- // "span")
           num <- T.pack <$> text ("p" // "a"  )
           return $ FootnoteData num txt


-- <a id="footnote-265-903-backlink" class="footnote-link" href="#footnote-265-903">(903)</a>
parseVerse1 :: Scraper String [VerseData]
parseVerse1 = do
  let del = "\160"
  verse <- innerHTML $ "p"  @: [hasClass "Body_Body-Text"]
  vNums <- chroots ("p" // "span" @: [hasClass "Num"])  $ T.pack <$> innerHTML "span" -- parseVerseNum
  versRefs <- chroots ("p" // "a" @: [hasClass "footnote-link"]) $ parseVerseRef

  let vs = filter (not . T.null) $ PCRE.split rr_1 $ T.pack verse
      rs = PCRE.scan refRegex verse
  -- mapM (\(link, [z]) -> do
  --         TIO.putStrLn link
  --         TIO.putStrLn z
  --      )   rs

  let xs = map (\(num, v) -> VerseData vNums (versRefs) rs num v $ T.pack verse)  (zip vNums vs)
  return xs
  -- verse <- text $ "p"  @: [hasClass "Body-Text"]
  -- return $ map (VerseData . T.pack ) $ splitOn del verse         
  -- return $ (++ "\n") <$> intercalate "{#}" $ splitOn del verse
--  return $ VerseData vNums versRefs $ T.pack  verse --   (vNums, versRefs, verse)
--  where
parseVerseNum :: Scraper String Int
parseVerseNum = do
       txt <- text "span"
       let num = fromMaybe 0 $ ((readMaybe txt) :: Maybe Int)
       return num
parseVerseRef :: Scraper String Text
parseVerseRef = do
       txt <- T.pack <$> text "a"
       return txt


printBook hFile BookData{..} = do
   TIO.putStrLn (T.append "    " book'title)
   TIO.hPutStrLn hFile (T.append "    " book'title)
   forM_ book'chapters $ printChapter hFile

printChapter hFile  ChapterData{..} = do
           TIO.putStrLn (T.append "    " chapterNum)
           TIO.hPutStrLn hFile (T.append "    " chapterNum)
           forM_ chapter'sections $ printSection hFile

printSection hFile SectionData{..} = do
    (TIO.putStrLn . T.append "      ")  title
    (TIO.putStrLn . T.append "      ")  p_ref
    (TIO.hPutStrLn hFile . T.append "      ")  title
    (TIO.hPutStrLn hFile . T.append "      ")  p_ref
    forM_ verses $ printVerse1

printVerse hFile VerseData{..} = do
  TIO.putStrLn "{#}"
  TIO.hPutStrLn hFile verse    
  TIO.putStrLn verse

printVerse1 VerseData'{..} = do
  TIO.putStrLn "{#}"
  TIO.putStrLn vv


printVerse' VerseData{..} = do
  TIO.putStrLn " -- - dadatam"
  let del = [qc|<\span>|]
  TIO.putStrLn $T.pack . show $ verse'nums
  TIO.putStrLn $T.pack . show $ verse'refs
  let vs = filter (not . T.null ) $ PCRE.split rr_1  verse
--      rs = filter (not . T.null  ) $ PCRE.scan refRegex  verse
--      rs = PCRE.scan refRegex  verse
  mapM (\(link, [z]) -> do
          
          let kv = [qc|{T.pack z} -> {T.pack link}|] :: Text
          TIO.putStrLn kv -- $ T.pack link
--          TIO.putStrLn $ T.pack z
       ) verse'ref_word
   
  TIO.putStrLn $ [qc|{verse'num}. {verse'verse}|]

--   forM_ (zip verse'nums vs) $ \(num, v) -> do
-- --      TIO.putStrLn "-->"
--       TIO.putStrLn $ [qc|{num}. {v}|]

delS :: Text
delS = [qc|</span>|]


data FootnoteData = FootnoteData Text Text
                  deriving (Show)

parseFootnotes :: Scraper String [FootnoteData]
parseFootnotes = do
    chroots ( ("div" @:  [hasClass "_idFootnotes"]) // "p") $ parseFootnote
  where
    parseFootnote :: Scraper String FootnoteData
    parseFootnote = do
           txt <- T.pack <$> text "p"
           num <- T.pack <$> text ("p" // "a"  )
           return $ FootnoteData num txt



parseFootNoteTest :: IO ()
parseFootNoteTest = do
  setLocaleEncoding utf8
  hSetEncoding stdout utf8
  exampleHtml <- readFile "./htmlData/New/Matthew.html"
  let ts = scrapeStringLike exampleHtml parseFootnotes
  case ts of
    Just xs -> do
            hFile <- openFile "grabarfootnotes.out" WriteMode
            forM_ xs printFootnote
    Nothing -> error $ "failed parse html file "
 where
   printFootnote (FootnoteData a b) = do
                      TIO.putStrLn (T.append "    " a)
                      TIO.putStrLn (T.append "    " b)
  
-- Regex
-- rr1 :: String
-- rr1 = [r|<\s*span[^>]*>(.*?)<\s*/\s*span>|]

-- verseSpanRegex = mkRegex [qc|<\s*span[^>]*>(.*?)<\s*/\s*span>|]
-- splitVerseText = splitRegex verseSpanRegex
 

-- matchTexst = matchRegexAll verseSpanRegex txtReg
             
-- txtReg :: String
-- txtReg = [qc|asdasdasd asd<span class="Numeral" id="6-16">16 </span> text_11 <span class="Numeral" id="6-17">17 </span> asdasd "|]                 

-- tt3 = splitVerseText txtReg
      


-- tt1 = getAllTextMatches (txtReg =~ rr1) :: [String]

-- txt1 :: String
-- txt1 = [qc|Aenean lacinia bibendum <a href="/life">life</a> sed consectetur. <a href="/work">Work</a> quis risus eget urna mollis ornare <a href="/about">about</a> leo.|]
-- rg1 :: String
-- rg1 = [r|/<\s*a[^>]*>(.*?)<\s*/\s*a>/g|]

      
-- tt2 = getAllTextMatches (txt1 =~ rg1) :: [String]
       
rr_1 = [PCRE.re|<\s*span[^>]*>(.*?)<\s*/\s*span>|]


-- ref link with the worde before that
refRegex = [PCRE.re|(?:\S+\s)?\S*<\s*a[^>]*>(.*?)<\s*/\s*a>|]
linkRegex = [PCRE.re|<\s*a[^>]*>(.*?)<\s*/\s*a>|]
