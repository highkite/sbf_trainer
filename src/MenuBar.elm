module MenuBar exposing (menuBar)

import Svg exposing (svg, use)
import Svg.Attributes exposing (fillRule, d, viewBox, style, xlinkHref, x, y)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Messages exposing (Msg(..))

menuBar :  Html Msg
menuBar =
        header []
        [ div [ class "px-3 py-2 bg-dark text-white"]
        [ div [class "container"][ div
        [ class "d-flex flex-wrap align-items-center justify-content-left justify-content-lg-start"]
        [ a [onClick ToggleSidePanel, class "d-flex align-items-center my-2 my-lg-0 me-lg-auto text-white text-decoration-none"]
        [svg [width 40, height 32, Svg.Attributes.class "bi me-2"] [use [x "00", y "00", xlinkHref "#justify" ][]]]
        ] ] ] ]
