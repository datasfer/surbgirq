{-# LANGUAGE ExtendedDefaultRules #-}
{-# LANGUAGE OverloadedStrings    #-}
{-# OPTIONS_GHC -fno-warn-type-defaults #-}
module Lucid.Helper where

import Lucid.Base
import Lucid.Html5

import Data.Text          (pack, unpack)
import Data.Text.Internal (Text)
import Text.Casing        (kebab)


metas :: Html()
metas = meta_ []


css :: Monad m => Text -> HtmlT m ()
css name = link_ [rel_ "stylesheet", type_ "text/css", href_ name]

js :: Monad m => Text -> HtmlT m ()
js script = (script_ [src_ script] "")

jquery :: Monad m => HtmlT m ()
jquery = do (js "/static/js/jquery-3.3.1.min.js")

-- https://fezvrasta.github.io/bootstrap-material-design/docs/4.0/bootstrap-components/buttons/
materialjs :: Monad m => HtmlT m ()
materialjs = (js "/static/js/bootstrap-material-design.min.js")

-- https://mdbootstrap.com/components/buttons/
mdbjs :: Monad m => HtmlT m ()
mdbjs = do (js "/static/js/bootstrap.js")
           (js "/static/js/mdb.js")


commonjs :: Monad m => HtmlT m ()
commonjs = do (js "/static/js/popper.js")
              (js "/static/js/fontawesome-all.min.js")
              (js "/static/js/jsonFormatter.min.js")
              (js "/static/js/micromodal.min.js")

appjs :: Monad m => HtmlT m ()
appjs = js "/static/js/app.js"

materialcss :: Monad m => HtmlT m ()
materialcss = do (css "/static/css/bootstrap-material-design.min.css")

mdbcss :: Monad m => HtmlT m ()
mdbcss = do (css "/static/css/bootstrap.css")
            (css "/static/css/mdb.css")

commoncss :: Monad m => HtmlT m ()
commoncss = do (css "/static/css/normalize.css")
               (css "/static/css/skeleton.css")
               (css "/static/css/custom.css")
               (css "/static/css/jsonFormatter.min.css")
               (css "/static/css/micromodal.css")


allCSS :: Monad m => HtmlT m ()
allCSS = do mdbcss
            commoncss

allJS :: Monad m => HtmlT m ()
allJS = do jquery
           mdbjs
           commonjs
           appjs


footer :: Monad m => HtmlT m ()
footer = footer_ [class_ "footer"] $ do
           p_ $ do
             (small_ "Scripture Corpora © 2020 ")


mkPage ::  Monad m => HtmlT m () -> HtmlT m ()
mkPage body = do
      doctype_
      html_ $ do
        head_ $ do
          title_ "Scripture Explorer."
          meta_ [name_ "viewport", content_ "width=device-width, initial-scale=1"]
          link_ [rel_ "icon", type_ "image/png", href_ "/static/img/cross-blue.png"]
          allCSS
        body_ $ do
            nav_ [class_ "navbar navbar-expand-lg navbar-dark primary-color"] navBar
            div_ [class_ "clear"] ""
            div_ [class_ "container"] body
            footer
            allJS


dropDownMenu :: Monad m => Text -> Text -> [Menu] -> HtmlT m ()
dropDownMenu menuStyle name items =
  with li_ [class_ menuStyle] $ do
    withA_ (do toHtml name; (span_ [class_ "caret"] ""))
    with div_ [class_ "dropdown-menu dropdown-primary"]  $ do
                                  (mapM_ mkMenu_ items)
  where
    withA_ = with a_ [  href_ "#"
                  , class_ "nav-link dropdown-toggle"
                  , data_toggle_ "dropdown"
                  , role_ "button"
                  , aria_haspopup_ "true"
                  , aria_expanded_ "false"
                 ]

-- | The @mkMenu_@ function.
mkMenu_ :: Monad m => Menu -> HtmlT m ()
mkMenu_ (Logo txt url) =
  with li_ [class_ "nav-item"] $
  with a_ [class_ "nav-link", href_ url] $ do
    img_ [src_ "/static/img/cross-transparent.png", style_ "width: 35px;"]
    toHtml txt
mkMenu_ (Counter _txt url) =
  with li_ [class_ "nav-item"] $
  a_ [class_ "nav-link", href_ url] $ do span_ [id_ "block_count", class_ "block-counter"] "*"
mkMenu_ (Menu txt url) =
  with li_ [class_ "nav-item"] $ a_ [class_ "nav-link", href_ url, id_ (mkId txt)] (toHtml txt)
  where
    mkId text = pack $ kebab $ "menu " ++ unpack text
mkMenu_ (JsMenu txt txtId) =
    with li_ [class_ "nav-item"] $
         a_ [class_ "nav-link", makeAttribute "data-micromodal-trigger" "modal-1", href_ "#", id_ txtId] (toHtml txt)

mkMenu_ (DropDown name ms) = dropDownMenu "nav-item dropdown" name ms
mkMenu_ (DropDownItem txt url) = a_ [class_ "dropdown-item", href_ url] (toHtml txt)
mkMenu_ (SubMenu name ms) = dropDownMenu "dropdown-submenu" name ms


-- | The @navBar@ html element.
navBar :: Monad m => HtmlT m ()
navBar = do
  a_ [class_ "navbar-brand", href_ "/#"] $ do
           img_ [src_ "/static/img/cross-transparent.png", style_ "width: 35px;"]
  button_ [class_ "navbar-toggler",  type_ "button", data_toggle_ "collapse", data_target_ "#bexNav",
               aria_controls_ "bexNav", aria_expanded_ "false", aria_label_ "Toggle navigation"] $
          span_ [class_ "navbar-toggler-icon"] ""
  div_ [id_ "bexNav", class_ "navbar-collapse collapse" ] $ do
           ul_ [class_ "navbar-nav mr-auto"] (mapM_ mkMenu_ siteMenu )
           form_ [action_ "/search", method_ "post", class_ "form-inline", style_ "margin-bottom: auto;"] $
               div_ [class_ "md-form", style_ "display: inline;"] $ do
                 input_ [class_ "form-control mr-sm-2", style_ "width: 300px;",  type_ "text", name_ "word", placeholder_ "search", id_ "txhash", aria_label_ "Search"]
                 button_ [class_ "btn btn-primary", type_ "submit", style_ "margin-top: auto;", value_ "Search"] "Search"


-- | The @Url@ type.
type Url = Text

-- | The @Menu@ recursive data.
data Menu = Counter Text Url
          | Logo Text Url
          | Menu Text Url
          | DropDown Text [Menu]
          | DropDownItem Text Url
          | SubMenu Text [Menu]
          | JsMenu Text Text -- menu name and id

-- | The @siteMenu@ structure.
siteMenu :: [Menu]
siteMenu = [ -- Counter "" "/#"
             Menu "e1994" $ "/scripture/e1994/books"
           , Menu "v1805" $ "/scripture/v1805/books"
           , Menu "KJV" $ "/scripture/kjv/books"
           --                , JsMenu "Filter" "filter_menu"
           , DropDown "Books" [ DropDownItem "e1994" "/scripture/e1994/books"
                              , DropDownItem "v1805" "/scripture/v1805/books"
                              , DropDownItem "KJV"  "/scripture/kjv/books"
                              ]
           , Menu "About" "/about"
           ]

-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------

aria_label_ :: Text -> Attribute
aria_label_ = makeAttribute "aria-label"


-- | The @data_toggle@ attribute.
data_toggle_ :: Text -> Attribute
data_toggle_ = makeAttribute "data-toggle"

-- | The @data_toggle@ attribute.
data_target_ :: Text -> Attribute
data_target_ = makeAttribute "data-target"

-- | The @data_method@ attribute.
data_method_ :: Text -> Attribute
data_method_ = makeAttribute "data-method"

-- | The @data_confirm@ attribute.
data_confirm_ :: Text -> Attribute
data_confirm_ = makeAttribute "data-confirm"

-- | The @data_tag@ attribute.
data_tag_ :: Text -> Attribute
data_tag_ = makeAttribute "data-tag"

-- | The @tag@ attribute.
tag_ :: Text -> Attribute
tag_ = makeAttribute "tag"

-- | The @aria-haspopup@ attribute.
aria_haspopup_ :: Text -> Attribute
aria_haspopup_ = makeAttribute "aria-haspopup"

-- | The @aria-expanded@ attribute.
aria_expanded_ :: Text -> Attribute
aria_expanded_ = makeAttribute "aria-expanded"

-- | The @aria-controls@ attribute.
aria_controls_ :: Text -> Attribute
aria_controls_ = makeAttribute "aria-controls"
