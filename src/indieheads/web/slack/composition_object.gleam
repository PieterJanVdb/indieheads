import gleam/json
import gleam/list

pub type TextObject {
  TextObject(text: String, kind: TextObjectKind)
}

pub type TextObjectKind {
  PlainText
  Markdown
}

pub type CompositionObject {
  Text(TextObject)
}

pub type TextOption =
  fn(TextObject) -> TextObject

fn text_object_to_json(obj: TextObject) -> json.Json {
  let kind = case obj.kind {
    Markdown -> "mrkdwn"
    PlainText -> "plain_text"
  }

  json.object([#("type", json.string(kind)), #("text", json.string(obj.text))])
}

pub fn to_json(obj: CompositionObject) -> json.Json {
  case obj {
    Text(obj) -> text_object_to_json(obj)
  }
}

pub fn text(text: String, options: List(TextOption)) -> CompositionObject {
  let text_object = {
    let init = TextObject(text, kind: PlainText)
    use init, setup <- list.fold(options, init)
    setup(init)
  }

  Text(text_object)
}

pub fn text_kind(kind: TextObjectKind) -> TextOption {
  fn(obj: TextObject) { TextObject(..obj, kind:) }
}
