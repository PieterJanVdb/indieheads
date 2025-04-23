import gleam/bit_array
import gleam/erlang/process
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/string_tree
import gleam/uri
import indieheads/clients/lastfm
import indieheads/clients/spotify
import indieheads/context.{type Context}
import indieheads/error
import indieheads/helpers
import indieheads/web/slack/block
import indieheads/web/slack/composition_object as co
import indieheads/web/slack/element_object as eo
import indieheads/web/slack/message
import indieheads/web/slack/verify
import prng/random
import wisp.{type Request, type Response}

pub type Command {
  Command(text: String, response_url: String)
}

fn handle_command(
  cmd: Command,
  handler: fn(Command) -> Result(String, error.Error),
) {
  process.start(
    fn() {
      let msg = case handler(cmd) {
        Ok(msg) -> msg
        Error(err) -> {
          wisp.log_error("Error handling command: " <> string.inspect(err))
          error_message()
        }
      }

      let assert Ok(base_req) = request.to(cmd.response_url)
      let req =
        request.set_method(base_req, http.Post)
        |> request.set_header("content-type", "application/json")
        |> request.set_body(msg)

      case httpc.send(req) {
        Ok(res) if res.status < 400 -> {
          echo res.body
          wisp.log_info("Successfully handled command (" <> cmd.text <> ")")
        }
        Ok(res) -> {
          wisp.log_error("Fetch error replying to slack: " <> res.body)
        }
        Error(err) ->
          wisp.log_error(
            "Network error replying to slack: " <> string.inspect(err),
          )
      }
    },
    linked: False,
  )
}

fn ack_command() {
  let text = string_tree.from_string("Running...")
  wisp.ok() |> wisp.set_body(wisp.Text(text))
}

fn get_user(cmd: Command) {
  string.split(cmd.text, on: " ")
  |> list.first()
  |> result.replace_error(error.CommandError("No user provided"))
}

fn error_message() {
  message.build(
    [block.section([block.section_text(co.text("Something went wrong", []))])],
    where: message.Ephemeral,
  )
}

fn now_playing_message(
  ctx ctx: Context,
  user user: String,
  track track: lastfm.Track,
  url url: Option(String),
) {
  let status = {
    let current = case track.now_playing {
      True -> "is currently listening to:"
      False -> "has last listened to:"
    }

    ":headphones: <https://www.lastfm.com/user/"
    <> user
    <> "|*"
    <> user
    <> "*> "
    <> current
  }

  let spotify_link = case url {
    None -> "No stream found..."
    Some(url) -> {
      let encoded_link =
        bit_array.from_string(url) |> bit_array.base64_encode(True)
      let redirect_url = ctx.domain <> "/redirect/spotify?link=" <> encoded_link

      "<" <> redirect_url <> "|Listen on Spotify>"
    }
  }

  let track_text = {
    let artist_line = "*Artist* - " <> track.artist
    let name_line = "*Track* - " <> track.name
    let album_line = "*Album* - " <> track.album
    string.join([artist_line, name_line, album_line, spotify_link], with: "\n")
    <> "\n"
  }

  message.build(
    [
      block.context([co.text(status, [co.text_kind(co.Markdown)])]),
      block.divider(),
      block.context([co.text(track_text, [co.text_kind(co.Markdown)])]),
    ],
    where: message.InChannel,
  )
}

fn perhaps_insult(user: String, next: fn() -> Result(String, error.Error)) {
  let random_value = random.int(0, 100) |> random.random_sample()

  case random_value {
    50 ->
      Ok(message.build(
        [
          block.section([
            block.section_text(
              co.text("*" <> user <> "* is listening to poopoo kaka", []),
            ),
          ]),
        ],
        where: message.InChannel,
      ))
    _ -> next()
  }
}

fn now_playing(ctx: Context, cmd: Command) {
  handle_command(cmd, fn(cmd) {
    use user <- result.try(get_user(cmd))
    use <- perhaps_insult(user)
    use track <- result.try(lastfm.get_recent_track(ctx.clients.lastfm, user))
    use url <- result.try(spotify.get_track_link(
      ctx.clients.spotify,
      track: track.name,
      artist: track.artist,
    ))

    Ok(now_playing_message(ctx:, user:, track:, url:))
  })

  ack_command()
}

fn require_command(req: Request, body: String, next: fn(Command) -> Response) {
  case list.key_find(req.headers, "content-type") {
    Ok("application/x-www-form-urlencoded")
    | Ok("application/x-www-form-urlencoded;" <> _) -> {
      use pairs <- helpers.or_400(uri.parse_query(body))
      use text <- helpers.or_400(list.key_find(pairs, "text"))
      use response_url <- helpers.or_400(list.key_find(pairs, "response_url"))

      next(Command(text:, response_url:))
    }
    _ -> wisp.unsupported_media_type(["application/x-www-form-urlencoded"])
  }
}

pub fn commands(ctx: Context, req: Request, target: String) {
  use <- wisp.require_method(req, http.Post)
  use req, body <- verify.slack_request(req, ctx.slack_signing_secret)
  use cmd <- require_command(req, body)
  case target {
    "np" -> now_playing(ctx, cmd)
    _ -> wisp.not_found()
  }
}
