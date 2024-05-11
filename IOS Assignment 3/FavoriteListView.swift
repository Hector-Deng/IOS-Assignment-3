//
//  FavoriteListView.swift
//  IOS Assignment 3
//

import SwiftUI

struct FavoriteListView: View {
    @ObservedObject var weatherViewModel = WeatherViewModel()
    @State private var favorites: [Favorite] = []
    @State private var hasLoadedWeather = false

    var body: some View {
        NavigationView {
            ZStack(alignment: .trailing) {
                List {
                    ForEach(favorites, id: \.city) { favorite in
                        NavigationLink(destination: WeatherView(viewModel: weatherViewModel).onAppear {
                            weatherViewModel.fetchWeather(latitude: favorite.latitude, longitude: favorite.longitude)
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(favorite.city)
                                        .font(.headline)
                                    Text("\(String(format: "%.0f", weatherViewModel.weatherData["\(favorite.latitude),\(favorite.longitude)"]?.current.temp ?? 0))°C")
                                        .font(.subheadline)
                                }
                                Spacer()
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
                    .onDelete(perform: deleteFavorites)
                }
                .navigationTitle("Favorite Cities Weather")
            }
        }
        .onAppear {
            if !hasLoadedWeather {
                loadFavorites()
                hasLoadedWeather = true
            }
        }
    }



    private func loadFavorites() {
        // 从 UserDefaults 或其他来源加载收藏列表
        if let savedFavorites = UserDefaults.standard.array(forKey: "favoriteList") as? [[String: Any]] {
            self.favorites = savedFavorites.map { dict in
                Favorite(
                    city: dict["city"] as? String ?? "",
                    latitude: dict["latitude"] as? Double ?? 0,
                    longitude: dict["longitude"] as? Double ?? 0
                )
            }
            // 可选：更新天气数据
            for favorite in favorites {
                weatherViewModel.fetchWeather(latitude: favorite.latitude, longitude: favorite.longitude)
            }
        }
    }

    private func deleteFavorites(at offsets: IndexSet) {
        favorites.remove(atOffsets: offsets)
        // 更新 UserDefaults
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
