module FamilyTreeViewer exposing (..)

import View
import Viz

import Browser
import Browser.Dom
import Http
import Url exposing (Url)
import Url.Parser
import Url.Parser.Query

type Msg
  = UI View.Msg
  | GraphText (Result Http.Error String)

type alias Model =
  {
  }

main = Browser.document
  { init = init
  , update = update
  , subscriptions = subscriptions
  , view = View.document UI
  }

init : String -> (Model, Cmd Msg)
init fragment =
  let
    url = (Url Url.Http "" Nothing "" Nothing (Just (String.dropLeft 1 fragment)))
  in
  ( { 
    }
  , extractHashArgument "gv" url
    |> Maybe.map (\targetUrl -> Http.get
      { url = targetUrl
      , expect = Http.expectString GraphText
      }
    )
    |> Maybe.withDefault Cmd.none
  )

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    UI (View.None) -> (model, Cmd.none)
    GraphText (Ok text) ->
      (model, Viz.renderGraphviz text)
    GraphText (Err error) ->
      let _ = Debug.log "fetch graph failed" error in
      (model, Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

extractHashArgument : String -> Url -> Maybe String
extractHashArgument key location =
  { location | path = "", query = location.fragment }
    |> Url.Parser.parse (Url.Parser.query (Url.Parser.Query.string key))
    |> Maybe.withDefault Nothing