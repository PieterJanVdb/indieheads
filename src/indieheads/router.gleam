import indieheads/context.{type Context}
import indieheads/web
import indieheads/web/redirect
import indieheads/web/slack
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    ["commands", target] -> slack.commands(ctx, req, target)
    ["redirect", "spotify"] -> redirect.spotify_link(req)
    _ -> wisp.not_found()
  }
}
