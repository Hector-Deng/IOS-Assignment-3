import SwiftUI
import MapKit

// Define a custom struct for map annotations
struct MapAnnotationItem: Identifiable {
    var id = UUID()
    var coordinate: CLLocationCoordinate2D
    var cityName: String
    var countryName: String
}

struct MapView: View {
    // Define the initial map region as a static property
    private static let initialRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    @State private var region: MKCoordinateRegion
    @State private var selectedCoordinates: MapAnnotationItem?
    @State private var weatherData: WeatherResponse?
    @State private var cityName: String = "Unknown"
    @State private var countryName: String = "Unknown"

    let weatherService = WeatherService()
    let geocoder = CLGeocoder() // Geocoder instance for reverse geocoding

    init() {
        // Initialize the region to the initial map region
        self._region = State(initialValue: Self.initialRegion)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                Map(
                    coordinateRegion: $region,
                    interactionModes: [.all],
                    showsUserLocation: true,
                    annotationItems: selectedCoordinates != nil ? [selectedCoordinates!] : [],
                    annotationContent: { annotationItem in
                        MapMarker(coordinate: annotationItem.coordinate, tint: .red)
                    }
                )
                .gesture(
                    TapGesture()
                        .onEnded { _ in
                            let tappedLocation = region.center
                            reverseGeocode(coordinates: tappedLocation)
                            fetchWeather(for: tappedLocation)
                        }
                )

                if let weather = weatherData {
                    VStack {
                        Text("Location: \(cityName), \(countryName)")
                        Text("Temperature: \(String(format: "%.1f°C", weather.current.temp))")
                        Text("Description: \(weather.current.weather.first?.description ?? "N/A")")

                        // Optional button to dismiss the location pin
                      
                        .padding()
                    }
                }
            }

            // Add a small "X" button to dismiss the location pin
            if selectedCoordinates != nil {
                Button(action: {
                    // Dismiss the location pin and reset the map region
                    selectedCoordinates = nil
                    weatherData = nil
                    cityName = "Unknown"
                    countryName = "Unknown"
                    region = Self.initialRegion
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.red)
                        .padding()
                }
                .padding(.top, 10)
                .padding(.trailing, 10)
            }
        }
    }

    // Function to fetch weather data for a given coordinate
    private func fetchWeather(for coordinates: CLLocationCoordinate2D) {
        weatherService.fetchWeather(latitude: coordinates.latitude, longitude: coordinates.longitude) { result in
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    weatherData = response
                }
            case .failure(let error):
                print("Error fetching weather: \(error)")
            }
        }
    }

    // Function to perform reverse geocoding
    private func reverseGeocode(coordinates: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Error with reverse geocoding: \(error)")
                cityName = "Unknown"
                countryName = "Unknown"
            } else if let placemark = placemarks?.first {
                cityName = placemark.locality ?? "Unknown"
                countryName = placemark.country ?? "Unknown"
                
                selectedCoordinates = MapAnnotationItem(
                    coordinate: coordinates,
                    cityName: cityName,
                    countryName: countryName
                )
            }
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
