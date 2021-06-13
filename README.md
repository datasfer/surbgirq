![Telegram bot inline mode demo 01](images/inlinequery_mode_01_demo.gif)

# Surbgirq

## Projects

## common
## surbgirq
## surbgirq-api
 - surbgirq-api *
 not used, the hasbolt doesnot support neo4j protocol of version 4.*
 depricated, this project describition of the haskell api to access the neo4j db, but which at this moment
 cannot be used
 - api-client *
 depricated, the surbgirq-api client endpoints

 - surbgirq-api-instances
 the Instances for parse and convert to url the surbgirq types
 this module seperated from surbgirq-api, duplicate, later we will remove this module from surbgir-api
.net core REST API swagger endpoint http://192.0.2.10:33010/swagger/index.html
 - surbgirq-neo4j-client
 Here we describe all endoints using Types (Servant) of .net core web app.
 From Surbgirq.Bot.ClientRequests module we call these endpoints.

 Due to hasbolt do not support new 4.* protocol of neo4j server, we develope the web api using .net core neo4j
 provider which support new protocol and this way we have access to our neo4j graph DB. but all other parts of our
 pp in Haskell, hence we need call that .net web api to get data.

## surbgirq-bot
   Create the bot using botfather https://telegram.me/botfather
 - surbgirq-bot-types
 - surbgirq-bot-state
 - surbgirq-bot-store
 - surbgirq-bot-telegram

## surbgirq-db *
   not used, the hasbolt doesnot support neo4j protocol of version 4.*
## surbgirq-service *
   not used, the hasbolt doesnot support neo4j protocol of version 4.*
## surbgirq-shell
## surbgirq-types
## surbgirq-utils
## surbgirq-web/verse-explorer
 - [front using Lucid package](http://192.0.2.10:8009/)
 - service




# Telegram bot User's manual

## Inline mode

Inline mode in telegram give posibility to post the bot's result without navigate to bot direct messaging.
e.g. entering following commands in any direct chat, grou pchat or channel window you will get the result to choose.
- > @surbgirq Mat 1
Will be the list of all verses from chapter 1 of Matthew, and then you can choose on of vers and it willbe past.
w> @surbgirq Mat 1 4
Will bring exact one verse Mat 1.4, this command can be modified to bring list starting from 4
- > @surbgirq Mat 1 4 12
Will show the list of all verses from chapter 1 of Matthew starting verse 4 till verse 12
- > @surbgirq Mat 1 4:12 or @surbgirq Mat 1 4-12
Will show exactly one item on list which is combined verse starting from 4 to 12
`

## read command





