import gleam/erlang/process
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleam/string_tree
import gleam/uri
import indieheads/clients/lastfm
import indieheads/clients/spotify
import indieheads/context.{type Context}
import indieheads/error
import indieheads/web/slack/block
import indieheads/web/slack/composition_object as co
import indieheads/web/slack/element_object as eo
import indieheads/web/slack/message
import indieheads/web/slack/verify
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
        |> request.set_body(msg)

      case httpc.send(req) {
        Ok(_) -> Nil
        Error(err) ->
          wisp.log_error("Error replying to slack: " <> string.inspect(err))
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
  message.build([
    block.section([block.section_text(co.text("Something went wrong", []))]),
  ])
}

fn now_playing(ctx: Context, cmd: Command) {
  handle_command(cmd, fn(cmd) {
    use user <- result.try(get_user(cmd))
    use track <- result.try(lastfm.get_recent_track(ctx.clients.lastfm, user))
    use url <- result.try(spotify.get_track_link(
      ctx.clients.spotify,
      track: track.name,
      artist: track.artist,
    ))

    let spotify_link = case url {
      None -> "No stream found..."
      Some(url) -> "<" <> url <> "|Listen on Spotify>"
    }

    message.build([
      block.section([
        block.section_text(co.text("status", [co.text_kind(co.Markdown)])),
      ]),
      block.section([
        block.section_fields(
          [
            co.text("*Artist*", [co.text_kind(co.Markdown)]),
            co.text("*Name*", [co.text_kind(co.Markdown)]),
            co.text(track.artist, []),
            co.text(track.name, []),
            co.text("*Album*", [co.text_kind(co.Markdown)]),
            co.text("*Stream*", [co.text_kind(co.Markdown)]),
            co.text(track.album, []),
            co.text(spotify_link, [co.text_kind(co.Markdown)]),
          ]
          |> list.map(block.co_field),
        ),
        block.section_accessory(
          eo.image("some_url", [eo.image_alt_text("Thumbnail")]),
        ),
      ]),
    ])
    |> Ok()
  })

  ack_command()
}

fn or_400(result: Result(value, error), next: fn(value) -> Response) -> Response {
  case result {
    Ok(value) -> next(value)
    Error(_) -> wisp.bad_request()
  }
}

fn require_command(req: Request, body: String, next: fn(Command) -> Response) {
  case list.key_find(req.headers, "content-type") {
    Ok("application/x-www-form-urlencoded")
    | Ok("application/x-www-form-urlencoded;" <> _) -> {
      use pairs <- or_400(uri.parse_query(body))
      use text <- or_400(list.key_find(pairs, "text"))
      use response_url <- or_400(list.key_find(pairs, "response_url"))

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
