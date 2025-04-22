import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import indieheads/web/slack/composition_object as co
import indieheads/web/slack/element_object as eo

pub type SectionBlockField {
  Text(co.TextObject)
  Image(eo.ImageElementObject)
}

pub type SectionBlock {
  SectionBlock(
    text: Option(co.TextObject),
    fields: Option(List(SectionBlockField)),
    accessory: Option(eo.ImageElementObject),
  )
}

pub type ContextBlock {
  ContextBlock(fields: List(co.TextObject))
}

pub type Block {
  Section(SectionBlock)
  Context(ContextBlock)
  Divider
}

pub type SectionOption =
  fn(SectionBlock) -> SectionBlock

fn section_block_field_to_json(field: SectionBlockField) -> json.Json {
  case field {
    Text(obj) -> co.text_object_to_json(obj)
    Image(obj) -> eo.img_el_object_to_json(obj)
  }
}

fn section_block_to_json(block: SectionBlock) -> json.Json {
  let props = [#("type", json.string("section"))]

  let props = case block.fields {
    Some(fields) -> [
      #("fields", json.array(fields, of: section_block_field_to_json)),
      ..props
    ]
    _ -> props
  }

  let props = case block.text {
    Some(text) -> [#("text", co.text_object_to_json(text)), ..props]
    _ -> props
  }

  let props = case block.accessory {
    Some(accessory) -> [
      #("accessory", eo.img_el_object_to_json(accessory)),
      ..props
    ]
    _ -> props
  }

  json.object(props)
}

fn context_block_to_json(block: ContextBlock) {
  json.object([
    #("type", json.string("context")),
    #("elements", json.array(block.fields, of: co.text_object_to_json)),
  ])
}

fn divider_block_to_json() {
  json.object([#("type", json.string("divider"))])
}

pub fn to_json(block: Block) {
  case block {
    Section(block) -> section_block_to_json(block)
    Context(block) -> context_block_to_json(block)
    Divider -> divider_block_to_json()
  }
}

pub fn section(options: List(SectionOption)) -> Block {
  let section = {
    let init = SectionBlock(fields: None, text: None, accessory: None)
    use init, setup <- list.fold(options, init)
    setup(init)
  }

  Section(section)
}

pub fn section_text(text: co.TextObject) -> SectionOption {
  fn(obj: SectionBlock) { SectionBlock(..obj, text: Some(text)) }
}

pub fn section_accessory(accessory: eo.ImageElementObject) -> SectionOption {
  fn(obj: SectionBlock) { SectionBlock(..obj, accessory: Some(accessory)) }
}

pub fn section_fields(fields: List(SectionBlockField)) -> SectionOption {
  fn(obj: SectionBlock) { SectionBlock(..obj, fields: Some(fields)) }
}

pub fn context(fields: List(co.TextObject)) {
  Context(ContextBlock(fields:))
}

pub fn divider() {
  Divider
}
