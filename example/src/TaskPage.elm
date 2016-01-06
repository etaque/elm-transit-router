module TaskPage where

import Effects exposing (Effects)
import Html exposing (div, text, button, Html)
import Html.Events exposing (onClick)
import Routes
import Signal
import Task


type alias Model = ()


init : Model
init = ()


type Action =
  NoOp
  | TaskStarted
  | TaskCompleted (Maybe Int)


update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    NoOp ->
      ( model
      , Effects.none)
    TaskStarted ->
      (model, myTask )
    TaskCompleted _ ->
      ( model
      , Effects.map (\_ -> NoOp) (Routes.redirect Routes.Home)
      )

view : Signal.Address Action -> Model -> Html
view address model =
  div [] [ button
           [ onClick address TaskStarted ]
           [ text "Click me to start the task. You will be brought back to home once it finished." ]
         ]

myTask : Effects Action
myTask =
  Task.succeed 0
    |> Task.toMaybe
    |> Task.map TaskCompleted
    |> Effects.task
