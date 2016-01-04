module Routes where

import RouteParser exposing (..)


type Route
  = Home
  | Page Int
  | EmptyRoute


routeParsers : List (Matcher Route)
routeParsers =
  [ static Home "/"
  , dyn1 Page "/page/" int ""
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
    EmptyRoute -> ""
