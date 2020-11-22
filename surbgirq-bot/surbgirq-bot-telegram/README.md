# surbgirq-bot

# Facebook





# Telegram

## set webhook
https://api.telegram.org/bot<token>/setWebhook?url=https://bot.datasfer.com/tg-webhook

## get webhook info
request:
https://api.telegram.org/bot<token>/getWebHookInfo

https://api.telegram.org/botREMOVED-TELEGRAM-TOKEN/getWebHookInfo
https://api.telegram.org/botREMOVED-TELEGRAM-TOKEN/setWebhook?url=https://bot.datasfer.com/tg-webhook

response:
{
    "ok": true,
    "result": {
        "url": "https://bot.datasfer.com/tg-webhook",
        "has_custom_certificate": false,
        "pending_update_count": 0,
        "max_connections": 40
    }
}

{
    "ok": true,
    "result": {
        "url": "https://bot.datasfer.com/goat",
        "has_custom_certificate": false,
        "pending_update_count": 0,
        "last_error_date": 1596900179,
        "last_error_message": "Wrong response from the webhook: 500 Internal Server Error",
        "max_connections": 40
    }
}

## bot info
https://api.telegram.org/bot<token>/getMe


## local BOT API server

- logout cloud Bot API server
https://api.telegram.org/botREMOVED-TELEGRAM-TOKEN/logOut
