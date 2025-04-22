import envoy
import gleam/erlang/process
import indieheads/context.{type Context}
import indieheads/router
import mist
import wisp
import wisp/wisp_mist

pub fn main() -> Nil {
  wisp.configure_logger()

  let assert Ok(secret_key_base) = envoy.get("SECRET_KEY_BASE")
  let assert Ok(ctx) = context.init()
  let assert Ok(_) = start_http_server(ctx, secret_key_base)

  process.sleep_forever()
}

fn start_http_server(ctx: Context, secret_key_base: String) {
  router.handle_request(_, ctx)
  |> wisp_mist.handler(secret_key_base)
  |> mist.new
  |> mist.bind("0.0.0.0")
  |> mist.port(3000)
  |> mist.start_http
}
