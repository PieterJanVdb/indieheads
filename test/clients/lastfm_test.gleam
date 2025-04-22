import gleam/option.{Some}
import gleeunit/should
import indieheads/clients/lastfm

pub fn parse_test() {
  let json =
    "{\"recenttracks\":{\"track\":[{\"artist\":{\"mbid\":\"\",\"#text\":\"Dj suzy\"},\"streamable\":\"0\",\"image\":[{\"size\":\"small\",\"#text\":\"https:\\/\\/lastfm.freetls.fastly.net\\/i\\/u\\/34s\\/c94fe9bb8158601755cd410c4f2c3883.jpg\"},{\"size\":\"medium\",\"#text\":\"https:\\/\\/lastfm.freetls.fastly.net\\/i\\/u\\/64s\\/c94fe9bb8158601755cd410c4f2c3883.jpg\"},{\"size\":\"large\",\"#text\":\"https:\\/\\/lastfm.freetls.fastly.net\\/i\\/u\\/174s\\/c94fe9bb8158601755cd410c4f2c3883.jpg\"},{\"size\":\"extralarge\",\"#text\":\"https:\\/\\/lastfm.freetls.fastly.net\\/i\\/u\\/300x300\\/c94fe9bb8158601755cd410c4f2c3883.jpg\"}],\"mbid\":\"\",\"album\":{\"mbid\":\"\",\"#text\":\"Haunted Disc\"},\"name\":\"spells\",\"@attr\":{\"nowplaying\":\"true\"},\"url\":\"https:\\/\\/www.last.fm\\/music\\/Dj+suzy\\/_\\/spells\"},{\"artist\":{\"mbid\":\"13e2db47-3010-48b8-a8b9-667551f37119\",\"#text\":\"Oklou\"},\"streamable\":\"0\",\"image\":[{\"size\":\"small\",\"#text\":\"https:\\/\\/lastfm.freetls.fastly.net\\/i\\/u\\/34s\\/3ac17bf2160fd9d6503fc509e0841655.jpg\"},{\"size\":\"medium\",\"#text\":\"https:\\/\\/lastfm.freetls.fastly.net\\/i\\/u\\/64s\\/3ac17bf2160fd9d6503fc509e0841655.jpg\"},{\"size\":\"large\",\"#text\":\"https:\\/\\/lastfm.freetls.fastly.net\\/i\\/u\\/174s\\/3ac17bf2160fd9d6503fc509e0841655.jpg\"},{\"size\":\"extralarge\",\"#text\":\"https:\\/\\/lastfm.freetls.fastly.net\\/i\\/u\\/300x300\\/3ac17bf2160fd9d6503fc509e0841655.jpg\"}],\"mbid\":\"198ab0e4-ccfd-4a84-86de-17e3c444c35e\",\"album\":{\"mbid\":\"d567881a-1e38-4222-96c0-db03f099fbd1\",\"#text\":\"choke enough\"},\"name\":\"Obvious\",\"url\":\"https:\\/\\/www.last.fm\\/music\\/Oklou\\/_\\/Obvious\",\"date\":{\"uts\":\"1745260095\",\"#text\":\"21 Apr 2025, 18:28\"}}],\"@attr\":{\"user\":\"PieGie\",\"totalPages\":\"179903\",\"page\":\"1\",\"perPage\":\"1\",\"total\":\"179903\"}}}"

  lastfm.parse_recent_tracks(json)
  |> should.be_ok()
  |> should.equal(lastfm.Track(
    "Dj suzy",
    "Haunted Disc",
    "spells",
    Some(
      "https://lastfm.freetls.fastly.net/i/u/174s/c94fe9bb8158601755cd410c4f2c3883.jpg",
    ),
    True,
  ))
}

pub fn parse_not_playing_test() {
  let json =
    "{\"recenttracks\":{\"track\":[{\"artist\":{\"mbid\":\"d614b0ad-fe3a-4927-b413-48cb831a814b\",\"#text\":\"Frou Frou\"},\"streamable\":\"0\",\"image\":[{\"size\":\"small\",\"#text\":\"https:\\/\\/lastfm.freetls.fastly.net\\/i\\/u\\/34s\\/5cd37564f12cb92824e8fea9b6cddb9f.jpg\"},{\"size\":\"medium\",\"#text\":\"https:\\/\\/lastfm.freetls.fastly.net\\/i\\/u\\/64s\\/5cd37564f12cb92824e8fea9b6cddb9f.jpg\"},{\"size\":\"large\",\"#text\":\"https:\\/\\/lastfm.freetls.fastly.net\\/i\\/u\\/174s\\/5cd37564f12cb92824e8fea9b6cddb9f.jpg\"},{\"size\":\"extralarge\",\"#text\":\"https:\\/\\/lastfm.freetls.fastly.net\\/i\\/u\\/300x300\\/5cd37564f12cb92824e8fea9b6cddb9f.jpg\"}],\"mbid\":\"063c3fbd-82f3-314c-a829-9d9713a7694f\",\"album\":{\"mbid\":\"0ed73915-1c56-4adc-9f16-5b718854e4b7\",\"#text\":\"Details\"},\"name\":\"Breathe In\",\"url\":\"https:\\/\\/www.last.fm\\/music\\/Frou+Frou\\/_\\/Breathe+In\",\"date\":{\"uts\":\"1745265727\",\"#text\":\"21 Apr 2025, 20:02\"}}],\"@attr\":{\"user\":\"PieGie\",\"totalPages\":\"179922\",\"page\":\"1\",\"perPage\":\"1\",\"total\":\"179922\"}}}"

  lastfm.parse_recent_tracks(json)
  |> should.be_ok()
  |> should.equal(lastfm.Track(
    "Frou Frou",
    "Details",
    "Breathe In",
    Some(
      "https://lastfm.freetls.fastly.net/i/u/174s/5cd37564f12cb92824e8fea9b6cddb9f.jpg",
    ),
    False,
  ))
}
