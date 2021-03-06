port module Client.Port exposing (error, join, leave, receive, send)

import Json.Decode exposing (Value)


port join : (Value -> msg) -> Sub msg


port leave : (Value -> msg) -> Sub msg


port receive : (String -> msg) -> Sub msg


port error : (String -> msg) -> Sub msg


port send : String -> Cmd msg
