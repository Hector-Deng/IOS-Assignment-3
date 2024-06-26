//
//  WeatherViewModel.swift
//
import Foundation
import Combine

class WeatherViewModel: ObservableObject {
    @Published var weatherResponse: WeatherResponse?
    @Published var city: String = ""
    @Published var isFavorite: Bool = false
    @Published var lastLocation: (lat: Double, lon: Double)?
    @Published var weatherData: [String: WeatherResponse] = [:]
    
    

    let apiKey = "645b6c195d49ee0b1f364003c7887e44"//OpenWeatherMap APIkey

    func fetchLocation(for city: String) {//Use city name to find the loaction by using geo-API
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

            //Decode the loaction info then apply the lat&lon
            if let locations = try? JSONDecoder().decode([Location].self, from: data), let location = locations.first {
                DispatchQueue.main.async {
                    self.lastLocation = (lat: location.lat, lon: location.lon)
                }
                //Search the weather with the lon&lat
                self.fetchWeather(latitude: location.lat, longitude: location.lon)
            } else {
                print("Fail to decode position info")
            }
        }.resume()
    }


    
    func fetchWeather(latitude: Double, longitude: Double) {

        let key = "\(latitude),\(longitude)"
        if self.weatherData[key] != nil {//USe weatherdate to save a list of weather
            self.weatherResponse = self.weatherData[key]//update current weather object
            return
        }

        //USE lon&lat to get weather from API
        let urlString = "https://api.openweathermap.org/data/3.0/onecall?lat=\(latitude)&lon=\(longitude)&exclude=minutely,daily,alerts&appid=\(apiKey)&units=metric"
        URLSession.shared.dataTask(with: URL(string: urlString)!) { [weak self] data, response, error in
            guard let self = self else { return }
            if let error = error {
                print("Error in getting weather info: \(error)")
                return
            }

            guard let data = data else {
                print("Did not receive weather info")
                return
            }

            DispatchQueue.main.async {
                if let weatherResponse = try? JSONDecoder().decode(WeatherResponse.self, from: data) {
                    self.weatherData[key] = weatherResponse  //update weather in weatherdata
                    self.weatherResponse = weatherResponse  // Update the weatherResponse
                }
            }
        }.resume()
    }


}

struct Location: Decodable {
    let lat: Double
    let lon: Double
}

struct WeatherResponse: Decodable {//Weather data structure
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

//Weather Icon for different waether(day&night)
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