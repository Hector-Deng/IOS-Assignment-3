import SwiftUI
import MapKit

struct MapView: View {
    @StateObject private var weatherViewModel = WeatherViewModel()
    @State private var tappedCoordinate: CLLocationCoordinate2D?
    @State private var locationString: String = ""
    @State private var isLoadingLocation: Bool = false
    @State private var isWeatherDisplayed: Bool = true // State to control weather information visibility
    @State private var isFavorite: Bool = false // State to track if location is favorite
    @State private var isActive: Bool = false


    var body: some View {
        VStack {
            MapKitView(tappedCoordinate: $tappedCoordinate, locationString: $locationString, isLoadingLocation: $isLoadingLocation)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // To handle tap gesture on the map
                    isWeatherDisplayed=true
                    print("Tapped on the map")
                    if let coordinate = tappedCoordinate {
                        fetchLocationAndWeather(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    }
                }
                .frame(maxHeight: .infinity) // Ensure the map fills the available space
            
            if isWeatherDisplayed, let weatherResponse = weatherViewModel.weatherResponse {
                let roundedTemperature = String(format: "%.1f", weatherResponse.current.temp)
                HStack {
                    Image(systemName: "location.fill")
                    Text(locationString)
                }
                
                HStack {
                    Image(systemName: "thermometer")
                    Text("Temperature: \(roundedTemperature) °C")
                }
    
                HStack {
                    Image(systemName: "cloud.fill")
                    Text("Weather: \(weatherResponse.current.weather[0].description)")
                }
                
                // Dismiss button for the weather information
                HStack {
                    Button(action: {
                        // Dismiss the weather information
                        isWeatherDisplayed = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.title2)
                            .padding(.top, 4)
                    }
                    Button(action: {
                        if let coordinate = tappedCoordinate, !locationString.isEmpty {
                            isActive = true
                        }
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.title2)
                            .padding(.top, 4)
                    }
                    .sheet(isPresented: $isActive, onDismiss: {
                    }) {
                        WeatherView(viewModel: weatherViewModel)
                            .onAppear {
                                if let coordinate = tappedCoordinate {
                                    weatherViewModel.fetchWeather(latitude: coordinate.latitude, longitude: coordinate.longitude)
                                }
                            }
                    }
                }
            }
        }
    }
    
    private func fetchLocationAndWeather(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        isLoadingLocation = true
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            isLoadingLocation = false
            guard let placemark = placemarks?.first else {
                print("No placemark found")
                return
            }
            locationString = "\(placemark.locality ?? ""), \(placemark.country ?? "")"
            weatherViewModel.fetchWeather(latitude: latitude, longitude: longitude)
        }
    }
}

struct MapKitView: UIViewRepresentable {
    @Binding var tappedCoordinate: CLLocationCoordinate2D?
    @Binding var locationString: String
    @Binding var isLoadingLocation: Bool
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update the view if needed
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    class Coordinator: NSObject {
        var parent: MapKitView
        
        init(parent: MapKitView) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
            let mapView = gestureRecognizer.view as! MKMapView
            let tapPoint = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(tapPoint, toCoordinateFrom: mapView)
            parent.tappedCoordinate = coordinate
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
