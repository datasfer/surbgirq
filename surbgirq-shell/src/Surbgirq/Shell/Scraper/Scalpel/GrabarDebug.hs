{-# LANGUAGE ApplicativeDo     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}
{-# LANGUAGE QuasiQuotes         #-}
{-# LANGUAGE DeriveGeneric         #-}
{-# LANGUAGE QuasiQuotes, FlexibleContexts #-}

module Surbgirq.Shell.Scraper.Scalpel.GrabarDebug where

import Data.Text(Text)

import Text.InterpolatedString.Perl6 (qc)

import           Control.Applicative
import           Control.Monad
import           Control.Monad.IO.Class
import           Data.List
import           Data.List.Split
import qualified Data.Text           as T
import qualified Data.Text.Encoding  as TE
import qualified Data.Text.IO        as TIO
import           System.IO
import           Text.HTML.Scalpel
import System.FilePath
import           GHC.IO.Encoding
import           GHC.Generics

import Text.RawString.QQ    
import Text.Regex.PCRE
import qualified           Text.Regex.PCRE.Heavy as PCRE
import Data.Yaml
    
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
 } deriving(Show, Generic)


instance ToJSON VerseData 
instance ToJSON VerseData'
instance ToJSON SectionData
instance ToJSON ChapterData
instance ToJSON BookData
    
parseBibleHtml_1 :: Scraper String [(String, [SectionData])]
parseBibleHtml_1 = chroots ("div" @: [hasClass "content"]) $ inSerial pp
  where
   pp =  do
    title <- seekNext $ text "h1"
    sections <- many $ do
       section <- seekNext $T.pack <$>  text "h2"
       ps <- untilNext (matches "h2") (many $ seekNext $ VerseData' . T.pack <$> innerHTML "p")
       return $ SectionData section "" ps
    return (title, sections)

parseBibleTest :: IO ()
parseBibleTest = do
  setLocaleEncoding utf8
  hSetEncoding stdout utf8
  exampleHtml <- readFile "./htmlData/New/Matthew.html"
  let ts = scrapeStringLike exampleHtml parseBibleHtml_1
  case ts of
    Just xs -> do
            print $ length xs
            encodeFile "parseHtml.yaml" xs
            hFile <- openFile "scalpel.out" WriteMode
            -- print $  show xs
            --       TIO.putStrLn a
            -- [(String, [SectionData])]
            forM_ xs $ \ (t, ys) -> do
                 TIO.putStrLn $ T.pack  t      
                 forM_ ys $ \ SectionData{..} -> do
                     TIO.putStrLn $   title      
                     forM_ verses $ \ VerseData'{..} -> do
                       TIO.putStrLn $   "-->>"      
                       TIO.putStrLn $   vv      
                                                   
                
                -- (printSection hFile)
    Nothing -> error $ "failed parse html file "



-- <a id="footnote-265-903-backlink" class="footnote-link" href="#footnote-265-903">(903)</a>
parseVerse1 :: Scraper String [VerseData]
parseVerse1 = do
  let del = "\160"
  verse <- innerHTML $ "p"  @: [hasClass "Body_Body-Text"]
  vNums <- chroots ("p" // "span" @:  [hasClass "Num"]) $ parseVerseNum
  versRefs <- chroots ("p" // "a" @:  [hasClass "footnote-link"]) $ parseVerseRef

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
  where
    parseVerseNum :: Scraper String Text
    parseVerseNum = do
           txt <- T.pack <$> (attr "id" $ "span")
           return txt
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
    chroots ("div" @:  [hasClass "footnote"]) $ parseFootnote
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
            hFile <- openFile "footnotes.out" WriteMode
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
