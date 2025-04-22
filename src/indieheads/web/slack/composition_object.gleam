import gleam/json
import gleam/list

pub type TextObject {
  TextObject(text: String, kind: TextObjectKind)
}

pub type TextObjectKind {
  PlainText
  Markdown
}

pub type TextOption =
  fn(TextObject) -> TextObject

pub fn text_object_to_json(obj: TextObject) {
  let kind = case obj.kind {
    Markdown -> "mrkdwn"
    PlainText -> "plain_text"
  }

  json.object([#("type", json.string(kind)), #("text", json.string(obj.text))])
}

pub fn text(text: String, options: List(TextOption)) {
  let init = TextObject(text, kind: PlainText)
  use init, setup <- list.fold(options, init)
  setup(init)
}

pub fn text_kind(kind: TextObjectKind) -> TextOption {
  fn(obj: TextObject) { TextObject(..obj, kind:) }
}
