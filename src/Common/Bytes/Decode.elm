module Common.Bytes.Decode exposing
    ( andMap
    , bool
    , components
    , float
    , foldl
    , id
    , int
    , maybe
    , reverseList
    , sequence
    , sizedString
    , vec2
    , xy
    , xyz
    , xyzw
    )

import AltMath.Vector2 as AltVec2
import Bytes exposing (Bytes, Endianness(..))
import Bytes.Decode as D exposing (Decoder, Step(..))
import Logic.Component as Component


sequence : List (Decoder (a -> a)) -> Decoder (a -> a)
sequence =
    List.foldl (D.map2 (<<)) (D.succeed identity)


sequence2 : List (Decoder (b -> a -> a)) -> Decoder (b -> a -> a)
sequence2 =
    List.foldl (D.map2 composeBAA) (D.succeed (\_ a -> a))


composeBAA : (b -> a -> a) -> (b -> a -> a) -> b -> a -> a
composeBAA f g b a =
    f b (g b a)


andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap argument function =
    D.map2 (<|) function argument


float : Decoder Float
float =
    D.float32 BE


bool : Decoder Bool
bool =
    D.unsignedInt8
        |> D.map
            (\a ->
                if a == 1 then
                    True

                else
                    False
            )


vec2 : Decoder AltVec2.Vec2
vec2 =
    D.map2 (\x y -> AltVec2.fromRecord { x = x, y = y })
        float
        float


xy : Decoder { x : Float, y : Float }
xy =
    D.map2 (\x y -> { x = x, y = y })
        float
        float


xyz : Decoder { x : Float, y : Float, z : Float }
xyz =
    D.map3 (\x y z -> { x = x, y = y, z = z })
        float
        float
        float


xyzw : Decoder { x : Float, y : Float, z : Float, w : Float }
xyzw =
    D.map4 (\x y z w -> { x = x, y = y, z = z, w = w })
        float
        float
        float
        float


id : Decoder Int
id =
    D.unsignedInt32 BE


int : Decoder Int
int =
    D.signedInt32 BE


sizedString : Decoder String
sizedString =
    D.unsignedInt32 BE
        |> D.andThen D.string


reverseList : Decoder a -> Decoder (List a)
reverseList decoder =
    D.unsignedInt32 BE
        |> D.andThen (\len -> D.loop ( len, [] ) (listStep decoder))


listStep : Decoder a -> ( Int, List a ) -> Decoder (Step ( Int, List a ) (List a))
listStep decoder ( n, xs ) =
    if n <= 0 then
        D.succeed (Done xs)

    else
        D.map (\x -> Loop ( n - 1, x :: xs )) decoder


foldl : Int -> (b -> Decoder b) -> b -> Decoder b
foldl count decoder acc =
    D.loop ( count, acc ) (foldlStep decoder)


foldlStep : (a -> Decoder b) -> ( Int, a ) -> Decoder (Step ( Int, b ) a)
foldlStep decoder ( n, acc ) =
    if n <= 0 then
        D.succeed (Done acc)

    else
        D.map (\x -> Loop ( n - 1, x )) (decoder acc)


maybe : Decoder b -> Decoder (Maybe b)
maybe d =
    D.unsignedInt8
        |> D.andThen
            (\i ->
                if i == 1 then
                    D.map Just d

                else
                    D.succeed Nothing
            )


components : Decoder a -> Decoder (Component.Set a)
components d =
    reverseList (D.map2 (\id_ shapes -> ( id_, shapes )) id d)
        |> D.map Component.fromList
