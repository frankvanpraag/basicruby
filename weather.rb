#!/usr/bin/env ruby
# frozen_string_literal: true
# This script uses the Open-Meteo API to get the weather for a given city.
# It first gets the latitude and longitude of the city using the geocoding API.
# Then it gets the weather for the city using the forecast API.
# It prints the weather to the console.   


require "bundler/setup"
require "httparty"

city = ARGV.first
unless city
  warn "Usage: ruby weather.rb <city>"
  exit 1
end

geo = HTTParty.get(
  "https://geocoding-api.open-meteo.com/v1/search",
  query: { name: city, count: 1, language: "en" }
)

unless geo.success?
  warn "Geocoding request failed: HTTP #{geo.code}"
  exit 1
end

places = geo.parsed_response["results"]
if places.nil? || places.empty?
  warn "No results for #{city.inspect}"
  exit 1
end

place = places.first
lat = place["latitude"]
lon = place["longitude"]
label = [place["name"], place["admin1"], place["country"]].compact.reject(&:empty?).join(", ")

forecast = HTTParty.get(
  "https://api.open-meteo.com/v1/forecast",
  query: {
    latitude: lat,
    longitude: lon,
    current: "temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m"
  }
)

unless forecast.success?
  warn "Forecast request failed: HTTP #{forecast.code}"
  exit 1
end

current = forecast.parsed_response["current"] || {}
puts "Location: #{label}"
puts "Temperature: #{current['temperature_2m']} °C"
puts "Humidity: #{current['relative_humidity_2m']}%"
puts "Weather code: #{current['weather_code']}"
puts "Wind (10m): #{current['wind_speed_10m']} km/h"
