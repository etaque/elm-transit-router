module Main where

import Effects exposing (Never)
import Task
import Signal
import StartApp

import Update exposing (init, update, actions)
import View exposing (view)


port initialPath : String


app =
  StartApp.start
    { init = init initialPath
    , update = update
    , view = view
    , inputs = [ actions ]
    }


main =
  app.html


port tasks : Signal (Task.Task Never ())
port tasks =
  app.tasks
