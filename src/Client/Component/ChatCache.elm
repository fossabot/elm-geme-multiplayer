module Client.Component.ChatCache exposing (ChatCache, cache, empty, spec)

import Client.Asset.Text
import Common.Component.Chat exposing (Chat)
import Common.Util as Util
import Playground exposing (Shape, moveY)


type alias ChatCache =
    { input : String
    , messages : List Shape
    }


spec : Util.Spec ChatCache { world | chat_ : ChatCache }
spec =
    Util.Spec .chat_ (\comps world -> { world | chat_ = comps })


empty : Chat -> ChatCache
empty chat =
    { input = ""
    , messages = []
    }
        |> cache chat


lineHeight =
    10


cache : Chat -> ChatCache -> ChatCache
cache messages_ chat_ =
    { chat_
        | messages =
            List.take 10 messages_
                |> List.foldl
                    (\( _, a ) ( acc, offset ) ->
                        ( (Client.Asset.Text.chat a |> moveY offset)
                            :: acc
                        , offset + lineHeight
                        )
                    )
                    ( [], lineHeight )
                |> Tuple.first
    }
