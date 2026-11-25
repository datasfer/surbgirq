{-# LANGUAGE ApplicativeDo     #-}
{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE FlexibleContexts  #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}

module Surbgirq.Shell.Scraper.Scalpel.JupyterHtml.ZohrapScraper (parseZohrapHtml, parseAR94Html) where


import Data.Text (Text)

import Control.Monad.Except          (MonadError, MonadIO, catchError, liftIO)
import Control.Monad.IO.Class        (liftIO)
import Data.Maybe                    (fromMaybe)
import Text.InterpolatedString.Perl6 (qc)
import Text.Read                     (readMaybe)

import           Control.Applicative
import           Control.Monad
import           Control.Monad.IO.Class
import qualified Data.Aeson             as A
import           Data.List
import           Data.List.Split
import qualified Data.Text              as T
import qualified Data.Text.Encoding     as TE
import qualified Data.Text.IO           as TIO
import           GHC.Generics
import           GHC.IO.Encoding
import           System.Directory
import           System.FilePath
import           System.IO
import           Text.HTML.Scalpel

import           Data.Yaml
import           Text.RawString.QQ

import           Common.Aeson
import qualified Surbgirq.Shell.Scraper.Tags as Tags
import           Surbgirq.Shell.Types
import           Surbgirq.Utils
-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------

data BookData = BookData
 { bookData'title    :: Text
 , bookData'chapters :: [Chapter]
 } deriving (Show, Generic)

data OutFormat =  YAML
                | JSON

instance ToJSON BookData
-- test :: IO ()
-- test = do
--   setLocaleEncoding utf8
--   hSetEncoding stdout utf8
--   exampleHtml <- readFile "../data/test/zohrap.html"
--   let ts = scrapeStringLike exampleHtml parseNarekHtml
--   case ts of
--     Just xs -> do
--             encodeFile "../data/test/zohrap-gen-parseHtml.yaml" xs
--             -- XShFile <- openFile "../data/test/zohrap-scalpel.out" WriteMode
--             return ()
-- --            forM_ xs (printBook hFile)
--     Nothing -> error $ "failed parse html file "



-- | for running from ghci load
zohrapTest :: IO ()
zohrapTest = parseZohrapHtml "../data/html/z1805" "../data/yaml"

ar94Test :: IO ()
ar94Test = parseJupterGeneratedHtml "bible/am/ar94" "../data/html/ar94" "../data/yaml"

eTest :: IO ()
eTest = parsee1994Html "./data/e1994/html" "./data/yaml"
eTest1 = parseJupterGeneratedHtml "" "./data/e1994/html" "./data/e1994/yaml"


parseZohrapHtml  = parseJupterGeneratedHtml "bible/am/z1805"
parseAR94Html  = parseJupterGeneratedHtml "bible/am/ar94"
parsee1994Html  = parseJupterGeneratedHtml "bible/am/e1994-J"


-- | stack exec -- html-scraper --z1805  --yaml  -i ./data/html/z1805 -o ./data/yaml
-- parseZohrapHtml "../data/html/z1805" "../data/yaml"
parseJupterGeneratedHtml :: FilePath -> FilePath -> FilePath -> IO ()
parseJupterGeneratedHtml outSubPath dataRootPath   outPutPath = do
  setLocaleEncoding utf8
  hSetEncoding stdout utf8
  let datDir = dataRootPath </> "New"
      datDirOld = dataRootPath </> "Old"
      outRootDir = outPutPath </> outSubPath -- "bible/am/z1805"
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

    let ts = scrapeStringLike htmlText parseNarekHtml

    case ts of
      Just xs  -> do
              encodeFile "parseHtml.yaml" xs
              -- A.encodeFile "parseHtml.json" xs
              print $  length xs

              when (length xs > 0) $ do
                let outDir = outRootDir </> lastFolderName </> (takeBaseName file)
                createDirectoryIfMissing True outDir

                forM_ xs $ \BookData{..} -> do
                  forM_ bookData'chapters $ \ ch@Chapter{..} -> do
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
    doesFilenameMatch path = takeExtension path `elem` [ ".txt", ".html", ".HTML"]


parseNarekHtml :: Scraper String [BookData]
parseNarekHtml = chroots ("div" @: [hasClass "content"]) $ inSerial innerScraper
  where
    innerScraper = do
       chapters <- many $ do

         chapter <- seekNext $ text "h3" -- <|> return "****************"
         let chNum = fromMaybe 0 $ ((readMaybe   chapter) :: Maybe Int)

         sections <- untilNext (matches "h3") $
                     many $ do
            (s_num, sectionTitle) <- (seekNext parseSection) -- $ T.pack <$> text "h4")
            let secNum = fromArmenianNumber $ T.unpack sectionTitle

            p_ref <- (seekNext $ T.pack <$> text ("p" @: [hasClass "Parallel-References"]))  <|> return "ref empty"

            ps <- untilNext (matches "h4") $ many $ seekNext $ parseVerse1

            return $ Section sectionTitle s_num p_ref $  concat ps
         -- let secs = zipWith (\n s@(Section{section'number = m}) -> s{section'number = secNum}) [1..] sections
         return $ Chapter chNum "" "" sections
       return $ BookData "" chapters


parseSection :: Scraper String (Int, Text)
parseSection = do
  let tag  = "h4"
  title <- T.pack <$> innerHTML tag
  numTxt <- (attr "sec-num" tag)
  let secNum = fromMaybe 0 $ ((readMaybe   numTxt) :: Maybe Int)
 -- h4 <- text "p4"
  return  (secNum, title)


parseVerse1 :: Scraper String [Verse]
parseVerse1 = do
  let del = "\160"
      pTag = "p"  @: [hasClass "verse-text"]
--
  verse <- T.pack <$> innerHTML pTag
--  vNums <- chroots ("p" // "span" @:  [hasClass "Numeral"]) $ parseVerseNum
  versRefs <- chroots ("p" // "a" @:  [hasClass "footnote-link"]) $ parseVerseRef
  numTxt <- (attr "verse-num" pTag)
  let num = fromMaybe 0 $ ((readMaybe  numTxt) :: Maybe Int)

  refNum <- (attr "ref-num" pTag)
  refText <- (attr "ref-text" pTag)


  let vs = filter (not . T.null) $ Tags.splitAtElements "span" verse

--  let xs = map (\(num, v) -> VerseData [] (versRefs) rs (T.pack $ show num) v $ T.pack verse)  (zip [4..] vs)
  let xs = map (\verse ->
                    let v = removeLinkTag verse
                        v1 = removeDivTag v
                        vref = case (refNum, refText) of
                                 ([], _)  -> []
                                 (_, [])  -> []
                                 (rn, rt) ->  [toVerseRef rn rt]
                    in Verse num v1  vref)
           vs
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
    toVerseRef :: String -> String -> VerseRef
    toVerseRef key footnote = VerseRef 0 (RefVerseEnd (T.pack key) (T.pack footnote) )


removeLinkTag :: Text -> Text
removeLinkTag = Tags.removeElements "a"

removeDivTag :: Text -> Text
removeDivTag = Tags.removeElements "div"

-- this commented becuase of bump to ghc: 9.4.8, seems the order of instancing is matter, added 
-- tojson instance declaration above
-- $(deriveJSON dropPrefixOptions ''BookData)
