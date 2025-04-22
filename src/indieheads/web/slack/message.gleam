import gleam/json
import indieheads/web/slack/block

pub type BuildMessageError {
  NoBlocksProvided
}

pub type ResponseTarget {
  InChannel
  Ephemeral
}

pub fn build(blocks: List(block.Block), where where: ResponseTarget) -> String {
  let props = [#("blocks", json.array(blocks, of: block.to_json))]

  let props = case where {
    InChannel -> [#("response_type", json.string("in_channel")), ..props]
    Ephemeral -> props
  }

  json.object(props) |> json.to_string()
}
