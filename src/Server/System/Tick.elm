module Server.System.Tick exposing (system)

import Common.Component.Position as Position
import Common.Sync
import Dict
import Logic.System as System
import Server.Sync
import Server.World as World
import Time


system time was =
    let
        newTime =
            Time.posixToMillis time

        now =
            { was | time = newTime, frame = was.frame + 1 }
                |> System.step (\p -> { p | y = p.y + 0.1 }) Position.spec

        toAll =
            Server.Sync.pack was now
                |> Common.Sync.compose
                |> Server.Sync.send
    in
    ( now
    , World.tick was.time newTime
        :: Dict.foldl (\k _ -> (::) (toAll k)) [] now.user
        |> Cmd.batch
    )
