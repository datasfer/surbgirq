{-|
Module      : Surbgirq.Bot.Server.Webhook
Description : the handlers of GET /version and POST /tg-webhook
-}
module Surbgirq.Bot.Server.Webhook
    ( returnVersion
    , handleWebhook
    ) where

import Control.Monad.Except   (throwError)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Reader   (asks)
import Data.Aeson             ((.:))
import Data.Bits              (xor, (.|.))
import Data.Char              (isAsciiLower, isAsciiUpper, isDigit)
import Data.List              (foldl')
import Data.String            (fromString)
import Data.Text              (Text)
import Data.Version           (makeVersion, showVersion)
import Servant.Server         (err401)
import System.IO              (stderr)

import qualified Data.Aeson         as A
import qualified Data.Aeson.Types   as A (parseMaybe)
import qualified Data.ByteString    as B
import qualified Data.Text          as T
import qualified Data.Text.Encoding as TE

import Surbgirq.Bot.Monad
import Surbgirq.Bot.Server.Handlers
import Surbgirq.Bot.Types
------------------------------------------------------------
--
------------------------------------------------------------


returnVersion :: Bot Version
returnVersion = return version'
  where
    version' = Version $ T.pack $ showVersion $ makeVersion [1,2,3]


-- | POST /tg-webhook. Telegram sends the secret given to setWebhook (secret_token) in the X-Telegram-Bot-Api-Secret-Token
-- header with every update; a request without it, or with another value, gets 401 and isn't handled. An update this
-- library can't decode (it speaks Bot API 3.5) is logged and skipped with 200: a non-2xx answer makes Telegram resend the
-- update and hold back the chat's next ones.
handleWebhook :: Maybe Text -> A.Value -> Bot ()
handleWebhook secretHeader body = do
  secret <- asks webhookSecret
  case secretHeader of
    Nothing -> refuse "no secret token header"
    Just given
      | not (sameSecret secret given) -> refuse "a wrong secret token"
      | otherwise -> case A.fromJSON body of
          A.Success update  -> handleUpdate update
          A.Error   problem -> liftIO $ logLine $
            "Webhook: update " <> updateIdOf body <> " doesn't decode, so it's skipped (200): " <> problem
  where
    refuse :: String -> Bot ()
    refuse what = do
      liftIO $ logLine $ "Webhook: 401 for a request with " <> what
      throwError err401


-- | Compares the header with the secret without stopping at the first difference, so the time it takes doesn't tell
-- how much of a guess was right.
sameSecret :: Text -> Text -> Bool
sameSecret expected given = B.length e == B.length g && foldl' (.|.) 0 (B.zipWith xor e g) == 0
  where
    e = TE.encodeUtf8 expected
    g = TE.encodeUtf8 given


-- | The update's update_id, for the log, or "?" when it has none.
updateIdOf :: A.Value -> String
updateIdOf body = maybe "?" show updateId
  where
    updateId = A.parseMaybe (A.withObject "update" (\o -> o .: fromString "update_id")) body :: Maybe Int


-- | Writes one line to stderr: whitespace runs (line breaks too) become one space, anything shaped like a bot token
-- becomes <token>, and a line over 600 characters keeps its start and its end (an exception's cause is often at the
-- end). Written as one block of UTF-8 bytes, so lines from concurrent requests don't mix and no locale can make it fail.
logLine :: String -> IO ()
logLine = B.hPut stderr . TE.encodeUtf8 . T.pack . (<> "\n") . shorten . redact . unwords . words
  where
    shorten s
      | length s <= 600 = s
      | otherwise       = take 300 s <> " ... " <> drop (length s - 300) s


-- | Replaces anything shaped like a bot token (5 to 16 digits, a colon, then 30 or more letters, digits, _ or -) with
-- <token>, wherever it sits, e.g. in a request path /bot<token>/sendMessage.
redact :: String -> String
redact [] = []
redact text@(c : rest) = case span isDigit text of
    (digits, ':' : afterColon)
      | length digits >= 5, length digits <= 16
      , (key, after) <- span isKeyChar afterColon
      , length key >= 30
      -> "<token>" <> redact after
    _ -> c : redact rest
  where
    isKeyChar ch = isAsciiUpper ch || isAsciiLower ch || isDigit ch || ch == '_' || ch == '-'
