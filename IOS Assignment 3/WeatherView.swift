//
//  WeatherView.swift
//  IOS Assignment 3
//
//
//

import SwiftUI
import Foundation

struct WeatherView: View {
    //Call viewModel to access weather service
    @ObservedObject var viewModel: WeatherViewModel = WeatherViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    SearchBarView(//Search bar for searching city, MAP button, and favorite buttton
                        searchText: $viewModel.city,
                        searchAction: {
                            viewModel.fetchLocation(for: viewModel.city)
                        },
                        toggleFavorite: toggleFavorite,
                        isFavorite: viewModel.isFavorite
                    )
                    .padding(.top, 20)


                    if let weather = viewModel.weatherResponse {//Show weather
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("\(String(format: "%.0f", weather.current.temp))°")//Temperature
                                    .font(.system(size: 60))
                                    .fontWeight(.bold)
                                Spacer()
                                //Weather Icon, could.fill as defult.
                                Image(systemName: weatherIconMapping[weather.current.weather.first?.icon ?? "cloud"] ?? "cloud.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 60)
                            }
                            .padding()

                            DetailBox(weather: weather)//Detail weather box
                            ScrollView(.horizontal, showsIndicators: false) {//A H-Scroll bar to show the hourly weather. 
                                HStack {
                                    ForEach(weather.hourly, id: \.dt) { hour in
                                        HourlyWeatherCard(hour: hour, timezoneOffset: weather.timezone_offset)
                                    }
                                }
                                .padding()
                            }

                            //User colourful bar to show  
                            EnvironmentalFactorsBox(weather: weather)
                        }
                        .padding()
                    } else {
                        Spacer()
                        Text("Loading weather data...")//Loadding text before the weather info display.
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    
                }
                
            }
            .navigationBarTitle("Weather", displayMode: .inline)
            .toolbar {//A button navigate to Favorite List.
                            ToolbarItem(placement: .navigationBarTrailing) {
                                NavigationLink(destination: FavoriteListView(weatherViewModel: viewModel)) {
                                    Text("Favorite List")
                    }
                }
            }
        }
    }

    private func toggleFavorite() {
            print("Toggle favorite called from WeatherView.")
            viewModel.isFavorite.toggle()//Switch favorite otr not
            print("Favorite status after toggle: \(viewModel.isFavorite)")
            
            if viewModel.isFavorite {//If is favorite, print the location message
                guard let location = viewModel.lastLocation else {
                    print("No location available to save.")//Error message if not saved.
                    return
                }
                //print the city that just saved
                print("Saving favorite for city: \(viewModel.city) at (\(location.lat), \(location.lon))")
                saveFavorite(city: viewModel.city, latitude: location.lat, longitude: location.lon)//Save it to localStorage
            } else {
                print("Removing favorite for city: \(viewModel.city)")
                removeFavorite(city: viewModel.city)// Remoce it from localStorage
            }
        }


        private func saveFavorite(city: String, latitude: Double, longitude: Double) {
            //Get the favortieList from UserDefult, if dont have, make new one
            var favorites = UserDefaults.standard.array(forKey: "favoriteList") as? [[String: Any]] ?? []
            //Create a new favorite object
            let newFavorite = ["city": city, "latitude": latitude, "longitude": longitude] as [String : Any]
            //Add it to array
            favorites.append(newFavorite)
            //Save the updated list to UserDefult
            UserDefaults.standard.set(favorites, forKey: "favoriteList")
        }

        private func removeFavorite(city: String) {
             //Get the favortieList from UserDefult, if dont have, make new one
            var favorites = UserDefaults.standard.array(forKey: "favoriteList") as? [[String: Any]] ?? []
            //Rremove the maching city
            favorites.removeAll(where: { $0["city"] as? String == city })
            //Save the updated list to UserDefult
            UserDefaults.standard.set(favorites, forKey: "favoriteList")
        }
    }




struct DetailBox: View {
    var weather: WeatherResponse// Weather data passed to the view

    var body: some View {
        GroupBox(label: Text("Weather Details").bold()) {
            VStack(alignment: .leading) {
                // Displays weather description, feels-like temperature, sunrise, and sunset times
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
                // Displays environmental factors such as humidity and UV index using sliders.
                SliderView(value: Double(weather.current.humidity), maxValue: 100, label: "Humidity")
                SliderView(value: weather.current.uvi, maxValue: 10, label: "UV Index")
            }
        }
    }
}

// Converts a time interval to a string based on the timezone offset
func convertTime(timeInterval: TimeInterval, timezoneOffset: Int) -> String {
    let date = Date(timeIntervalSince1970: timeInterval)
    let dateFormatter = DateFormatter()
    dateFormatter.timeZone = TimeZone(secondsFromGMT: timezoneOffset + 36000) // Sydney GMT+10
    dateFormatter.dateFormat = "h:mm a"
    return dateFormatter.string(from: date)
}

// A custom view that represents a value with a slider
struct SliderView: View {
    var value: Double
    var maxValue: Double
    var label: String

