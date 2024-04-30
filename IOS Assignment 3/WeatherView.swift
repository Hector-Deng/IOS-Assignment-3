//
//  WeatherView.swift
//  IOS Assignment 3
//
//  
//

import SwiftUI


struct WeatherView: View {
    @State private var weatherResponse: WeatherResponse?
    @State private var city: String = "Sydney"

struct WeatherView: View {
    @State private var weatherResponse: WeatherResponse?
    @State private var city: String = "Sydney"

    var body: some View {
        VStack {
            SearchBarView(searchText: $city)
                .padding(.horizontal)
                .padding(.top, 20)
            
            if let weather = weatherResponse {
                WeatherSummaryView(weather: weather.current)
                
                Divider()
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(weather.hourly, id: \.dt) { hour in
                            HourlyWeatherCard(hour: hour, timezoneOffset: weather.timezone_offset)
                        }
                    }
                    .padding()
                }
            } else {
                Spacer()
                Text("Loading weather data...")
                    .foregroundColor(.gray)
                Spacer()
            }
        }
        .onAppear(perform: loadWeather)
        .background(Color("Background"))
        .edgesIgnoringSafeArea(.all)
    }
}

struct WeatherSummaryView: View {
    var weather: CurrentWeather

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(city)")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("\(String(format: "%.1f°C", weather.temp)) • \(weather.weather.first?.description.capitalized ?? "N/A")")
                .font(.title)
            
            HStack {
                WeatherDetail(title: "Feels like", value: String(format: "%.1f°C", weather.feels_like))
                WeatherDetail(title: "Humidity", value: "\(weather.humidity)%")
                WeatherDetail(title: "UV Index", value: String(format: "%.1f", weather.uvi))
            }
            
            HStack {
                WeatherDetail(title: "Sunrise", value: convertTime(timeInterval: weather.sunrise, timezoneOffset: weather.timezone_offset))
                WeatherDetail(title: "Sunset", value: convertTime(timeInterval: weather.sunset, timezoneOffset: weather.timezone_offset))
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.5)))
        .shadow(radius: 5)
    }
}

struct HourlyWeatherCard: View {
    var hour: HourlyWeather
    var timezoneOffset: Int

    var body: some View {
        VStack {
            Text(convertTime(timeInterval: hour.dt, timezoneOffset: timezoneOffset))
                .font(.caption)
            Image(systemName: weatherIconMapping[hour.weather.first?.icon ?? "cloud"] ?? "cloud.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
            Text("\(String(format: "%.1f°C", hour.temp))")
            Text("Pop: \(Int(hour.pop * 100))%")
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.5)))
        .shadow(radius: 3)
    }
}
    
    private func loadWeather() {
        let latitude = -33.865143  // latitude
        let longitude = 151.209900 // longitude
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
    
    private func convertTime(timeInterval: TimeInterval, timezoneOffset: Int) -> String {
        let date = Date(timeIntervalSince1970: timeInterval)
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: timezoneOffset + 36000) // Sydney GMT+10
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.string(from: date)
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
    // API key
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





#Preview {
    WeatherView()
}
