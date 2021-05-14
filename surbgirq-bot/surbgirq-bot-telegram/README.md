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


check ssl certificate onlien
https://www.geocerts.com/ssl-checker

# let's encrypt

for creating certificate make sure you disable nginx config for your site to
pass acme challange, ususaly for bot webhook you use ssl but for acme challange you need
enable port 80.
for disable just comment your config include in
/etc/nginx/nginx.config
e.g.
`
  include /etc/nginx/conf.d/*.conf;                                                                                                                                                                                                   
  #include /etc/nginx/sites-enabled/*;
`

>> sudo systemctl restart nginx
if get error regarding busy port e.g. nginx: [emerg] bind() to [::]:443 failed (98: Address already in use)

then use command
>> sudo fuser -k 443/tcp

list app listening prts
>> netstat -tulpn 

>>  sudo certbot certonly --nginx -d bot.datasfer.comw
maybe some more folder will have to delete, e.g. /etc/letsencrypt/archive/*
after creating enable nginx config for your bot and reload nginx
>> sudo systemctl restart nginx

To check the status of webhook
>> https://api.telegram.org/botREMOVED-TELEGRAM-TOKEN/getWebHookInfo
sample of reply
{"ok":true,
"result":{"url":"https://bot.datasfer.com/tg-webhook",
"has_custom_certificate":false,
"pending_update_count":4,"last_error_date":1614437701,
"last_error_message":"Connection refused",
"max_connections":40,
"ip_address":"192.0.2.10"}}

## renewal process

>> sudo certbot renew --dry-run
if get error on renewal check the folders
>> ls -la /etc/letsencrypt/renewal/
>> sudo ls -l /etc/letsencrypt/live/

## AUTOMATING THE SSL CERTIFICATE RENEWAL FOR NGINX
>> edit /etc/cron.d/certbot or create it
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

0 */12 * * * root certbot -q renew --nginx


This will run the renew process twice daily, exactly as above when you ran it manually. The -q flag is provided to prevent any output being logged.


# links
https://support.count.ly/hc/en-us/articles/360037816491-Installing-Let-s-Encrypt-for-HTTPS
https://support.count.ly/hc/en-us/articles/360037816431-Configuring-HTTPS-and-SSL