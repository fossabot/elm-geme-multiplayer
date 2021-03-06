module WebGL.Ui exposing (repeat, slice9)

import Math.Vector2 exposing (Vec2, vec2)
import Math.Vector4 exposing (Vec4, vec4)
import WebGL.Shape2d exposing (Form(..), Render, Shape2d(..))
import WebGL.Texture exposing (Texture)
import WebGL.Ui.Slice exposing (spriteRender)
import WebGL.Ui.Util as Util


slice9 =
    WebGL.Ui.Slice.slice9


repeat : String -> { xmin : Float, xmax : Float, ymin : Float, ymax : Float } -> Float -> Float -> Shape2d
repeat atlas { xmin, xmax, ymin, ymax } w_ h_ =
    let
        w =
            abs (xmax - xmin) + 1

        h =
            abs (ymax - ymin) + 1
    in
    Util.withTexture atlas <|
        \t ->
            let
                ( tW_, tH_ ) =
                    WebGL.Texture.size t

                tW =
                    toFloat tW_

                tH =
                    toFloat tH_

                uv =
                    vec4 (xmin / tW) (1 - ymin / tH - (h / tH)) (w / tW) (h / tH)

                uv2 =
                    vec2 (w_ / w) (h_ / h)
            in
            Util.shape w_ h_ <|
                spriteRender uv2 t (vec2 tW tH) uv
