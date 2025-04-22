import envoy
import gleam/result
import indieheads/clients/lastfm
import indieheads/clients/spotify

pub type Clients {
  Clients(lastfm: lastfm.LastFM, spotify: spotify.Spotify)
}

pub type Context {
  Context(clients: Clients, slack_signing_secret: String)
}

pub fn init() {
  use lastfm_api_key <- result.try(envoy.get("LAST_FM_API_KEY"))
  use slack_signing_secret <- result.try(envoy.get("SLACK_SIGNING_SECRET"))
  use spotify_client_secret <- result.try(envoy.get("SPOTIFY_CLIENT_SECRET"))
  use spotify_client_id <- result.map(envoy.get("SPOTIFY_CLIENT_ID"))

  let lastfm_client = lastfm.new(lastfm_api_key)
  let spotify_client =
    spotify.new(
      client_id: spotify_client_id,
      client_secret: spotify_client_secret,
    )

  let clients = Clients(lastfm: lastfm_client, spotify: spotify_client)

  Context(clients:, slack_signing_secret:)
}
