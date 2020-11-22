module Surbgirq.Bot.Server.Imports.TelegramAPI
    ( module  TelegramBotApi
    )where


import Web.Telegram.API.Bot as TelegramBotApi hiding
    ( answerCallbackQuery
    , answerCallbackQueryM
    , answerInlineQuery
    , answerInlineQueryM
    , editInlineMessageCaption
    , editInlineMessageCaptionM
    , editInlineMessageReplyMarkup
    , editInlineMessageReplyMarkupM
    , editInlineMessageText
    , editInlineMessageTextM
    , editMessageCaption
    , editMessageCaptionM
    , editMessageLiveLocationM
    , editMessageReplyMarkup
    , editMessageReplyMarkupM
    , editMessageText
    , editMessageTextM
    , forwardMessage
    , forwardMessageM
    , sendAudio
    , sendAudioM
    , sendChatAction
    , sendChatActionM
    , sendContact
    , sendContactM
    , sendDocument
    , sendDocumentM
    , sendGame
    , sendGameM
    , sendLocation
    , sendLocationM
    , sendMediaGroupM
    , sendMessage
    , sendMessageM
    , sendPhoto
    , sendPhotoM
    , sendSticker
    , sendStickerM
    , sendVenue
    , sendVenueM
    , sendVideo
    , sendVideoM
    , sendVideoNote
    , sendVideoNoteM
    , sendVoice
    , sendVoiceM
    , stopMessageLiveLocationM
    , uploadAudio
    , uploadAudioM
    , uploadDocument
    , uploadDocumentM
    , uploadPhoto
    , uploadPhotoM
    , uploadSticker
    , uploadStickerM
    , uploadVideo
    , uploadVideoM
    , uploadVideoNote
    , uploadVideoNoteM
    , uploadVoice
    , uploadVoiceM
    )
