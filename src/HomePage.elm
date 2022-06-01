port module HomePage exposing (main, save, doload)

import Browser

import Http exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import List exposing (head)

import MenuBar exposing (menuBar)
import StartUp exposing (startUp)

import DataHandler exposing (fetchQuestions)

import QuestionHandler exposing (questionView)

import Messages exposing (Msg(..), LearnData, Model)


port save : String -> Cmd msg
port doload : () -> Cmd msg

initialModel : () -> (Model, Cmd Msg)
initialModel _ =
        ({ page_state = 0, learnData = [], learnProgress = [], errorMessage = Nothing}, Cmd.none)

view : Model -> Html Msg
view model =
        case model.page_state of
                0 ->
                        div []
                        [
                                menuBar
                                ,startUp model
                                ,case model.errorMessage of
                                        Just message ->
                                                text ("Error: " ++ message)
                                        Nothing ->
                                                text ""
                        ]
                1 ->
                        div []
                        [
                                menuBar
                                ,questionView (head model.learnData)
                        ]
                _ ->
                        div []
                        [
                                menuBar
                                ,text ("Gello")
                        ]


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
        case msg of
                StartUpView ->
                        ({ model | page_state = 0 }, Cmd.none)

                GelloView ->
                        ({ model | page_state = 1 }, Cmd.none)

                SendHttpRequest ->
                        (model, fetchQuestions)

                DataReceived (Ok learningData) ->
                        ({ model | learnData = learningData, page_state = 1 }, Cmd.none )

                DataReceived (Err httpError) ->
                        ( { model | errorMessage = Just (buildErrorMessage httpError) }
                            , Cmd.none
                            )

                SaveLocalStorage ->
                      (model , save "abc")

                LoadLocalStorage ->
                      (model , doload ())

buildErrorMessage : Http.Error -> String
buildErrorMessage httpError =
    case httpError of
        Http.BadUrl message ->
            message

        Http.Timeout ->
            "Server is taking too long to respond. Please try again later."

        Http.NetworkError ->
            "Unable to reach server."

        Http.BadStatus statusCode ->
            "Request failed with status code: " ++ String.fromInt statusCode

        Http.BadBody message ->
            message

main : Program () Model Msg
main =
        Browser.element
        { init = initialModel
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }
