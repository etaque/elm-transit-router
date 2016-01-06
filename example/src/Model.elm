module Model where

import TransitRouter exposing (WithRoute)
import Routes exposing (Route)
import TaskPage exposing (Model, Action)


type alias Model = WithRoute Route
  { page : Int
  , taskModel : TaskPage.Model}


type Action =
  NoOp
  | TaskPageAction TaskPage.Action
  | RouterAction (TransitRouter.Action Route)
