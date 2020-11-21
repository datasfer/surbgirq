{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}


module Surbgirq.Bot.Server.Helpers.Pagination where

import Data.Text                     (Text)
import Text.InterpolatedString.Perl6 (qc)

import Web.Telegram.API.Bot

import qualified Data.Text as T (pack, unpack)


mkInlineBtn :: Text -> Text -> InlineKeyboardButton
mkInlineBtn caption callback_data = InlineKeyboardButton caption Nothing (Just callback_data) Nothing Nothing Nothing Nothing



generatePageBtns :: Int -> Int -> Int -> String -> String -> [[InlineKeyboardButton]]
generatePageBtns i page pages cmd category
      | i == pages = do return []
      | i == page = do
            next <- generatePageBtns (i + 1) page pages cmd category
            let cqData = [qc|no_reply|]
                btnText = [qc|. {page + 1} .|]
            return $ mkInlineBtn btnText cqData : next
      | i == 0 = do
            next <- generatePageBtns (i + 1) page pages cmd category
            let cqData = [qc|{cmd} {category} 1|]
                btnText = [qc|« 1|]
            return $ mkInlineBtn btnText cqData : next
      | i == pages - 1 = do
            next <- generatePageBtns (i + 1) page pages cmd category
            let cqData = [qc|{cmd} {category} {pages-1}|]
                btnText = [qc|{pages} »|]
            return $ mkInlineBtn btnText cqData : next

      | (i < page) && (page - i) <= (max 1 (4 - pages + page)) =  do
             next <- generatePageBtns (i + 1) page pages cmd category
             let cqData = [qc|{cmd} {category} {i}|]
                 btnText = [qc|‹ {i + 1}|]
             return $ mkInlineBtn btnText cqData : next

      | (i > page) && (i - page) <= (max 1 (3 - page)) =  do
              next <- generatePageBtns (i + 1) page pages cmd category
              let cqData = [qc|{cmd} {category} {i}|]
                  btnText = [qc|{i + 1} ›|]
              return $ mkInlineBtn btnText cqData : next

      |  otherwise = generatePageBtns (i + 1) page pages cmd category



prevNextPageBtns :: Int -> Int -> String -> String -> [[InlineKeyboardButton]]
prevNextPageBtns  pageIndex totalPages cmd args
      | pageIndex == totalPages = do
           let prevCmd = [qc|{cmd} {args} {pageIndex - 1}|]
               prev = mkInlineBtn "<<" prevCmd
           return [prev]
      | pageIndex == 1 = do
           let nextCmd = [qc|{cmd} {args} {pageIndex + 1}|]
               next = mkInlineBtn ">>" nextCmd
           return [next]
      | otherwise = do
           let prevCmd = [qc|{cmd} {args} {pageIndex - 1}|]
               nextCmd = [qc|{cmd} {args} {pageIndex + 1}|]
               prev = mkInlineBtn "<<" prevCmd
               next = mkInlineBtn ">>" nextCmd
           return [prev, next]

