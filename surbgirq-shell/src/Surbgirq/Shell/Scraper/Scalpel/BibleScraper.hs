{-# LANGUAGE ApplicativeDo     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}
{-# LANGUAGE QuasiQuotes         #-}
{-# LANGUAGE DeriveGeneric         #-}
{-# LANGUAGE QuasiQuotes, FlexibleContexts #-}

module Surbgirq.Shell.Scraper.Scalpel.BibleScraper where

import Data.Text(Text)
import Text.Read (readMaybe)
import Data.Maybe (fromMaybe)

import Text.InterpolatedString.Perl6 (qc)

import           Control.Applicative
import System.Directory
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
import qualified Data.Aeson as A
import Surbgirq.Shell.Types
    

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
 , verses :: [VerseData]
 } deriving(Show, Generic)

data VerseData = VerseData
 { verse'num :: Text
 , verse'verse :: Text
 } deriving(Show, Generic)


data Book' = Book'
 { b'title :: Text
 , b'chapters :: [Chapter]
 } deriving (Show, Generic)

data FootnoteData = FootnoteData Text Text
                  deriving (Show, Generic)

instance ToJSON VerseData 
instance ToJSON SectionData
instance ToJSON ChapterData
instance ToJSON BookData
instance ToJSON Book'
instance ToJSON FootnoteData
    
parseBibleTest :: IO ()
parseBibleTest = do
  setLocaleEncoding utf8
  hSetEncoding stdout utf8
  matthewText <- readFile "./data/html/1994/New/2.Mark.html"
  let exportFolder = "./data/html/1994/export"

  createDirectoryIfMissing True exportFolder

  let ts = scrapeStringLike matthewText parseBibleHtml_1
      
  case ts of
    Just xs -> do
            encodeFile "parseHtml.yaml" xs
            A.encodeFile "parseHtml.json" xs
            print $ length xs
            forM_ xs $ \Book'{..} -> do
              forM_ b'chapters $ \ ch@Chapeter{..} -> do
                        let file = exportFolder </> [qc|{chapter'number}.yaml|]
                        encodeFile file ch
            return ()
--            hFile <- openFile "scalpel.out" WriteMode
--            forM_ xs (printBook hFile)
    Nothing -> error $ "failed parse html file "


parseVerse_1 :: Scraper String [Verse]
parseVerse_1 = do
  verse <- innerHTML $ "p"  @: [hasClass "Body-Text"]
  vNums <- chroots ("p" // "span" @:  [hasClass "Numeral"]) $ parseVerseNum
  versRefs <- chroots ("p" // "a" @:  [hasClass "footnote-link"]) $ parseVerseRef

  let vs = filter (not . T.null) $ PCRE.split rr_1 $ T.pack verse
      rs = PCRE.scan refRegex  verse
  let xs = map (\(n, v) ->
                    let num = fromMaybe 0 $ ((readMaybe  $ T.unpack n) :: Maybe Int)
                    in Verse num v Nothing Nothing)  (zip vNums vs)
  return xs
  where
    parseVerseNum :: Scraper String Text
    parseVerseNum = do
           txt <- T.pack <$> text "span" --  (attr "id" $ "span")
           return txt
    parseVerseRef :: Scraper String Text
    parseVerseRef = do
           txt <- T.pack <$> text "a"
           return txt

parseBibleHtml_1 :: Scraper String [Book']
parseBibleHtml_1 = chroots ("div" @: [hasClass "content"]) $ inSerial innerScraper
  where
    innerScraper = do
       title <- seekNext $ T.pack <$> text "h2"
       chapters <- many $ do

                     -- TODO: parse to Int
         chapter <- seekNext $ T.pack <$> text "h3" <|> return "999"
         let chNum = fromMaybe 0 $ ((readMaybe  $ T.unpack chapter) :: Maybe Int)

         sections <- untilNext (matches "h3") $
                     many $ do
            sectionTitle <- (seekNext $ T.pack <$> text "h4")
            p_ref <- (seekNext $ T.pack <$> text ("p" @: [hasClass "Parallel-References"]))  <|> return T.empty
            ps <- untilNext (matches "h4") $ many $ seekNext $ parseVerse_1 
            return $ Section sectionTitle 111 p_ref $ [Paragraph 1 $ concat ps] 
         let secs = zipWith (\n s@(Section{section'number = m}) -> s{section'number = n}) [1..] sections
         return $ Chapeter chNum "" "" secs  
       return $ Book' title   chapters

parseBibleHtml :: Scraper String [BookData]
parseBibleHtml = chroots ("div" @: ["id" @= "mCSB_1_container"]) $ inSerial innerScraper
  where
    innerScraper = do
       title <- seekNext $ T.pack <$> text "h2"
       chapters <- many $ do

         chapter <- seekNext $ T.pack <$> text "h3" -- <|> return "****************"
         sections <- untilNext (matches "h3")
                     (many $ do
            sectionTitle <- (seekNext $ T.pack <$> text "h4")
            p_ref <- (seekNext $ T.pack <$> text ("p" @: [hasClass "Parallel-References"]))  <|> return "ref empty"
--            ps <- untilNext (matches "h4") (many $ seekNext $ VerseData [] . T.pack <$> parseVerse1)

            ps <- untilNext (matches "h4")
                  (                
                   many $ seekNext $ parseVerse
                  )
--            let vss = map (\(nums, refs, verse) -> VerseData nums refs $ T.pack verse ) ps
            return $ SectionData sectionTitle p_ref $ concat ps )
         return $ ChapterData chapter  sections  
       return $ BookData title chapters







-- <a id="footnote-265-903-backlink" class="footnote-link" href="#footnote-265-903">(903)</a>
parseVerse :: Scraper String [VerseData]
parseVerse = do
  verse <- innerHTML $ "p"  @: [hasClass "Body-Text"]
  vNums <- chroots ("p" // "span" @:  [hasClass "Numeral"]) $ parseVerseNum
  versRefs <- chroots ("p" // "a" @:  [hasClass "footnote-link"]) $ parseVerseRef

  let vs = filter (not . T.null) $ PCRE.split rr_1 $ T.pack verse
      rs = PCRE.scan refRegex  verse
  let xs = map (\(num, v) -> VerseData num v)  (zip vNums vs)
  return xs
  where
    parseVerseNum :: Scraper String Text
    parseVerseNum = do
           txt <- T.pack <$> (attr "id" $ "span")
           return txt
    parseVerseRef :: Scraper String Text
    parseVerseRef = do
           txt <- T.pack <$> text "a"
           return txt

  -- let vs = filter (not . T.null) $ PCRE.split rr_1  verse
--       rs = PCRE.scan refRegex  verse
--   mapM (\(link, [z]) -> do
--           TIO.putStrLn link
--           TIO.putStrLn z
--        )   rs

--   forM_ (zip verse'nums vs) $ \(num, v) -> do
-- --      TIO.putStrLn "-->"
--       TIO.putStrLn $ [qc|{num}. {v}|]
         
-- parseVerse1 :: Scraper String [VerseData]
-- parseVerse1 = do
--   let del = "\160"
--   verse <- innerHTML $ "p"  @: [hasClass "Body-Text"]
--   vNums <- chroots ("p" // "span" @:  [hasClass "Numeral"]) $ parseVerseNum
--   versRefs <- chroots ("p" // "a" @:  [hasClass "footnote-link"]) $ parseVerseRef

--   let vs = filter (not . T.null) $ PCRE.split rr_1 $ T.pack verse
--       rs = PCRE.scan refRegex  verse
--   -- mapM (\(link, [z]) -> do
--   --         TIO.putStrLn link
--   --         TIO.putStrLn z
--   --      )   rs

--   let xs = map (\(num, v) -> VerseData vNums versRefs num v $ T.pack verse)  (zip vNums vs)
--   return xs
--   -- verse <- text $ "p"  @: [hasClass "Body-Text"]
--   -- return $ map (VerseData . T.pack ) $ splitOn del verse         
--   -- return $ (++ "\n") <$> intercalate "{#}" $ splitOn del verse
-- --  return $ VerseData vNums versRefs $ T.pack  verse --   (vNums, versRefs, verse)
--   where
--     parseVerseNum :: Scraper String Text
--     parseVerseNum = do
--            txt <- T.pack <$> (attr "id" $ "span")
--            return txt
--     parseVerseRef :: Scraper String Text
--     parseVerseRef = do
--            txt <- T.pack <$> text "a"
--            return txt


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
--    forM_ verses $ printVerse'

printVerse hFile VerseData{..} = do
  TIO.putStrLn "{#}"
  TIO.hPutStrLn hFile verse'verse    
  TIO.putStrLn verse'verse


-- printVerse' VerseData{..} = do
--   TIO.putStrLn " -- - dadatam"
-- --  let del = "\160"
--   let del = [qc|<\span>|]
-- --  forM_ (T.splitOn del $  verse) $ \v -> TIO.putStrLn $ v
--   TIO.putStrLn $T.pack . show $  verse'num
-- --  TIO.putStrLn $T.pack . show $  verse'refs
--   let vs = filter (not . T.null  ) $ PCRE.split rr_1  verse
-- --      rs = filter (not . T.null  ) $ PCRE.scan refRegex  verse
--       rs = PCRE.scan refRegex  verse
--   mapM (\(link, [z]) -> do
--           TIO.putStrLn link
--           TIO.putStrLn z
--        )   rs

--   forM_ (zip verse'nums vs) $ \(num, v) -> do
-- --      TIO.putStrLn "-->"
--       TIO.putStrLn $ [qc|{num}. {v}|]

delS :: Text
delS = [qc|</span>|]

  
       
rr_1 = [PCRE.re|<\s*span[^>]*>(.*?)<\s*/\s*span>|]


-- ref link with the worde before that
refRegex = [PCRE.re|(?:\S+\s)?\S*<\s*a[^>]*>(.*?)<\s*/\s*a>|]



-- | Footnotes
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
  exampleHtml <- readFile "./data/html/1994/matthew.html"
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
