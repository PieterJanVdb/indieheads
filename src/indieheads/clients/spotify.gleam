import gleam/dynamic/decode
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/result
import indieheads/clients/spotify/token_provider.{type TokenProvider, Auth}
import indieheads/error

const host = "api.spotify.com"

pub opaque type Spotify {
  Spotify(token_provider: TokenProvider)
}

pub fn new(client_id client_id: String, client_secret client_secret: String) {
  let assert Ok(token_provider) =
    token_provider.new(Auth(client_id:, client_secret:))
  Spotify(token_provider:)
}

pub fn get_track_link(
  client: Spotify,
  track track: String,
  artist artist: String,
) {
  use access_token <- result.try(token_provider.get(client.token_provider))

  let query = "track:" <> track <> " artist:" <> artist

  let req =
    request.new()
    |> request.set_host(host)
    |> request.set_path("/v1/search")
    |> request.set_header("accept", "application/json")
    |> request.set_header("authorization", "Bearer " <> access_token)
    |> request.set_query([#("q", query), #("type", "track"), #("limit", "1")])

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(error.FetchError),
  )

  case resp.status {
    200 -> {
      let url_decoder = decode.at(["external_urls", "spotify"], decode.string)
      let first_track_decoder = decode.at([0], decode.optional(url_decoder))
      let tracks_decoder = decode.at(["tracks", "items"], first_track_decoder)

      json.parse(resp.body, tracks_decoder)
      |> result.map_error(error.JsonError)
    }
    _ -> {
      let err_msg =
        "Could not get track link for (" <> query <> "): " <> resp.body
      Error(error.SpotifyError(err_msg))
    }
  }
}