    var body: some View {
        VStack(alignment: .leading) {
            Text("\(label): \(String(format: "%.0f", value))")
            
            ZStack(alignment: .leading) {
                // Colorful bar behind the slider
                RoundedRectangle(cornerRadius: 5)
                    .fill(LinearGradient(gradient: Gradient(colors: [.red, .orange, .yellow, .blue, .green]), startPoint: .leading, endPoint: .trailing))
                    .frame(height: 6)
                
                // slider to show data
                Slider(value: .constant(value), in: 0...maxValue)
                    .accentColor(.clear)  // Hides the slider's default visual components
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
            Text(convertTime(timeInterval: hour.dt, timezoneOffset: timezoneOffset))// Displays the time
                .font(.caption)
            Image(systemName: weatherIconMapping[hour.weather.first?.icon ?? "cloud"] ?? "cloud.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
            Text("\(String(format: "%.1f°C", hour.temp))")// Displays the temperature
            Text("Pop: \(Int(hour.pop * 100))%")// Displays the probability of precipitation
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.5)))
        .shadow(radius: 3)
    }
}



struct SearchBarView: View {
    @Binding var searchText: String// The text in the search bar
    @State private var isMapNavigationActive = false // State to manage map view navigation
    @State private var isValidCity = true //State for checking the input is valid
    var searchAction: () -> Void // Action to search
    var toggleFavorite: () -> Void // Action to toggle favorite
    var isFavorite: Bool //Indicates the current location is a favorite or not

    var body: some View {
        NavigationStack {
            HStack {
                TextField("Enter city name", text: $searchText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .onChange(of: searchText, perform: { value in
                        // Check text when it change
                        self.isValidCity = self.checkCityName(value)
                    })


                Button(action: {
                    // Only search when the text is valid
                    if isValidCity {
                        searchAction()
                    }
                }) {
                    Image(systemName: "magnifyingglass")
                        .padding()
                        .background(Color.blue)
                        .clipShape(Circle())
                        .foregroundColor(.white)
                }



                Button(action: {//MAP button
                    self.isMapNavigationActive = true
                }) {
                    Image(systemName: "map.fill")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                
                Button(action: {//Star button folr favorite
                                    print("Favorite button tapped.")
                                    toggleFavorite()
                                }) {
                                    Image(systemName: isFavorite ? "star.fill" : "star")
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(isFavorite ? .yellow : .gray)
                                }
            }
            .navigationDestination(isPresented: $isMapNavigationActive) {
                MapView()// Navigation destination when the map button is tapped
            }
            .padding(.horizontal)
            
        }
    }

    //Check whether the city name starts with a capital letter 
    //And contains only English letters and spaces.
    private func checkCityName(_ name: String) -> Bool {
        let regex = "^[A-Z][a-zA-Z\\s]*$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: name)
    }

    
}

// Preview provider
struct WeatherView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherView()
    }
}


//Priviour weatherService now move to weatherViewModel
//class WeatherService {
//    let apiKey = "645b6c195d49ee0b1f364003c7887e44"
//
//
//    // Get the city position info by using geo API
//    func fetchLocation(for city: String, completion: @escaping (Result<(Double, Double), Error>) -> Void) {
//        let formattedCity = city.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
//        let urlString = "http://api.openweathermap.org/geo/1.0/direct?q=\(formattedCity)&limit=1&appid=\(apiKey)"
//        
//        guard let url = URL(string: urlString) else {
//            completion(.failure(URLError(.badURL)))
//            return
//        }
//
//        URLSession.shared.dataTask(with: url) { data, response, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//
//            guard let data = data else {
//                completion(.failure(URLError(.cannotParseResponse)))
//                return
//            }
//
//            do {
//                let locations = try JSONDecoder().decode([Location].self, from: data)
//                guard let location = locations.first else {
//                    completion(.failure(URLError(.dataNotAllowed)))
//                    return
//                }
//                completion(.success((location.lat, location.lon)))
//            } catch {
//                completion(.failure(error))
//            }
//        }.resume()
//    }
//
//    // Get weather info from OpenWeatherMap
//    func fetchWeather(latitude: Double, longitude: Double, completion: @escaping (Result<WeatherResponse, Error>) -> Void) {
//        let urlString = "https://api.openweathermap.org/data/3.0/onecall?lat=\(latitude)&lon=\(longitude)&exclude=minutely,daily,alerts&appid=\(apiKey)&units=metric"
//        
//        guard let url = URL(string: urlString) else {
//            completion(.failure(URLError(.badURL)))
//            return
//        }
//
//        URLSession.shared.dataTask(with: url) { data, response, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//
//            guard let data = data else {
//                completion(.failure(URLError(.cannotDecodeContentData)))
//                return
//            }
//
//            do {
//                let weatherResponse = try JSONDecoder().decode(WeatherResponse.self, from: data)
//                completion(.success(weatherResponse))
//            } catch {
//                completion(.failure(error))
//            }
//        }.resume()
//    }
//}