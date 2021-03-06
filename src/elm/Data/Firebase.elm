port module Data.Firebase exposing (Category(..), inBoundComments, inBoundPosts, inBoundUser, requestComments, requestPosts, requestUser, requestedContent)

import Data.Comment as Comment exposing (Comment)
import Data.Feed exposing (FeedContent)
import Data.Post as Post exposing (Post)
import Data.User as User exposing (User)
import Json.Decode as Decode
import Json.Decode.Pipeline as Decode
import Json.Encode as Encode


type Category
    = Best
    | New
    | Top
    | Show
    | Comment
    | Ask
    | Job


port firebaseOutbound : Decode.Value -> Cmd msg


requestPosts : Category -> Maybe Int -> Cmd msg
requestPosts category maybeCursor =
    firebaseOutbound <|
        Encode.object
            [ ( "cmd", Encode.string "RequestPosts" )
            , ( "category", Encode.string <| categoryToString category )
            , ( "cursor"
              , case maybeCursor of
                    Just cursor ->
                        Encode.int cursor

                    Nothing ->
                        Encode.null
              )
            ]


requestComments : Int -> Cmd msg
requestComments parentId =
    firebaseOutbound <|
        Encode.object
            [ ( "cmd", Encode.string "RequestComment" )
            , ( "parentId", Encode.string <| String.fromInt parentId )
            ]


requestUser : String -> Cmd msg
requestUser id =
    firebaseOutbound <|
        Encode.object
            [ ( "cmd", Encode.string "RequestUser" )
            , ( "id", Encode.string id )
            ]


{-| Receive all fetched news posts
-}
port requestedContent : (Decode.Value -> msg) -> Sub msg


inBoundPosts :
    { onPosts : FeedContent -> msg
    , onFailure : String -> msg
    }
    -> Sub msg
inBoundPosts config =
    let
        contentDecoder =
            Decode.field "cmd" Decode.string
                |> Decode.andThen
                    (\cmd ->
                        case cmd of
                            "RequestPosts" ->
                                Decode.succeed FeedContent
                                    |> Decode.optional "cursor" (Decode.nullable Decode.int) Nothing
                                    |> Decode.required "posts" (Decode.list Post.postDecoder)
                                    |> Decode.map config.onPosts

                            unmatched ->
                                Decode.fail <| unmatched ++ "is not a supported command"
                    )
    in
    requestedContent <|
        \value ->
            case Decode.decodeValue contentDecoder value of
                Ok msg ->
                    msg

                Err e ->
                    config.onFailure <| Decode.errorToString e


inBoundComments :
    { onComments : ( Post, List Comment ) -> msg
    , onFailure : String -> msg
    }
    -> Sub msg
inBoundComments config =
    let
        contentDecoder =
            Decode.field "cmd" Decode.string
                |> Decode.andThen
                    (\cmd ->
                        case cmd of
                            "RequestComment" ->
                                Decode.succeed Tuple.pair
                                    |> Decode.required "post" Post.postDecoder
                                    |> Decode.required "comments" (Decode.list Comment.commentDecoder)
                                    |> Decode.map config.onComments

                            unmatched ->
                                Decode.fail <| unmatched ++ "is not a supported command"
                    )
    in
    requestedContent <|
        \value ->
            case Decode.decodeValue contentDecoder value of
                Ok msg ->
                    msg

                Err e ->
                    config.onFailure <| Decode.errorToString e


inBoundUser :
    { onUser : User -> msg
    , onFailure : String -> msg
    }
    -> Sub msg
inBoundUser config =
    let
        contentDecoder =
            Decode.field "cmd" Decode.string
                |> Decode.andThen
                    (\cmd ->
                        case cmd of
                            "RequestUser" ->
                                Decode.succeed config.onUser
                                    |> Decode.required "user" User.userDecoder

                            unmatched ->
                                Decode.fail <| unmatched ++ "is not a supported command"
                    )
    in
    requestedContent <|
        \value ->
            case Decode.decodeValue contentDecoder value of
                Ok msg ->
                    msg

                Err e ->
                    config.onFailure <| Decode.errorToString e



-- HELPERS


categoryToString : Category -> String
categoryToString category =
    case category of
        Best ->
            "best"

        New ->
            "new"

        Top ->
            "top"

        Comment ->
            "comment"

        Show ->
            "show"

        Ask ->
            "ask"

        Job ->
            "job"
