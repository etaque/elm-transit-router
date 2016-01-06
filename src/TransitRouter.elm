module TransitRouter
  ( WithRoute, TransitRouter, Action, Config
  , actions, empty, init, update
  , getRoute, getTransition, pushPathAddress
  ) where

{-|
Drop-in router with transitions for animated, single page apps. See README for usage.

# Types
@docs WithRoute, TransitRouter, Action, Config

# Actions
@docs actions, empty, init, update

# Views
@docs getRoute, getTransition, pushPathAddress
-}


import History
import Effects exposing (Effects, Never, none)
import Task exposing (Task)
import Signal exposing (..)

import Transit
import Response exposing (..)


{-| Type extension for the model. -}
type alias WithRoute route model = { model | transitRouter : TransitRouter route }

{-| State of the router. -}
type TransitRouter route = TR (State route)

type alias State route = Transit.WithTransition
  { route : route
  , path : String
  }

{-| Router actions, wrap it in you own Action type. -}
type Action route =
  NoOp
  | PushPath String
  | PathUpdated String
  | SetRoute route
  | TransitAction (Transit.Action (Action route))


{-| Signal for path updates, feed your app with this as input. -}
actions : Signal (Action route)
actions =
  Signal.mergeMany
    [ Signal.map PathUpdated History.path
    , mailbox.signal
    ]


{-| Private. -}
mailbox : Mailbox (Action route)
mailbox =
  Signal.mailbox NoOp


{-| Address for path updates. Can be used to create a click handler:

    clickTo : String -> List Attribute
    clickTo path =
      [ href path
      , onWithOptions
          "click"
          { stopPropagation = True, preventDefault = True }
          Json.value
          (\_ -> message TransitRouter.pushPathAddress path)
      ]
 -}
pushPathAddress : Address String
pushPathAddress =
  Signal.forwardTo mailbox.address PushPath


{-| Config record for router behaviour:
 * `mountRoute`: what should be the result of a route update (previous route, new route, model) on your model & effects
 * `getDurations`: durations for `Enter` (before `routeUpdate`) and `Exit` (after) phases, same params as `mountRoute`
 * `actionWrapper`: wrapper for router actions into your own action type, to be consistent with `mountRoute` result
 * `routeDecoder`: to transform a path to a route (see `etaque/elm-route-decoder`)
 -}
type alias Config route action model =
  { mountRoute : route -> route -> (WithRoute route model) -> Response (WithRoute route model) action
  , getDurations : route -> route -> (WithRoute route model) -> (Float, Float)
  , actionWrapper : Action route -> action
  , routeDecoder : String -> route
  }


{-| Empty state for model initialisation (route should render nothing, like EmptyRoute). -}
empty : route -> TransitRouter route
empty route =
  TR { route = route, path = "", transition = Transit.initial }


{-| Start the router with this config and an initial path. Returns host's model and action. -}
init : Config route action model -> String -> WithRoute route model -> Response (WithRoute route model) action
init config path model =
  update config (SetRoute (config.routeDecoder path)) model


-- Private: extract state from model
getState : WithRoute route model -> State route
getState model =
  case model.transitRouter of
    TR state -> state


-- Private: set state in model
setState : WithRoute route model -> State route -> WithRoute route model
setState model state =
  { model | transitRouter = TR state }


-- Private: update state in model
updateState : (State route -> State route) -> WithRoute route model -> WithRoute route model
updateState f model =
  (getState >> f >> (setState model)) model


{-| Update the router with this config, for a given action. Returns host's model and action. -}
update : Config route action model -> Action route -> WithRoute route model -> Response (WithRoute route model) action
update config action model =
  case action of

    PushPath path ->
      let
        newModel = updateState (\s -> { s | path = path }) model
        task = History.setPath path
          |> Task.map (\_ -> NoOp)
      in
        taskRes newModel task
          |> mapEffects config.actionWrapper

    PathUpdated path ->
      let
        state = getState model
        newRoute = config.routeDecoder path
        (exit, enter) = config.getDurations state.route newRoute model
        timeline = Transit.timeline exit (SetRoute newRoute) enter
      in
        Transit.init TransitAction timeline (getState model)
          |> mapBoth (setState model) config.actionWrapper

    SetRoute route ->
      let
        state = getState model
        prevRoute = state.route
        newModel = setState model { state | route = route }
      in
        config.mountRoute prevRoute route newModel

    TransitAction transitAction ->
      Transit.update TransitAction transitAction (getState model)
        |> mapBoth (setState model) config.actionWrapper

    NoOp ->
      res model none


{-| Get current route from model -}
getRoute : WithRoute route model -> route
getRoute model =
  getState model |> .route


{-| Get current transition from model.
See etaque/elm-transit for transition handling.
-}
getTransition : WithRoute route model -> Transit.Transition
getTransition model =
  getState model |> .transition
