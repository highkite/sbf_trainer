module SideNav exposing (nav)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Messages exposing (Model, Msg(..))

nav : Model -> Html Msg
nav model =
    div [class "d-flex flex-column flex-shrink-0 p-3 bg-light", style "width" "280px", style "height" "100%", style "position" "fixed", style "z-index" "1", style "top" "0", style "left" "0", style "overflow-x" "hidden"] [
        a [class "d-flex align-items-center mb-3 mb-md-0 me-md-auto link-dark text-decoration-none", href "/"][
            span [class "fs-4"] [text "Sidebar"]]
        ,a [onClick ToggleSidePanel, style "text-align" "right"][
            span [class "fs-7"] [text "Close"]]
        ,a [class "btn btn-primary", style "margin-top" "15px", onClick DeleteLearningProgress] [text "Delete Learning Progress"]
        ]
