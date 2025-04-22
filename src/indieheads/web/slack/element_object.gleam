import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}

pub type ImageElementObject {
  ImageElementObject(url: String, alt_text: Option(String))
}

pub type ImageOption =
  fn(ImageElementObject) -> ImageElementObject

pub fn img_el_object_to_json(obj: ImageElementObject) -> json.Json {
  let props = [
    #("type", json.string("image")),
    #("image_url", json.string(obj.url)),
  ]

  case obj.alt_text {
    Some(alt_text) -> [#("alt_text", json.string(alt_text)), ..props]
    _ -> props
  }
  |> json.object()
}

pub fn image(url: String, options: List(ImageOption)) {
  let init = ImageElementObject(url:, alt_text: None)
  use init, setup <- list.fold(options, init)
  setup(init)
}

pub fn image_alt_text(alt_text: String) -> ImageOption {
  fn(obj: ImageElementObject) {
    ImageElementObject(..obj, alt_text: Some(alt_text))
  }
}
