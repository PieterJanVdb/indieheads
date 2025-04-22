import birdie
import gleam/list
import indieheads/web/slack/block
import indieheads/web/slack/composition_object as co
import indieheads/web/slack/element_object as eo
import indieheads/web/slack/message

pub fn build_message_test() {
  let msg =
    message.build(
      [
        block.section([
          block.section_text(co.text("status", [co.text_kind(co.Markdown)])),
        ]),
        block.section([
          block.section_fields(
            [
              co.text("*Artist*", [co.text_kind(co.Markdown)]),
              co.text("*Name*", [co.text_kind(co.Markdown)]),
              co.text("artist", []),
              co.text("name", []),
              co.text("*Album*", [co.text_kind(co.Markdown)]),
              co.text("*Stream*", [co.text_kind(co.Markdown)]),
              co.text("album", []),
              co.text("spotify_link", [co.text_kind(co.Markdown)]),
            ]
            |> list.map(block.Text),
          ),
          block.section_accessory(
            eo.image("some_url", [eo.image_alt_text("Thumbnail")]),
          ),
        ]),
      ],
      where: message.InChannel,
    )

  birdie.snap(msg, title: "build message")
}
