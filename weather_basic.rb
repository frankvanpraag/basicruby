#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

city = ARGV.first
unless city
  warn "Usage: ruby weather_simple.rb <city>"
  exit 1
end

def http_get_json(base_url, params)
  uri = URI(base_url)
  uri.query = URI.encode_www_form(params)
  res = Net::HTTP.get_response(uri)
  unless res.is_a?(Net::HTTPSuccess)
    warn "Request failed: HTTP #{res.code}"
    exit 1
  end
  JSON.parse(res.body)
end

geo_json = http_get_json(
  "https://geocoding-api.open-meteo.com/v1/search",
  { "name" => city, "count" => "1", "language" => "en" }
)

places = geo_json["results"]
#puts JSON.pretty_generate(places) # show the places array of objects for debugging

if places.nil? || places.empty?
  warn "No results for #{city.inspect}"
  exit 1
end

place = places.first
lat = place["latitude"]
lon = place["longitude"]
label = [place["name"], place["admin1"], place["country"]].compact.reject(&:empty?).join(", ")

forecast_json = http_get_json(
  "https://api.open-meteo.com/v1/forecast",
  {
    "latitude" => lat.to_s,
    "longitude" => lon.to_s,
    "current" => "temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m"
  }
)

current = forecast_json["current"] || {}
puts "Location: #{label}"
puts "Temperature: #{current['temperature_2m']} °C"
puts "Humidity: #{current['relative_humidity_2m']}%"
puts "Weather code: #{current['weather_code']}"
puts "Wind (10m): #{current['wind_speed_10m']} km/h"
