{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE QuasiQuotes         #-}
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Surbgirq.Shell.Scraper.Hxt where

import Control.Monad

import qualified Data.Text.IO as TIO
import qualified Data.Text as T
import Data.Text(Text)

import           GHC.IO.Encoding
import           System.IO

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
parseFamous = atTag "section" >>> listA (getChildren >>>
                                                   ( getName  &&& (getChildren >>> getText))
                                  )


hxt = do
  setLocaleEncoding utf8
  hSetEncoding stdout utf8

  html <- readFile "./data/html/1994/matt_2.html"
  let doc = readString [withParseHTML yes, withWarnings no] html
--  links <- runX $ doc //> parseFamous
  links <- runX  $ doc >>> css "p" >>> hasAttrValue "class" (/= "Parallel-References") //>   getChildren >>> getText
--  links1 <- runX . xshow  $ doc >>> css "a" >>> hasAttrValue "class" (== "footnote-link")  >>> indentDoc

                       
  mapM_ putStrLn links
  -- print links1
--  forM_  links $ \ls ->
  --    mapM_ (\t@(a,b) -> TIO.putStrLn $ a) ls 
--               {putStrLn a; putStrLn b})  ls


hxt1 = do
  html <- readFile "./data/html/1994/matt_2.html"
  let doc = readString [withParseHTML yes, withWarnings no] html
  links <- runX  $ doc >>> css "h2" <+> css "h3" <+> css "h4" >>> hasAttrValue "class" (/= "Parallel-References") //> getText
  links1 <- runX . xshow  $ doc >>> css "a" >>> hasAttrValue "class" (== "footnote-link")  >>> indentDoc
  links2 <- runX  $ doc >>> multi  (this &&& (getName ))
  mapM_ putStrLn links
  print links2

hxt2= do
  html <- readFile "./data/html/1994/matt_2.html"
  let doc = readString [withParseHTML yes, withWarnings no] html
  ls <- runX  $ doc >>> css "section" >>> hasAttrValue "class" (/= "Parallel-References") >>>  (getChildren >>>
                                                   ( getName  &&& (getChildren >>> getText))
                                  )

  mapM_ (\t@(a,b) -> putStrLn $ show t) ls 
--               {putStrLn a; putStrLn b})  ls


