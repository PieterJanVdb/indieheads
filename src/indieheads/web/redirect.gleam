import gleam/bit_array
import gleam/http
import gleam/http/request
import gleam/list
import gleam/option.{Some}
import gleam/result
import gleam/uri
import indieheads/helpers
import wisp.{type Request}

pub fn spotify_link(req: Request) {
  use <- wisp.require_method(req, http.Get)

  use query <- helpers.or_400(request.get_query(req))
  use encoded_link <- helpers.or_400(list.key_find(query, "link"))
  use decoded_link <- helpers.or_400({
    use decoded_bit_array <- result.try(bit_array.base64_decode(encoded_link))
    bit_array.to_string(decoded_bit_array)
  })
  use decoded_uri <- helpers.or_400(uri.parse(decoded_link))

  case decoded_uri.host {
    Some("open.spotify.com") -> wisp.redirect(to: decoded_link)
    _ -> wisp.bad_request()
  }
}
