

module Surbgirq.Shell.Theographic.JSON.Converter where

import Data.Aeson

import qualified Data.ByteString.Lazy as B

import Surbgirq.Shell.Theographic.JSON.Types


jsonFile = "./data/theodata/json/books.json"

getJSON :: IO B.ByteString
getJSON = B.readFile jsonFile


readBooks = do
  content <- getJSON
  let d = eitherDecode content :: Either String [TheoBook]
  --  d <- (eitherDecode <$> getJSON) :: IO (Either String [TheoBook])
  case d of
        Left err -> putStrLn err
        Right ps -> print ps


readChapters = do

  content <- B.readFile "./data/theodata/json/chapters.json"
  let d = eitherDecode content :: Either String [TheoChapter]
  --  d <- (eitherDecode <$> getJSON) :: IO (Either String [TheoBook])
  case d of
        Left err -> putStrLn err
        Right ps -> print ps

readVerse = do

  content <- B.readFile "./data/theodata/json/verses.json"
  let d = eitherDecode content :: Either String [TheoVerse]
  --  d <- (eitherDecode <$> getJSON) :: IO (Either String [TheoBook])
  case d of
        Left err -> putStrLn err
        Right ps -> print ps
