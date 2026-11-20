# A self-hosted Telegram Bot API server

Files to build Telegram's own [Bot API server](https://github.com/tdlib/telegram-bot-api) in Docker, so the bot can use it
instead of `api.telegram.org`. The bot doesn't need it; it works with the cloud server.

| File | What it is |
|---|---|
| `Dockerfile` | Builds `telegram-bot-api` from source on Alpine 3.7 and starts it with `--local --http-port=8009` |
| `Dockerfile_low_memory_build` | The same, but splits tdlib's sources before compiling (`php SplitSource.php`), for machines with little memory |
| `docker-entrypoint.sh` | An alternative start command (`--http-port 8081`); the Dockerfiles don't use it |

- **Credentials:** the server needs a Telegram API ID and hash from [my.telegram.org](https://my.telegram.org), passed as
  `TELEGRAM_API_ID` and `TELEGRAM_API_HASH`.
- **Port 8009** is also the verse explorer's port; change one of them if both run on the same machine.
- **To move the bot to it:** see [docs/bot.md](../../docs/bot.md#a-self-hosted-bot-api-server). The bot talks HTTPS to the Bot
  API, so put a TLS proxy in front of this server.

Build instructions for other systems: the official
[build instructions generator](https://tdlib.github.io/telegram-bot-api/build.html?os=Linux). Ready-made images and
Dockerfiles exist too, e.g. [aiogram/telegram-bot-api](https://github.com/aiogram/telegram-bot-api).
