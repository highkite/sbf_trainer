module HomePage exposing (main)

import Browser

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import MenuBar exposing (menuBar)
import StartUp exposing (startUp)

import Messages exposing (Msg(..))

type alias Model =
        { page_state : Int }

initialModel : Model
initialModel =
        { page_state = 0 }

view : Model -> Html Msg
view model =
        case model.page_state of
                0 ->
                        div []
                        [
                                menuBar
                                ,startUp
                        ]
                _ ->
                        div []
                        [
                                menuBar
                                ,text ("Gello")
                        ]


update : Msg -> Model -> Model
update msg model =
        case msg of
                StartUpView ->
                        { model | page_state = 0 }

                GelloView ->
                        { model | page_state = 1 }

main : Program () Model Msg
main =
        Browser.sandbox
        { init = initialModel
        , view = view
        , update = update
        }
