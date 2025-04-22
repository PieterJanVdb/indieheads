import gleam/bit_array
import gleam/dynamic/decode
import gleam/erlang/process.{type Subject}
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/otp/actor
import gleam/result
import gleam/time/duration
import gleam/time/timestamp.{type Timestamp}
import indieheads/error

const timeout = 10_000

const token_endpoint = "https://accounts.spotify.com/api/token"

pub type Message {
  Get(reply_with: Subject(Result(String, error.Error)))
  Shutdown
}

pub type TokenProvider =
  Subject(Message)

pub type Auth {
  Auth(client_id: String, client_secret: String)
}

pub type State {
  State(auth: Auth, cached: Option(#(String, Timestamp)))
}

fn handle_message(message: Message, state: State) -> actor.Next(Message, State) {
  case message {
    Shutdown -> actor.Stop(process.Normal)
    Get(client) -> {
      let new_state = case get_cached_token(state) {
        Ok(token) -> {
          process.send(client, Ok(token))
          state
        }
        Error(_) -> {
          case get_token(state.auth) {
            Ok(#(token, _) as cached) -> {
              process.send(client, Ok(token))
              State(..state, cached: Some(cached))
            }
            Error(err) -> {
              process.send(client, Error(err))
              state
            }
          }
        }
      }

      actor.continue(new_state)
    }
  }
}

pub fn new(auth: Auth) {
  actor.start(
    State(
      auth: Auth(client_id: auth.client_id, client_secret: auth.client_secret),
      cached: None,
    ),
    handle_message,
  )
}

pub fn get(token_provider: TokenProvider) {
  actor.call(token_provider, Get, timeout)
}

fn get_cached_token(state: State) -> Result(String, Nil) {
  case state.cached {
    Some(#(token, expires_at)) -> {
      let extended_now =
        timestamp.add(timestamp.system_time(), duration.seconds(10))
      case timestamp.compare(expires_at, extended_now) {
        order.Gt -> Ok(token)
        _ -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}

fn get_token(auth: Auth) {
  let auth_header = {
    let encoded =
      { auth.client_id <> ":" <> auth.client_secret }
      |> bit_array.from_string()
      |> bit_array.base64_encode(True)

    "Basic " <> encoded
  }

  let assert Ok(base_req) = request.to(token_endpoint)

  let req =
    request.set_method(base_req, http.Post)
    |> request.set_header("Accept", "application/json")
    |> request.set_header("Authorization", auth_header)
    |> request.set_header("Content-Type", "application/x-www-form-urlencoded")
    |> request.set_body("grant_type=client_credentials")

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(error.FetchError),
  )

  case resp.status {
    200 -> {
      let token_decoder = {
        use access_token <- decode.field("access_token", decode.string)
        use expires_in <- decode.field("expires_in", decode.int)

        let expires_at =
          timestamp.add(timestamp.system_time(), duration.seconds(expires_in))

        decode.success(#(access_token, expires_at))
      }

      json.parse(resp.body, token_decoder)
      |> result.map_error(error.JsonError)
    }
    _ -> Error(error.SpotifyError("Could not retrieve token: " <> resp.body))
  }
}
