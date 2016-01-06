module Routes where

import Effects exposing (Effects)
import RouteParser exposing (..)
import TransitRouter


type Route
  = Home
  | Page Int
  | TaskPage
  | EmptyRoute


routeParsers : List (Matcher Route)
routeParsers =
  [ static Home "/"
  , dyn1 Page "/page/" int ""
  , static TaskPage "/task"
  ]


decode : String -> Route
decode path =
  RouteParser.match routeParsers path
    |> Maybe.withDefault EmptyRoute


encode : Route -> String
encode route =
  case route of
    Home -> "/"
    Page i -> "/page/" ++ toString i
    TaskPage -> "/task"
    EmptyRoute -> ""

redirect : Route -> Effects ()
redirect route =
  encode route
    |> Signal.send TransitRouter.pushPathAddress
    |> Effects.task
