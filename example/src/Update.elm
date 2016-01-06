module Update where

import Effects exposing (Effects, none)
import TransitRouter

import Model exposing (..)
import Routes exposing (..)
import TaskPage


initialModel : Model
initialModel =
  { transitRouter = TransitRouter.empty EmptyRoute
  , page = 0
  , taskModel = TaskPage.init
  }


actions : Signal Action
actions =
  -- use mergeMany if you have other mailboxes or signals to feed into StartApp
  Signal.map RouterAction TransitRouter.actions


routerConfig : TransitRouter.Config Route Action Model
routerConfig =
  { mountRoute = mountRoute
  , getDurations = \_ _ _ -> (50, 200)
  , actionWrapper = RouterAction
  , routeDecoder = Routes.decode
  }


init : String -> (Model, Effects Action)
init path =
  TransitRouter.init routerConfig path initialModel


update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of

    NoOp ->
      (model, Effects.none)

    TaskPageAction taskAction ->
      let (model', effects) = TaskPage.update taskAction model.taskModel
      in ( { model | taskModel = model' }
         , Effects.map TaskPageAction effects )

    RouterAction routeAction ->
      TransitRouter.update routerConfig routeAction model


mountRoute : Route -> Route -> Model -> (Model, Effects Action)
mountRoute prevRoute route model =
  case route of

    -- in a typical SPA, you might have to trigger tasks when landing on a page,
    -- like an HTTP request to load specific data

    Home ->
      (model, Effects.none)

    Page p ->
      ({ model | page = p }, Effects.none)

    TaskPage ->
      (model, Effects.none)

    EmptyRoute ->
      (model, Effects.none)

