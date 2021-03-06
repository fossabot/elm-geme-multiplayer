module Client.Sync exposing (pack, receive, send)

import Base64
import Bytes.Decode as D exposing (Decoder)
import Bytes.Encode as E exposing (Encoder)
import Client.Component.Body as Body
import Client.Component.ChatCache as ChatCache
import Client.Port as Port
import Client.World as Client
import Common.Bytes.Decode as D
import Common.Bytes.Encode as E
import Common.Component.Body as CommonBody
import Common.Component.Desire as Desire
import Common.Component.Name as Name
import Common.Component.Position as Position
import Common.Component.Velocity as Velocity
import Common.Patch as Patch
import Common.Sync


pack : Client.World -> Client.World -> List Encoder
pack was now =
    [ packChat was now
    , packIfNeed .desire Desire.encode was now
    ]
        |> List.reverse


unpack =
    let
        ll =
            [ Patch.decode Name.decode |> D.map (Patch.apply Name.spec)
            , Patch.decode Position.decode |> D.map (Patch.apply Position.spec)
            , Patch.decode CommonBody.decode |> D.map (Patch.applyWith Body.unpack Body.spec)
            , Patch.decode Velocity.decode |> D.map (Patch.apply Velocity.spec)
            , D.id
                |> D.map
                    (\me w ->
                        if me /= w.me then
                            let
                                _ =
                                    Debug.log "change" "me"
                            in
                            { w | me = me }

                        else
                            w
                    )
            , D.reverseList (D.map2 Tuple.pair D.id D.sizedString)
                |> D.map List.reverse
                |> D.map (\chat w -> { w | chat = chat, chat_ = ChatCache.cache chat w.chat_ })
            ]
    in
    ll |> Common.Sync.decompose (List.length ll - 1)


packChat was now =
    if was.chat /= now.chat then
        case now.chat of
            ( a, b ) :: _ ->
                E.sequence [ E.id a, E.sizedString b ]

            [] ->
                E.sequence []

    else
        E.sequence []


packIfNeed : (world -> comp) -> (comp -> Encoder) -> world -> world -> Encoder
packIfNeed fn eee was now =
    if fn was /= fn now then
        fn now |> eee

    else
        E.sequence []


receive data world =
    case data |> Base64.toBytes |> Maybe.andThen (D.decode unpack) of
        Just fn ->
            fn world

        Nothing ->
            world


send info =
    let
        data =
            info
                |> E.encode
                |> Base64.fromBytes
                |> Maybe.withDefault ""
    in
    if data == "/w==" then
        Cmd.none

    else
        Port.send data


decompose : List (Decoder (a -> a)) -> Decoder (a -> a)
decompose =
    List.map fromMaybe >> D.sequence


fromMaybe : Decoder (a -> a) -> Decoder (a -> a)
fromMaybe fn =
    D.maybe fn
        |> D.map (\m -> m |> Maybe.withDefault identity)
