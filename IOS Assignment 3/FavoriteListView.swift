//
//  FavoriteListView.swift
//  IOS Assignment 3
//
//  Created by 密码：0000 on 2024/5/10.
//

import SwiftUI

struct FavoriteListView: View {
    @ObservedObject var weatherViewModel = WeatherViewModel()
    @State private var favorites: [Favorite] = []
    @State private var hasLoadedWeather = false

    var body: some View {
        NavigationView {
            List {
                ForEach(favorites, id: \.city) { favorite in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(favorite.city)
                                .font(.headline)
                            let key = "\(favorite.latitude),\(favorite.longitude)"
                            if let weather = weatherViewModel.weatherData[key] {
                                Text("\(String(format: "%.0f", weather.current.temp))°C")
                                    .font(.subheadline)
                            } else {
                                ProgressView()
                            }
                        }
                        Spacer()
                        let icon = weatherIconMapping[weatherViewModel.weatherData["\(favorite.latitude),\(favorite.longitude)"]?.current.weather.first?.icon ?? "cloud"] ?? "cloud.fill"
                        Image(systemName: icon)
                            .foregroundColor(.blue)
                            .imageScale(.large)
                    }
                }
                .onDelete(perform: deleteFavorites)
            }
            .navigationTitle("Favorite Cities Weather")
        }
        .onAppear {
            if !hasLoadedWeather {
                loadFavorites()
                hasLoadedWeather = true
            }
        }
    }

    private func loadFavorites() {
        if let savedFavorites = UserDefaults.standard.array(forKey: "favoriteList") as? [[String: Any]] {
            self.favorites = savedFavorites.map { dict in
                Favorite(
                    city: dict["city"] as? String ?? "",
                    latitude: dict["latitude"] as? Double ?? 0,
                    longitude: dict["longitude"] as? Double ?? 0
                )
            }
            for favorite in favorites {
                weatherViewModel.fetchWeather(latitude: favorite.latitude, longitude: favorite.longitude)
            }
        }
    }

    private func deleteFavorites(at offsets: IndexSet) {
        favorites.remove(atOffsets: offsets)
        updateFavoritesInUserDefaults()
    }

    private func updateFavoritesInUserDefaults() {
        let array = favorites.map { ["city": $0.city, "latitude": $0.latitude, "longitude": $0.longitude] }
        UserDefaults.standard.set(array, forKey: "favoriteList")
    }
}





struct Favorite {
    var city: String
    var latitude: Double
    var longitude: Double
}




#Preview {
    FavoriteListView()
}
