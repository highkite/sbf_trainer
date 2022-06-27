module DataHandler exposing (learnProgressDecoder, configDecoder, url, urlBinnen, urlSegeln, learnDataDecoder)

import Http
import Json.Decode as JD exposing (Decoder, Error(..), decodeString, list, string, int, bool)
import Json.Decode.Pipeline exposing (optional, optionalAt, required, requiredAt)

import Messages exposing (Msg(..), Question, LearnData, QuestionLearnProgress, LearnProgress, Id, Config, Model)

idDecoder : Decoder Id
idDecoder =
    JD.succeed Id
        |> required "ide" int
        |> required "questionType" int

questionDecoder : Decoder Question
questionDecoder =
        JD.succeed Question
                |> required "ide" idDecoder
                |> required "question" string
                |> required "answers" (list string)
                |> optional "images" (list string) []

learnDataDecoder : Decoder LearnData
learnDataDecoder =
        JD.list questionDecoder

questionProgressDecoder : Decoder QuestionLearnProgress
questionProgressDecoder =
    JD.succeed QuestionLearnProgress
        |> required "ide" idDecoder
        |> required "level" int
        |> required "timestamp" string

learnProgressDecoder : Decoder LearnProgress
learnProgressDecoder =
    JD.list questionProgressDecoder

configDecoder : Decoder Config
configDecoder =
    JD.succeed Config
        |> required "spez_fragen_binnen" bool
        |> required "spez_fragen_segeln" bool

url : String
url =
    "http://localhost:8080/data_collector/test_data.json"
    --"http://localhost:8080/data_collector/data.json"
    --"https://highkite.github.io/sbf_trainer/data_collector/data.json"

urlBinnen : String
urlBinnen =
    "http://localhost:8080/data_collector/binnen_data.json"

urlSegeln : String
urlSegeln =
    "http://localhost:8080/data_collector/segeln_data.json"

--loadLearnProgress : LearnProgress
--loadLearnProgress = []
