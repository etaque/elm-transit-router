module View where

import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import Signal exposing (..)
import Json.Decode as Json

import TransitStyle
import TransitRouter exposing (getTransition)

import Model exposing (..)
import Routes exposing (..)
import TaskPage


view : Address Action -> Model -> Html
view address model =
  div
    [ ]
    [ h1 [] [ text "Elm TransitRouter example" ]
    , div [ class "menu" ]
        [ a (clickTo <| Routes.encode Home) [ text "Home" ]
        , a (clickTo <| Routes.encode (Page 1)) [ text "Page 1" ]
        , a (clickTo <| Routes.encode (Page 2)) [ text "Page 2" ]
        , a (clickTo <| Routes.encode (TaskPage)) [ text "Task" ]
        ]
    , div
        [ class "content"
        , style (TransitStyle.fadeSlideLeft 100 (getTransition model))
        ]
        [ case (TransitRouter.getRoute model) of
            Home ->
              text <| "This is home"
            Page _ ->
              text <| "This is page " ++ toString model.page
            TaskPage ->
              TaskPage.view (Signal.forwardTo address TaskPageAction) model.taskModel
            EmptyRoute ->
              text <| ""
        ]
    ]


-- inner click helper

clickTo : String -> List Attribute
clickTo path =
  [ href path
  , onWithOptions
      "click"
      { stopPropagation = True, preventDefault = True }
      Json.value
      (\_ -> message TransitRouter.pushPathAddress path)
  ]
