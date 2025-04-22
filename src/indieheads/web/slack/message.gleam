import gleam/json
import indieheads/web/slack/block

pub type BuildMessageError {
  NoBlocksProvided
}

pub fn build(blocks: List(block.Block)) -> String {
  json.object([
    #("response_type", json.string("in_channel")),
    #("blocks", json.array(blocks, of: block.to_json)),
  ])
  |> json.to_string()
}
