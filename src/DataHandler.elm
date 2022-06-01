module DataHandler exposing (fetchQuestions)

import Http
import Json.Decode as JD exposing (Decoder, Error(..), decodeString, list, string, int)
import Json.Decode.Pipeline exposing (optional, optionalAt, required, requiredAt)

import Messages exposing (Msg(..), Question, LearnData)

questionDecoder : Decoder Question
questionDecoder =
        JD.succeed Question
                |> required "ide" int
                |> required "question" string
                |> required "answers" (list string)
                |> optional "images" (list string) []

learnDataDecoder : Decoder LearnData
learnDataDecoder =
        JD.list questionDecoder

url : String
url =
    "http://localhost:8080/data_collector/data.json"

fetchQuestions : Cmd Msg
fetchQuestions =
    Http.get
        { url = url
        , expect = Http.expectJson DataReceived learnDataDecoder
        }

--loadLearnProgress : LearnProgress
--loadLearnProgress = []
