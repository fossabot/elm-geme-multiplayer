module Client exposing (init, subscriptions, update, wrap)

import Browser.Dom as Dom
import Browser.Events as Browser
import Client.Event.Keyboard
import Client.Menu.HUD
import Client.Port as Port
import Client.Sync
import Client.System.Event
import Client.System.Join as Join
import Client.System.Tick as Tick
import Client.Util as Util
import Client.World as World exposing (Message(..), Model, World)
import Dict
import Html exposing (Html)
import Json.Decode as Json
import Set
import Task
import WebGL exposing (Entity)


wrap : List (Html.Attribute msg) -> List Entity -> Html msg
wrap attrs entities =
    WebGL.toHtmlWith webGLOption
        attrs
        entities


webGLOption : List WebGL.Option
webGLOption =
    [ WebGL.alpha True
    , WebGL.depth 1
    , WebGL.clearColor 1 1 1 1
    ]


init : Json.Value -> ( Model, Cmd Message )
init flags =
    let
        _ =
            Client.Menu.HUD.view

        initTextures =
            Util.getTexture Texture TextureFail "magic" "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="

        cmdScreen =
            Dom.getViewport
                |> Task.map (\{ viewport } -> Util.toScreen viewport.width viewport.height)
                |> Task.perform Resize
    in
    ( World.empty, Cmd.batch [ cmdScreen, initTextures ] )


update : Message -> Model -> ( Model, Cmd Message )
update msg ({ textures } as model) =
    case msg of
        Tick time ->
            Tick.system time model

        Subscription world ->
            Client.System.Event.system model world

        Event fn ->
            fn model.world
                |> Client.System.Event.system model

        Resize screen ->
            ( { model | screen = screen }, Cmd.none )

        Texture url t ->
            ( { model
                | textures =
                    { textures
                        | loading = Set.remove url textures.loading
                        , done = Dict.insert url t textures.done
                    }
              }
            , Cmd.none
            )

        TextureFail _ ->
            ( model, Cmd.none )

        ---- NETWORK
        Receive income ->
            ( { model | world = Client.Sync.receive income model.world }, Cmd.none )

        Join ->
            ( { model | world = Join.system model.world }, Cmd.none )

        Leave ->
            ( model, Cmd.none )

        Error err ->
            ( model, Cmd.none )


subscriptions model =
    Sub.batch
        [ Port.receive Receive
        , Port.join (\_ -> Join)
        , Port.leave (\_ -> Leave)
        , Port.error Error
        , Client.Event.Keyboard.subscription model.world |> Sub.map Subscription
        , Browser.onAnimationFrame Tick
        , Browser.onResize (\width height -> Util.toScreen (toFloat width) (toFloat height) |> Resize)
        ]
