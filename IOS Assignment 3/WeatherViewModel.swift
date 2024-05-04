//
//  WeatherViewModel.swift
//
import Foundation
import Combine

class WeatherViewModel: ObservableObject {
    @Published var weatherResponse: WeatherResponse?
    @Published var city: String = "Sydney"

    let apiKey = "645b6c195d49ee0b1f364003c7887e44"

    func fetchLocation(for city: String) {
        let formattedCity = city.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
        let urlString = "http://api.openweathermap.org/geo/1.0/direct?q=\(formattedCity)&limit=1&appid=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error in getting position: \(error)")
                return
            }

            guard let data = data else {
                print("Did not receive position info")
                return
            }

            if let locations = try? JSONDecoder().decode([Location].self, from: data), let location = locations.first {
                self.fetchWeather(latitude: location.lat, longitude: location.lon)
            } else {
                print("Fail to decode position info")
            }
        }.resume()
    }

    func fetchWeather(latitude: Double, longitude: Double) {
        let urlString = "https://api.openweathermap.org/data/3.0/onecall?lat=\(latitude)&lon=\(longitude)&exclude=minutely,daily,alerts&appid=\(apiKey)&units=metric"
        
        guard let url = URL(string: urlString) else {
            print("Invaild URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error in getting weather info: \(error)")
                return
            }

            guard let data = data else {
                print("Did not receive Weather info")
                return
            }

            DispatchQueue.main.async {
                self.weatherResponse = try? JSONDecoder().decode(WeatherResponse.self, from: data)
            }
        }.resume()
    }
}

struct Location: Decodable {
    let lat: Double
    let lon: Double
}

struct WeatherResponse: Decodable {
    let current: CurrentWeather
    let hourly: [HourlyWeather]
    let timezone_offset: Int

    struct CurrentWeather: Decodable {
        let temp: Double
        let feels_like: Double
        let uvi: Double
        let humidity: Int
        let sunrise: TimeInterval
        let sunset: TimeInterval
        let weather: [WeatherDetail]
    }
    
    struct HourlyWeather: Decodable {
        let dt: TimeInterval
        let temp: Double
        let pop: Double
        let weather: [WeatherDetail]
    }
    
    struct WeatherDetail: Decodable {
        let description: String
        let icon: String
    }
}

let weatherIconMapping: [String: String] = [
    "01d": "sun.max.fill", // clear sky day
    "01n": "moon.stars.fill", // clear sky night
    "02d": "cloud.sun.fill", // few clouds day
    "02n": "cloud.moon.fill", // few clouds night
    "03d": "cloud.fill", // scattered clouds
    "03n": "cloud.fill", // scattered clouds
    "04d": "smoke.fill", // broken clouds
    "04n": "smoke.fill", // broken clouds
    "09d": "cloud.drizzle.fill", // shower rain
    "09n": "cloud.drizzle.fill", // shower rain
    "10d": "cloud.heavyrain.fill", // rain day
    "10n": "cloud.heavyrain.fill", // rain night
    "11d": "cloud.bolt.fill", // thunderstorm
    "11n": "cloud.bolt.fill", // thunderstorm
    "13d": "snowflake", // snow
    "13n": "snowflake", // snow
    "50d": "cloud.fog.fill", // mist
    "50n": "cloud.fog.fill" // mist
]
