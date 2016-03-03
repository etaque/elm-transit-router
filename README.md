# Elm Transit Router

    elm package install etaque/elm-transit-router

Drop-in router with animated route transitions for single page apps in [Elm](http://elm-lang.org/), extracted from (and used in) [Tacks](https://github.com/etaque/tacks/tree/master/client/src).


## Features

* Takes care of the *history* interaction and actions plumbing
* Enables animated transition on route changes, thanks to [elm-transit](http://package.elm-lang.org/packages/etaque/elm-transit/latest)
* Provides a simple `Signal.Address String` for navigation 

There is a projet example with a minimal usage of the router [right here](./example).


## Usage

To be able to provide animated route transitions, **TransitRouter** (and **Transit** underneath) works by action delegation: it will be able to emit `(Action, Effects Action)` by knowing how to wrap his own `TransitRouter.Action` type into your app's `Action` type. This is why the `actionWrapper` is needed in config below.


### Model

Say you have an `Action` type wrapping `TransitRouter.Action`:

```elm
type Action = Foo | ... | RouterAction (TransitRouter.Action Route) | NoOp
```

Also a `Route` type to describe all routes in your apps:

```elm
type Route = Home | ... | NotFound | EmptyRoute
```

You must then extend your model with `WithRoute` on `Route` type:

```elm
type alias Model = TransitRouter.WithRoute Route 
  { foo: String }
```

Your `Model` is now enabled to work with `TransitRouter`. Initialize it with the `EmptyRoute` that should render nothing in your view, to avoid content flashing on app init.

```elm
initialModel : Model
initialModel =
  { transitRouter = TransitRouter.empty EmptyRoute
  , foo = ""
  }
```


### Update

A config should be prepared:

```elm
routerConfig : TransitRouter.Config Route Action Model

-- which expands to:
routerConfig :
  { mountRoute : Route -> Route -> Model -> (Model, Effects Action)
  , getDurations : Route -> Route -> Model -> (Float, Float)
  , actionWrapper : TransitRouter.Action Route -> Action
  , routeDecoder : String -> Route
  }
```

* In `mountRoute`, you'll provide what should be done in your `update` when a new route is mounted. The `Route` params are previous and new routes.

* In `getDurations`, you'll return the transition durations, given previous/new route and current model. Write `\_ _ _ -> (50, 200)` if you always want an exit of 50ms then an enter of 200ms. You `mountRoute` will happend at the end of exit.

* `actionWrapper` will be used to transform internal `TransitAction.Action` to your own `Action`.

* `routeDecoder` takes the current path as input and should return the associated route.
See my [elm-route-parser](http://package.elm-lang.org/packages/etaque/elm-route-parser/latest) package for help on this.


It's now time to wire `init` and `update` functions:

```elm
init : String -> (Model, Effects Action)
init path =
  TransitRouter.init routerConfig path initialModel
```

This will parse and mount initial route on app init. You can get initial path value by setting up a `port` in main and provide current path from JS side.

In `update`, the lib will take care of routes updates and transition control.

```elm
update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of

    NoOp ->
      (model, Effects.none)

    RouterAction routeAction ->
      TransitRouter.update routerConfig routeAction model

    Foo ->
      (doFoo model, Effects.none)
```


### View

This is where visible part of routing happens. You just have to match current route to render the current route's view, using `getRoute`:


```elm
contentView : Address Action -> Model -> Html
contentView address model =
  case (TransitRouter.getRoute model) of

    Home ->
      homeView address model
    
    --- and so on

```

Now for animations, there is `getTransition`, to be used with [elm-transit-style](http://package.elm-lang.org/packages/etaque/elm-transit-style/latest) (or directly with `Transit.getStatus` and `Transit.getValue` from [elm-transit](http://package.elm-lang.org/packages/etaque/elm-transit/latest)).

```elm
view : Address Action -> Model -> Html
view address model =
  div
    [ style (TransitStyle.fadeSlideLeft 100 (getTransition model)) ]
    [ contentView address model ]
```

Links: use `pushPathAddress` for clink handling, for instance within that kind of helper:

```elm
clickTo : String -> List Attribute
clickTo path =
  [ href path
  , onWithOptions
      "click"
      { stopPropagation = True, preventDefault = True }
      Json.value
      (\_ -> message TransitRouter.pushPathAddress path)
  ]
```

### Routing with Effects

Suppose you are in the module of one of the screens and you want to switch routes after handling an action (for instance after handling the result from a task). You can do this by using the redirect effect:

```elm
redirect : Routes.Route -> Effects ()
redirect route =
  Routes.toPath route
    |> Signal.send TransitRouter.pushPathAddress
    |> Effects.task
```

In the update function of the screen module you will not have access to the `RouteAction` action, since it is defined in the main app module. To be able to make the effect work in your update function, map it to a null operation:

```elm
update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of

    NoOp ->
      (model, Effects.none)

    TaskCompleted ->
      (model, Effects.map (\_ -> NoOp) (redirect Home))
```


## Subrouting transitions

If you app contains submenus, you might want to adapt the scope of transition animation, ie you only want to animate the submenu content when you switch from a submenu item to another, not the whole content of your page.

A good way to do that is to create a type to indicate the current route switch happening, and to store it in your model, so you will be able to adapt the animation in your views. Let's say you have an admin submenu:

```elm
type RouteSwitch = Global | InAdmin | NoSwitch

type alias Model = TransitRouter.WithRoute Route 
  { foo: String
  , routeSwitch : RouteSwitch
  }
```

Types are in place, but we still need to set `routeSwitch` value, and `Config.mountRoute` is the right place for that as it provides previous and new route, so you can compare them and decide what is the current switch:

```elm
mountRoute : Route -> Route -> Model -> (Model, Effects Action)
mountRoute prevRoute newRoute model =
  let
    routeSwitch = case (prevRoute, newRoute) of
      (Admin _, Admin _) ->
        InAdmin
      _ ->
        Global
    newModel = { model | routeSwitch = routeSwitch }
  in
    case newRoute of
      ...
```

Then you have everything in your hands in order to show animation in the right view, be it global content or admin content only.
