import gleam/dynamic/decode
import gleam/float
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/result
import gleam/string
import indieheads/error

const open_weather_host = "api.openweathermap.org"

pub opaque type OpenWeather {
  OpenWeather(api_key: String)
}

// lat, lon
pub type Coords =
  #(Float, Float)

pub type Geolocation {
  Geolocation(name: String, emoji: String, coords: Coords)
}

// celcius, fahrenheit
pub type Temperature =
  #(Float, Float)

pub type CurrentWeather {
  CurrentWeather(
    description: String,
    temperature: Temperature,
    feels_like: Temperature,
    humidity: Int,
    emoji: String,
    location: Geolocation,
  )
}

pub fn new(api_key: String) {
  OpenWeather(api_key:)
}

fn weather_icon_to_emoji(icon: String) {
  case icon {
    "02d" -> ":partly_sunny:"
    "03d" -> ":cloud:"
    "04d" -> ":cloud:"
    "09d" -> ":rain_cloud:"
    "10d" -> ":partly_sunny_rain:"
    "11d" -> ":thunder_cloud_and_rain:"
    "13d" -> ":snowflake:"
    "50d" -> ":fog:"
    "01n" -> ":new_moon:"
    "02n" -> ":cloud:"
    "03n" -> ":cloud:"
    "04n" -> ":cloud:"
    "09n" -> ":rain_cloud:"
    "10n" -> ":rain_cloud:"
    "11n" -> ":thunder_cloud_and_rain"
    "13n" -> ":snowflake:"
    "50n" -> ":fog:"
    _ -> ":sunny:"
    // just default to sunny
  }
}

fn c_to_f(from: Float) {
  float.multiply(from, 1.8) |> float.add(32.0)
}

fn geolocation_decoder() {
  use country <- decode.field("country", decode.string)
  use name <- decode.field("name", decode.string)
  use lat <- decode.field("lat", decode.float)
  use lon <- decode.field("lon", decode.float)

  let emoji = ":flag-" <> string.lowercase(country) <> ":"

  decode.success(Geolocation(emoji:, name:, coords: #(lat, lon)))
}

fn get_geolocation(client: OpenWeather, query: String) {
  let req =
    request.new()
    |> request.set_host(open_weather_host)
    |> request.set_path("/geo/1.0/direct")
    |> request.set_query([
      #("q", query),
      #("limit", "1"),
      #("appid", client.api_key),
    ])

  use resp <- result.try(httpc.send(req) |> result.map_error(error.FetchError))

  case resp.status {
    200 -> {
      let decoder = decode.at([0], geolocation_decoder())
      json.parse(resp.body, decoder)
      |> result.map_error(error.JsonError)
    }
    _ ->
      Error(error.WeatherError(
        "Error getting geolocation for '" <> query <> "': " <> resp.body,
      ))
  }
}

fn current_decoder(location: Geolocation) {
  let description_and_icon_decoder = {
    let decoder = {
      use description <- decode.field("description", decode.string)
      use icon <- decode.field("icon", decode.string)
      decode.success(#(description, icon))
    }
    let first_weather_decoder = decode.at([0], decoder)
    decode.at(["weather"], first_weather_decoder)
  }

  use #(description, icon) <- decode.then(description_and_icon_decoder)
  use c_temp <- decode.subfield(["main", "temp"], decode.float)
  use c_feel <- decode.subfield(["main", "feels_like"], decode.float)
  use humidity <- decode.subfield(["main", "humidity"], decode.int)

  let emoji = weather_icon_to_emoji(icon)
  let temperature = #(c_temp, c_to_f(c_temp))
  let feels_like = #(c_feel, c_to_f(c_feel))

  decode.success(CurrentWeather(
    description:,
    temperature:,
    feels_like:,
    humidity:,
    emoji:,
    location:,
  ))
}

/// query is in the format {city},{state code},{country}
/// where {state code} is only available for the US
pub fn get_current_weather(client: OpenWeather, query: String) {
  use location <- result.try(get_geolocation(client, query))

  let req =
    request.new()
    |> request.set_host(open_weather_host)
    |> request.set_path("/data/2.5/weather")
    |> request.set_query([
      #("lat", location.coords.0 |> float.to_string()),
      #("lon", location.coords.1 |> float.to_string()),
      #("units", "metric"),
      #("appid", client.api_key),
    ])

  use resp <- result.try(httpc.send(req) |> result.map_error(error.FetchError))

  case resp.status {
    200 -> {
      json.parse(resp.body, current_decoder(location))
      |> result.map_error(error.JsonError)
    }
    _ ->
      Error(error.WeatherError(
        "Error getting current weather for '" <> query <> "': " <> resp.body,
      ))
  }
}
