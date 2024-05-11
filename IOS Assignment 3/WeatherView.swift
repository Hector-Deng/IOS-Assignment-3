//
//  WeatherView.swift
//  IOS Assignment 3
//
//
//

import SwiftUI
import Foundation

struct WeatherView: View {
    @ObservedObject var viewModel: WeatherViewModel = WeatherViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    SearchBarView(searchText: $viewModel.city, searchAction: {
                        viewModel.fetchLocation(for: viewModel.city)
                    })
                    .padding(.top, 20)

                    if let weather = viewModel.weatherResponse {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("\(String(format: "%.0f", weather.current.temp))°")
                                    .font(.system(size: 60))
                                    .fontWeight(.bold)
                                Spacer()
                                Image(systemName: weatherIconMapping[weather.current.weather.first?.icon ?? "cloud"] ?? "cloud.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 60)
                            }
                            .padding()

                            DetailBox(weather: weather)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(weather.hourly, id: \.dt) { hour in
                                        HourlyWeatherCard(hour: hour, timezoneOffset: weather.timezone_offset)
                                    }
                                }
                                .padding()
                            }

                            EnvironmentalFactorsBox(weather: weather)
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
        }
    }
}



struct DetailBox: View {
    var weather: WeatherResponse

    var body: some View {
        GroupBox(label: Text("Weather Details").bold()) {
            VStack(alignment: .leading) {
                Text("Description: \(weather.current.weather.first?.description ?? "N/A")")
                Text("Feels like: \(String(format: "%.1f°C", weather.current.feels_like))")
                Text("Sunrise: \(convertTime(timeInterval: weather.current.sunrise, timezoneOffset: weather.timezone_offset))")
                Text("Sunset: \(convertTime(timeInterval: weather.current.sunset, timezoneOffset: weather.timezone_offset))")
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
        }
        .padding()
    }
}


struct EnvironmentalFactorsBox: View {
    var weather: WeatherResponse

    var body: some View {
        GroupBox(label: Text("Environmental Factors").bold()) {
            VStack {
                SliderView(value: Double(weather.current.humidity), maxValue: 100, label: "Humidity")
                SliderView(value: weather.current.uvi, maxValue: 10, label: "UV Index")
                SliderView(value: 50, maxValue: 100, label: "Hyperpigmentation")
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

struct SliderView: View {
    var value: Double
    var maxValue: Double
    var label: String

    var body: some View {
        VStack(alignment: .leading) {
            Text("\(label): \(String(format: "%.0f", value))")
            
            ZStack(alignment: .leading) {
                // colorful bar
                RoundedRectangle(cornerRadius: 5)
                    .fill(LinearGradient(gradient: Gradient(colors: [.red, .orange, .yellow, .blue, .green]), startPoint: .leading, endPoint: .trailing))
                    .frame(height: 6)
                
                // slider to show data
                Slider(value: .constant(value), in: 0...maxValue)
                    .accentColor(.clear)  // 隐藏默认滑块颜色
                    .background(Color.clear)
            }
        }
        .padding()
    }
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
    var searchAction: () -> Void

    var body: some View {
        HStack {
            TextField("Enter City name. eg: Sydney", text: $searchText)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)

            Button(action: searchAction) {
                Image(systemName: "magnifyingglass")
                    .padding()
                    .background(Color.blue)
                    .clipShape(Circle())
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal)
    }
}


// Preview provider
struct WeatherView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherView()
    }
}


