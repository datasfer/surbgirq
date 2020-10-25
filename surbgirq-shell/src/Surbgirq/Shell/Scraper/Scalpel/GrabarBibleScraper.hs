{-# LANGUAGE ApplicativeDo     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}
{-# LANGUAGE QuasiQuotes         #-}
{-# LANGUAGE DeriveGeneric         #-}
{-# LANGUAGE QuasiQuotes, FlexibleContexts #-}

module Surbgirq.Shell.Scraper.Scalpel.GrabarBibleScraper
    (parseGrabarBibleHtml)
    where

import Debug.Trace
import Data.IORef
    
import Data.Text(Text)
import Text.Read (readMaybe)
import Data.Maybe (fromMaybe)
import Data.Map(Map)
import Control.Monad.Except (MonadError, MonadIO, catchError, liftIO)

import Data.Char    

import Text.InterpolatedString.Perl6 (qc)

import System.Directory


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
import qualified Text.Regex.PCRE.Heavy as PCRE
    
import           System.IO
import           Text.HTML.Scalpel
import System.FilePath
import           GHC.IO.Encoding
import           GHC.Generics

import Text.RawString.QQ    
import Text.Regex.PCRE
import Data.Yaml

import Surbgirq.Shell.Types

-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------

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
parseBibleTest = parseGrabarBibleHtml "./data/html/v1805" "./data/yaml"

data OutFormat =  YAML
                | JSON

-- | stack exec -- html-scraper --v1805  --yaml  -i ./data/html/v1805 -o ./data/yaml
parseGrabarBibleHtml :: FilePath -> FilePath -> IO ()
parseGrabarBibleHtml dataRootPath  outPutPath = do
  setLocaleEncoding utf8
  hSetEncoding stdout utf8
  let datDir = dataRootPath </> "New"
      datDirOld = dataRootPath </> "Old"
      outRootDir = outPutPath </> "bible/am/v1805"
      format = YAML

  createDirectoryIfMissing True outRootDir

  txtFiles <- ((datDir </> ) <$>) <$> listDirectory datDir `catchError` \_ -> do
                                          liftIO $ putStrLn (concat [datDir, " does not exist."])
                                          return []

  txtFilesOld <- ((datDirOld </> ) <$>) <$> listDirectory datDirOld `catchError` \_ -> do
                                            liftIO $ putStrLn (concat [datDirOld, " does not exist."])
                                            return []

  forM_  (sort (txtFiles ++ txtFilesOld) )
          $ \file -> when (doesFilenameMatch file) $ do

    let fullFilename =file
        lastFolderName = (last . splitPath $ takeDirectory fullFilename)
    htmlText <- readFile fullFilename
    print fullFilename 

    let resM = scrapeStringLike htmlText parseFootnotesMap
        refMap = case resM of
                           Just m -> m
                           Nothing -> Map.empty
        ts = scrapeStringLike htmlText (parseBible refMap)

    case ts of 
      Just xs  -> do
              encodeFile "parseHtml.yaml" xs
              A.encodeFile "parseHtml.json" xs
              print $  length xs
      
              when (length xs > 0) $ do
                let outDir = outRootDir </> lastFolderName </> (takeBaseName file)
                createDirectoryIfMissing True outDir

                forM_ xs $ \Book'{..} -> do
                  forM_ b'chapters $ \ ch@Chapeter{..} -> do
                            let file = outDir </> if chapter'number < 10
                                                  then [qc|0{chapter'number}.yaml|]
                                                  else [qc|{chapter'number}.yaml|]
                            print file
                            case format of
                              YAML -> encodeFile file ch
                              JSON -> A.encodeFile file ch

      _ -> error $ "failed parse html file "
  where
    doesFilenameMatch :: FilePath -> Bool
    doesFilenameMatch path = takeExtension path `elem` [ ".html", ".HTML"]

-- <a id="footnote-265-903-backlink" class="footnote-link" href="#footnote-265-903">(903)</a>
parseBible :: Map Text Text -> Scraper String [Book']
parseBible refM = chroots ("div" @: [hasClass "content"]) $ inSerial pp
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

parseVerseNum :: Scraper String Int
parseVerseNum = do
       txt <- text "span"
       let num = fromMaybe 0 $ ((readMaybe txt) :: Maybe Int)
       return num
parseVerseRef :: Scraper String Text
parseVerseRef = do
       txt <- T.pack <$> text "a"
       return txt


rr_1 = [PCRE.re|<\s*span[^>]*>(.*?)<\s*/\s*span>|]


-- ref link with the worde before that
refRegex = [PCRE.re|(?:\S+\s)?\S*<\s*a[^>]*>(.*?)<\s*/\s*a>|]
linkRegex = [PCRE.re|<\s*a[^>]*>(.*?)<\s*/\s*a>|]
