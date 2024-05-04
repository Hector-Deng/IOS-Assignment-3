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

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    SearchBarView(searchText: $city)
                        .padding(.horizontal)
                        .padding(.top, 20)

                    if let weather = weatherResponse {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("\(city)")
                                .font(.largeTitle)
                                .fontWeight(.bold)

                            Text("Temperature: \(String(format: "%.1f°C", weather.current.temp))")
                                .font(.title)
                            Text("Description: \(weather.current.weather.first?.description ?? "N/A")")
                            Text("Feels like: \(String(format: "%.1f°C", weather.current.feels_like))")
                            Text("UV Index: \(weather.current.uvi)")
                            Text("Humidity: \(weather.current.humidity)%")
                            Text("Sunrise: \(convertTime(timeInterval: weather.current.sunrise, timezoneOffset: weather.timezone_offset))")
                            Text("Sunset: \(convertTime(timeInterval: weather.current.sunset, timezoneOffset: weather.timezone_offset))")

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(weather.hourly, id: \.dt) { hour in
                                        HourlyWeatherCard(hour: hour, timezoneOffset: weather.timezone_offset)
                                    }
                                }
                                .padding()
                            }
                        }
                        .padding()
                    } else {
                        Spacer()
                        Text("Loading weather data...")
                            .foregroundColor(.gray)
                        Spacer()
                    }
                }
            }
            .navigationBarTitle("Weather", displayMode: .inline)
            .navigationBarItems(trailing: HStack {
                            // Refresh button
                            Button(action: {
                                loadWeather()
                            }) {
                                Image(systemName: "arrow.clockwise")
                            }
                            
                            // Space between buttons (optional)
                            Spacer(minLength: 10)

                            // NavigationLink to MapsView with map icon
                            NavigationLink(destination: MapView()) {
                                Image(systemName: "map.fill")
                                    .foregroundColor(.blue) // Customize color if needed
                            }
                        })
                    }
        .onAppear(perform: loadWeather)
    }

    private func loadWeather() {
        let latitude = -33.8688  // Sydney latitude
        let longitude = 151.2093 // Sydney longitude
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

func convertTime(timeInterval: TimeInterval, timezoneOffset: Int) -> String {
    let date = Date(timeIntervalSince1970: timeInterval)
    let dateFormatter = DateFormatter()
    dateFormatter.timeZone = TimeZone(secondsFromGMT: timezoneOffset + 36000) // Sydney GMT+10
    dateFormatter.dateFormat = "h:mm a"
    return dateFormatter.string(from: date)
}

struct HourlyWeatherCard: View {
    let hour: WeatherResponse.HourlyWeather
    let timezoneOffset: Int

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

// Preview provider
struct WeatherView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherView()
    }
}

