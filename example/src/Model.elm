module Model where

import TransitRouter exposing (WithRoute)
import Routes exposing (Route)


type alias Model = WithRoute Route
  { page : Int }

type Action =
  NoOp
  | RouterAction (TransitRouter.Action Route)

