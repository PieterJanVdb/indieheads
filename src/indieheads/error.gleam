import gleam/httpc
import gleam/json

pub type Error {
  FetchError(httpc.HttpError)
  JsonError(json.DecodeError)
  LastFMError(String)
  SpotifyError(String)
  WeatherError(String)
  CommandError(String)
}
