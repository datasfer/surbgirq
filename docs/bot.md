# The Telegram bot

`@SurbgirqBot` answers Bible references with the verse text, in a private chat or, in inline mode, in any chat. It is the
`telegram-bot` executable (`surbgirq/app/TelegramBot.hs`), built on the `surbgirq-bot/*` packages and a fork of the
`telegram-api` library ([build.md](build.md)).

## Using it

**In a private chat:**

| Message | Answer |
|---|---|
| `/start`, `/settings` | the settings keyboard |
| `/help` | the list of commands |
| a reference, e.g. `Ղուկ. 6.20-23` or `Mat 1 4` | the verse or verses |
| `/verse <reference>` | the same |
| `/chapter <reference>` | a chapter, by its sections |
| `/books`, `/books <book>` | the list of books, or one book |
| `/today`, `/random`, `/mihatov` | placeholders that show the book list |
| `/md`, `/html` | formatting tests |

**In inline mode,** type `@SurbgirqBot` and a reference in any chat, then pick a result to post it:

| Query | Results |
|---|---|
| `Mat 1` | the whole chapter, one verse per result, 50 per page |
| `Mat 1 4` | one verse |
| `Mat 1 4 12` | verses 4 to 12, one per result |
| `Mat 1 4:12` or `Mat 1 4-12` | verses 4 to 12 as one result |
| `kjv mat 1 4` | the same, in the translation named first |
| `read Mat 1` | a reading view with previous and next buttons |
| nothing | a button that opens the settings |

Telegram may cache inline results for 333 seconds.

## References

`parseVerseRef` (`surbgirq-utils`) reads a reference as:

1. an optional **translation word**, e.g. `e1994`, `v1805`, `z1805`, `kjv` (all of them: `Surbgirq.Types.Abbreviation.TranslationIDAbbr`);
2. a **book** name or abbreviation, in Armenian or English (`Surbgirq.Types.Abbreviation.GirqAbbr`);
3. up to three **numbers**: the chapter, the first verse, the last verse.

- Any non-digit between the numbers separates them, so `Ղուկ. 6.20-23`, `Ղուկ 6 20 23` and `Luke 6:20-23` read the same.
- A `:` or `-` anywhere in the reference joins a verse range into one result, in inline mode.
- **Without a translation word, the book abbreviation decides the translation:** Armenian abbreviations (`Մատթ`, `Մատ`,
  `Մտ`) mean the 1994 translation, English ones (`Mat`, `Luke`) the KJV. The user's translation setting doesn't change this
  yet (README, Known issues). For the Zohrab text, put the translation word first: `v1805 Մատթ 1`.

## Settings

Per user, kept in memory (lost on restart): the Bible translation (Classical or modern Armenian, Russian Synodal, English), parallel
translations, the Narek translation, parallel Nareks, and the menu language (Armenian, Russian, English).

## Running it

1. **A bot and its token.** Create a bot with [@BotFather](https://t.me/BotFather). The token is hard-coded in
   `surbgirq-bot/surbgirq-bot-telegram/src/Surbgirq/Bot/Telegram.hs`; the public copy has `REMOVED-TELEGRAM-TOKEN` there.
   Put your token in its place, and don't commit it. Reading it from the environment is the first planned fix (README,
   Known issues).
2. **The data.** The graph in Neo4j ([neo4j-import.md](neo4j-import.md)), and
   [`surbgirq-graph-api`](https://github.com/datasfer/surbgirq-graph-api) on `http://localhost:33010`, or wherever
   `GRAPH_API_URL` points: the API's root, without `/api`.
3. **The configuration,** `surbgirq/config/bot-settings.yaml`:

   ```yaml
   bots:
     telegram:
       dbName: "db/telebot"
       botApiHost: "_env:BOT_API_URL:api.telegram.org"
       botApiPort: _env:BOT_API_PORT:443
       graphApiUrl: "_env:GRAPH_API_URL:http://localhost:33010"
   ```

   `_env:NAME:default` reads an environment variable, with a default. Set `BOT_API_URL` and `BOT_API_PORT` only for a
   self-hosted Bot API server (below).
4. **Start it** from the `surbgirq/` package folder inside the repository: `cd surbgirq && stack exec -- telegram-bot`. It serves `GET /version` and `POST /tg-webhook` on port 5000.
5. **HTTPS and the webhook.** Telegram delivers webhooks over HTTPS only, on port 443, 80, 88 or 8443. The author ran nginx
   with a Let's Encrypt certificate in front of the bot:

   ```nginx
   server {
       server_name bot.example.org;
       listen 443 ssl http2;
       ssl_certificate     /etc/letsencrypt/live/bot.example.org/fullchain.pem;
       ssl_certificate_key /etc/letsencrypt/live/bot.example.org/privkey.pem;

       location / {
           proxy_set_header Host $http_host;
           proxy_set_header X-Forwarded-Proto https;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_pass http://127.0.0.1:5000/;
       }
   }
   ```

   Get the certificate with `sudo certbot --nginx -d bot.example.org`, and test its renewal with
   `sudo certbot renew --dry-run`. Then register the webhook, and check it:

   ```text
   https://api.telegram.org/bot<token>/setWebhook?url=https://bot.example.org/tg-webhook
   https://api.telegram.org/bot<token>/getWebhookInfo
   ```

   When delivery fails, `getWebhookInfo` shows why in `last_error_message`, e.g. "Wrong response from the webhook: 500
   Internal Server Error" or "Connection refused".

## A self-hosted Bot API server

[`docker/telegram-bot-api/`](../docker/telegram-bot-api/README.md) builds Telegram's own Bot API server. To move the bot to it:
log the bot out of the cloud server once (`https://api.telegram.org/bot<token>/logOut`), start the local server, and set
`BOT_API_URL` and `BOT_API_PORT`. The bot always uses HTTPS for the Bot API, so the local server needs a TLS proxy in front.

## The API the bot calls

`Surbgirq.Bot.ClientRequests` calls the graph API at `GRAPH_API_URL` (default `http://localhost:33010`), on
`surbgirq-graph-api`'s `/api/…` routes, through one HTTP client made at start-up; a URL that isn't valid, or that ends in
`/api`, stops the bot and the verse explorer with a message. Four of the routes don't match the API yet (README, Known
issues). Until 2026 the bot called the 2020 .NET API's routes, e.g.
`/scripture/{translation}/books/{book}/chapters/{chapter}/verses/{from}?v2={to}`.

## Facebook Messenger

A Messenger integration from 2020 (`Surbgirq.Bot.FB.*` and the `fbmessenger-api-hs` fork) is dead code; its packages are
commented out of the build.
