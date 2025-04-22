import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import indieheads/web/slack/composition_object as co
import indieheads/web/slack/element_object as eo

pub type SectionBlockField {
  CompositionObjectField(co.CompositionObject)
  ElementObjectField(eo.ElementObject)
}

pub type SectionBlock {
  SectionBlock(
    text: Option(co.CompositionObject),
    fields: Option(List(SectionBlockField)),
    accessory: Option(eo.ElementObject),
  )
}

pub type Block {
  Section(SectionBlock)
}

pub type SectionOption =
  fn(SectionBlock) -> SectionBlock

fn section_block_field_to_json(field: SectionBlockField) -> json.Json {
  case field {
    CompositionObjectField(obj) -> co.to_json(obj)
    ElementObjectField(obj) -> eo.to_json(obj)
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
    Some(text) -> [#("text", co.to_json(text)), ..props]
    _ -> props
  }

  let props = case block.accessory {
    Some(accessory) -> [#("accessory", eo.to_json(accessory)), ..props]
    _ -> props
  }

  json.object(props)
}

pub fn to_json(block: Block) {
  case block {
    Section(block) -> section_block_to_json(block)
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

pub fn section_text(text: co.CompositionObject) -> SectionOption {
  fn(obj: SectionBlock) { SectionBlock(..obj, text: Some(text)) }
}

pub fn section_accessory(accessory: eo.ElementObject) -> SectionOption {
  fn(obj: SectionBlock) { SectionBlock(..obj, accessory: Some(accessory)) }
}

pub fn section_fields(fields: List(SectionBlockField)) -> SectionOption {
  fn(obj: SectionBlock) { SectionBlock(..obj, fields: Some(fields)) }
}

pub fn co_field(obj: co.CompositionObject) -> SectionBlockField {
  CompositionObjectField(obj)
}
