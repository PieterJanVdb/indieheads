import gleam/bit_array
import gleam/http/request
import gleam/result
import gleam/string
import wisp.{type Request, type Response}

@external(erlang, "indieheads_ffi", "hash_hmac_sha256")
fn do_hash_hmac_sha256(key: String, data: String) -> BitArray

@external(erlang, "indieheads_ffi", "hash_equals")
fn do_hash_equals(a: String, b: String) -> Bool

@external(erlang, "indieheads_ffi", "binary_to_hex")
fn do_binary_to_hex(binary: BitArray) -> BitArray

fn binary_to_hex(binary: BitArray) -> Result(String, Nil) {
  binary
  |> do_binary_to_hex
  |> bit_array.to_string
}

fn hmac_sha256(key: String, data: String) -> Result(String, Nil) {
  do_hash_hmac_sha256(key, data)
  |> binary_to_hex
}

fn hash_equals(a: String, b: String) -> Bool {
  case string.length(a) == string.length(b) {
    True -> do_hash_equals(a, b)
    False -> False
  }
}

pub fn slack_request(
  req: Request,
  signing_secret: String,
  handle_request: fn(Request, String) -> Response,
) -> Response {
  use body <- wisp.require_string_body(req)

  let valid = {
    use signature <- result.try(request.get_header(req, "x-slack-signature"))
    use request_ts <- result.try(request.get_header(
      req,
      "x-slack-request-timestamp",
    ))

    let version = "v0"
    let signature_base = version <> ":" <> request_ts <> ":" <> body
    use hash_digest <- result.try(hmac_sha256(signing_secret, signature_base))
    let computed_signature = "v0=" <> hash_digest

    case hash_equals(signature, computed_signature) {
      True -> Ok(Nil)
      False -> Error(Nil)
    }
  }

  case valid {
    Ok(_) -> handle_request(req, body)
    _ -> wisp.bad_request()
  }
}
