//
//  WeatherView.swift
//  IOS Assignment 3
//
//  
//

import SwiftUI


import SwiftUI

struct WeatherView: View {
    @State private var weatherResponse: WeatherResponse?
    @State private var city: String = "Sydney"

    var body: some View {
        VStack(alignment: .leading){
            SearchBarView(searchText: $city)
            HStack {
                Text("\(city)")
                    .font(.title)
                Spacer()
                Image(systemName: "gear")
            }
            .padding()
            if let weather = weatherResponse {
                let formattedTemp = String(format: "%.1f°C", weather.current.temp)
                Text(formattedTemp)
                    .font(.system(size: 70))
                    .fontWeight(.medium)
                HStack {
                    ForEach(weather.current.weather, id: \.description) { weatherDetail in
                        WeatherDetail(imageName: "cloud.fill", detailText: weatherDetail.description.capitalized)
                    }
                    let formattedWindSpeed = String(format: "%.1f km/h", weather.current.wind_speed)
                    WeatherDetail(imageName: "wind", detailText: formattedWindSpeed)
                    WeatherDetail(imageName: "sunrise.fill", detailText: "Sunrise: \(Date(timeIntervalSince1970: weather.current.sunrise).formatted())")
                    WeatherDetail(imageName: "sunset.fill", detailText: "Sunset: \(Date(timeIntervalSince1970: weather.current.sunset).formatted())")
                }
            } else {
                Text("Loading weather data...")
            }
        }
        .onAppear(perform: loadWeather)
        Spacer()
    }

    private func loadWeather() {
        let latitude = 33.44  // 示例纬度
        let longitude = -94.04 // 示例经度
        WeatherService().fetchWeather(latitude: latitude, longitude: longitude) { result in
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    self.weatherResponse = response
                }
            case .failure(let error):
                print("Error fetching weather: \(error)")
            }
        }
    }
}







// 这只是示意用法，具体图标与天气状态的映射需要根据实际情况来设置

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


struct WeatherDetail: View {
    let imageName: String
    let detailText: String
    
    var body: some View {
        VStack {
            Image(systemName: imageName)
                .font(.largeTitle)
                .foregroundColor(.yellow)
            Text(detailText)
                .font(.caption)
        }
    }
}

struct SearchBarView: View {
    @Binding var searchText: String
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(.blue)
            HStack {
                TextField("Search for a new destination", text: $searchText)
                    .padding(.leading, 40)
                Spacer()
                Image(systemName: "magnifyingglass")
                Image(systemName: "bell.fill")
            }
            .foregroundColor(.white)
            .padding()
        }
        .frame(height: 50)
    }
}

class WeatherService {
    // 使用您的实际 API 密钥
    let apiKey = "645b6c195d49ee0b1f364003c7887e44"
    
    func fetchWeather(latitude: Double, longitude: Double, completion: @escaping (Result<WeatherResponse, Error>) -> Void) {
        let urlString = "https://api.openweathermap.org/data/3.0/onecall?lat=\(latitude)&lon=\(longitude)&exclude=minutely,daily,alerts&appid=\(apiKey)&units=metric"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Network request failed: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                let weatherResponse = try JSONDecoder().decode(WeatherResponse.self, from: data)
                completion(.success(weatherResponse))
            } catch {
                print("JSON decoding failed: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
}


struct WeatherResponse: Decodable {
    let current: CurrentWeather
    struct CurrentWeather: Decodable {
        let temp: Double
        let weather: [Weather]
        let wind_speed: Double
        let sunrise: TimeInterval
        let sunset: TimeInterval
    }
    
    struct Weather: Decodable {
        let description: String
        let icon: String
    }
}




#Preview {
    WeatherView()
}
