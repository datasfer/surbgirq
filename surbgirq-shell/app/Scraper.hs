{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE QuasiQuotes         #-}
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE BlockArguments #-}

module Main where

import qualified Data.Text.IO                   as TIO
import qualified Data.Text                   as T
import           GHC.IO.Encoding
import           Surbgirq.Shell.Scraper.Scalpel
import           System.IO
import Text.HTML.Scalpel
import           Control.Applicative
import           Control.Monad
import Data.Char
import Data.List
import Data.Monoid
import Data.Ord
    
import Data.Text(Text)    
import Text.XML.HXT.Core hiding (utf8)
import Text.HandsomeSoup
import Text.XML.HXT.Core (isElem, hasName, getChildren, getText, listA, runX, readDocument, getName)
import Control.Arrow.ArrowTree (deep)
import Control.Arrow ((>>>), (&&&))
import Text.XML.HXT.Arrow.XmlArrow (ArrowXml)
import Text.XML.HXT.DOM.TypeDefs (XmlTree)

atTag :: ArrowXml a => String -> a XmlTree XmlTree
atTag tag = deep (isElem >>> hasName tag)

parseFamous :: ArrowXml a => a XmlTree [(String, String)]
parseFamous = atTag "p" >>> listA (getChildren >>>
                                                   (getName &&& (getChildren >>> getText))
                                  )


hxt = do
  html <- readFile "./data/html/1994/matt_2.html"
  let doc = readString [withParseHTML yes, withWarnings no] html
--  links <- runX $ doc //> hasName "p" >>> css "h3"
  links <- runX  $ doc >>> css "p" >>> hasAttrValue "class" (/= "Parallel-References") //>   getText
  links1 <- runX . xshow  $ doc >>> css "a" >>> hasAttrValue "class" (== "footnote-link")  >>> indentDoc

                       
  mapM_ putStrLn links
  print links1
--  forM_  links1 $ \ls ->
  --    mapM_ (\(a,b) -> do {putStrLn a; putStrLn b})  ls


      
main :: IO ()
main = do
  setLocaleEncoding utf8
  hSetEncoding stdout utf8
  exampleHtml <- readFile "./data/html/1994/matthew.html"
  let ts = scrapeStringLike exampleHtml (parseSerial1) -- (sections <|> sections1)  -- parseSerial --  parse11 -- sections -- <|> sections1) -- parse11
  case ts of
    Just [(t, xs)] -> do
            TIO.putStrLn (T.append "* " t)
            forM_ xs  $ \(h, zs) -> do
                   TIO.putStrLn (T.append "    " h)
                   mapM_ (TIO.putStrLn . T.append "      ") zs
                       
--                    -- forM_ zs  $ \(h, ys) -> do
--                    --    TIO.putStrLn h
-- --                     mapM_ TIO.putStrLn <$>  ys
                      
            
               
 -- setLocaleEncoding utf8
 -- hSetEncoding stdout utf8
  -- ts <- scrapeURLWithConfig utf8Config "https://www.qahana.am/bible/NewTestament/Matthew.html" parseSerial1 -- parse11
  -- TIO.putStrLn "--Գիրք ծննդեան"
  -- case ts of
  --   Nothing   -> TIO.putStrLn "Գիրք ծննդեան"
  --   -- Just [xs] -> do
  --   --         hFile <- openFile "scalpel.out" WriteMode
  --   --         TIO.hPutStrLn hFile "ՀԻՆ ԵՒ ՆՈՐ ԿՏԱԿԱՐԱՆՆԵՐԻ"
  --   --         mapM_ (TIO.hPutStrLn hFile ) xs
  --   --         hClose hFile             
  --   Just [(t, xs)] -> do
  --           TIO.putStrLn (T.append "* " t)
  --           forM_ xs  $ \(h, zs) -> do
  --                  TIO.putStrLn (T.append "    " h)
  --                  mapM_ (TIO.putStrLn . T.append "      ") zs
    -- Just xss -> 
    --     case xss of
    --       [xs] -> do
    --         -- TIO.putStrLn (T.append "* " t)
    --         forM_ xs  $ \(h, zs) -> do
    --                TIO.putStrLn (T.append "    " h)
    --            --    TIO.putStrLn (T.append "    " zs)
    --                print $ show $ length zs
    --                mapM_ (TIO.putStrLn . T.append "      ") zs
    --       [] -> print $ show xss



data Title = Title
 { mvTitle1 :: Text
 , parallel :: Text
 }
  deriving (Show)

  
saveTitles = do
  setLocaleEncoding utf8
  hSetEncoding stdout utf8
  ts <- allTitles
  mapM_ (TIO.putStrLn . T.append "      " . T.pack . show) ts
        
allMovies :: IO (Maybe [Movie])
allMovies = scrapeURLWithConfig config "https://films.criterionchannel.com" movieRoot
  where
    config = Config {decoder = utf8Decoder, manager = Nothing}
    movieRoot :: Scraper Text [Movie]
    movieRoot = chroots "tr" movie
    processText :: Text -> Text
    processText = T.dropAround \c -> getAny $ foldMap (\f -> Any (f c)) [(== '…'), (== ','), isSpace]
    movie :: Scraper Text Movie
    movie = do
      t <- processText <$> text ("td" @: [hasClass "criterion-channel__td--title"])
      d <- processText <$> text ("td" @: [hasClass "criterion-channel__td--director"])
      c <- processText <$> text ("td" @: [hasClass "criterion-channel__td--country"])
      y <- processText <$> text ("td" @: [hasClass "criterion-channel__td--year"])
      pure
        Movie
          { mvTitle = t,
            mvDirector = d,
            mvCountry = c,
            mvYear = y
          }
data Movie
  = Movie
      { mvTitle :: Text,
        mvDirector :: Text,
        mvCountry :: Text,
        mvYear :: Text
      }
  deriving (Show)
           
allTitles :: IO (Maybe [[Title]])
allTitles = scrapeURLWithConfig config "https://www.qahana.am/bible/NewTestament/Matthew.html" movieRoot
  where
    config = Config {decoder = utf8Decoder, manager = Nothing}
    movieRoot :: Scraper Text [[Title]]
    movieRoot = chroots ("section" @: ["id" @= "examples"]) (many movie)
    processText :: Text -> Text
    processText = T.dropAround \c -> getAny $ foldMap (\f -> Any (f c)) [(== '…'), (== ','), isSpace]
    movie :: Scraper Text Title
    movie = do
      t <- processText <$> text ("p" @: [hasClass "Parallel-References"])
      d <- processText <$> text ("h4" @: [hasClass "heading4"])
      -- c <- processText <$> text ("td" @: [hasClass "criterion-channel__td--country"])
      -- y <- processText <$> text ("td" @: [hasClass "criterion-channel__td--year"])
      return $ 
        Title t d 
