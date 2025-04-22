import gleam/dynamic/decode.{type Decoder}
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pair
import gleam/result
import indieheads/error

const endpoint = "https://ws.audioscrobbler.com/2.0"

pub type Track {
  Track(
    artist: String,
    album: String,
    name: String,
    thumbnail: Option(String),
    now_playing: Bool,
  )
}

pub opaque type LastFM {
  LastFM(api_key: String)
}

pub fn new(api_key: String) -> LastFM {
  LastFM(api_key:)
}

fn recent_tracks_decoder() -> Decoder(Track) {
  let thumbnails_decoder = {
    use size <- decode.field("size", decode.string)
    use url <- decode.field("#text", decode.string)
    decode.success(#(size, url))
  }

  let track_decoder = {
    use artist <- decode.subfield(["artist", "#text"], decode.string)
    use album <- decode.subfield(["album", "#text"], decode.string)
    use name <- decode.field("name", decode.string)
    use thumbnails <- decode.field("image", decode.list(thumbnails_decoder))
    use now_playing_str <- decode.then(decode.optionally_at(
      ["@attr", "nowplaying"],
      None,
      decode.optional(decode.string),
    ))

    let now_playing = case now_playing_str {
      Some("true") -> True
      _ -> False
    }

    let thumbnail =
      list.find(thumbnails, fn(t) {
        case t.0 {
          "large" -> True
          _ -> False
        }
      })
      |> option.from_result()
      |> option.map(pair.second)

    decode.success(Track(artist:, album:, name:, thumbnail:, now_playing:))
  }

  let first_track_decoder = decode.at([0], track_decoder)

  decode.at(["recenttracks", "track"], first_track_decoder)
}

pub fn parse_recent_tracks(data: String) {
  json.parse(data, recent_tracks_decoder())
  |> result.map_error(error.JsonError)
}

pub fn parse_error(data: String) {
  case json.parse(data, decode.at(["message"], decode.string)) {
    Ok(err) -> Error(error.LastFMError(err))
    Error(err) -> Error(error.JsonError(err))
  }
}

pub fn get_recent_track(client: LastFM, user: String) {
  let assert Ok(base_req) = request.to(endpoint)

  let req =
    request.set_header(base_req, "accept", "application/json")
    |> request.set_query([
      #("method", "user.getrecenttracks"),
      #("user", user),
      #("api_key", client.api_key),
      #("format", "json"),
      #("limit", "1"),
    ])

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(error.FetchError),
  )

  case resp.status {
    200 -> parse_recent_tracks(resp.body)
    _ -> parse_error(resp.body)
  }
}
