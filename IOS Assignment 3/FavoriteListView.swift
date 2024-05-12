//
//  FavoriteListView.swift
//  IOS Assignment 3
//

import SwiftUI

struct FavoriteListView: View {
    @ObservedObject var weatherViewModel = WeatherViewModel()
    @State private var favorites: [Favorite] = []//Array for favorite city
    @State private var hasLoadedWeather = false//The state for loading Weather

    var body: some View {
        NavigationView {
            ZStack(alignment: .trailing) {
                List {//List of cities

                    //Link to weatherView to show the favorite weather                
                    ForEach(favorites, id: \.city) { favorite in
                        NavigationLink(destination: WeatherView(viewModel: weatherViewModel).onAppear {
                            weatherViewModel.fetchWeather(latitude: favorite.latitude, longitude: favorite.longitude)
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(favorite.city)//city name
                                        .font(.headline)
                                    Text("\(String(format: "%.0f", weatherViewModel.weatherData["\(favorite.latitude),\(favorite.longitude)"]?.current.temp ?? 0))°C")
                                        .font(.subheadline)//temp
                                }
                                Spacer()
                                //Wearther icon
                                if let icon = weatherViewModel.weatherData["\(favorite.latitude),\(favorite.longitude)"]?.current.weather.first?.icon {
                                    Image(systemName: weatherIconMapping[icon] ?? "cloud")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteFavorites)//Make the list item to be deleteable
                }
                .navigationTitle("Favorite Cities Weather")
            }
        }
        .onAppear {//Load the weather when jump to this page
            if !hasLoadedWeather {
                loadFavorites()
                hasLoadedWeather = true
            }
        }
    }



    private func loadFavorites() {
        // Get favoriteList from UserDefaults 
        if let savedFavorites = UserDefaults.standard.array(forKey: "favoriteList") as? [[String: Any]] {
            self.favorites = savedFavorites.map { dict in
                Favorite(
                    city: dict["city"] as? String ?? "",
                    latitude: dict["latitude"] as? Double ?? 0,
                    longitude: dict["longitude"] as? Double ?? 0
                )
            }
            // Update weather
            for favorite in favorites {
                weatherViewModel.fetchWeather(latitude: favorite.latitude, longitude: favorite.longitude)
            }
        }
    }

    private func deleteFavorites(at offsets: IndexSet) {
        favorites.remove(atOffsets: offsets)//Remove the favorite from the list
        // UPdate UserDefaults
        let array = favorites.map { ["city": $0.city, "latitude": $0.latitude, "longitude": $0.longitude] }
        UserDefaults.standard.set(array, forKey: "favoriteList")
    }
}

struct Favorite: Identifiable {
    let id = UUID()
    var city: String
    var latitude: Double
    var longitude: Double
}

// Preview for SwiftUI view
struct FavoriteListView_Previews: PreviewProvider {
    static var previews: some View {
        FavoriteListView()
    }
}
