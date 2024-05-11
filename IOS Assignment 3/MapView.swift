import SwiftUI
import MapKit

struct MapView: View {
    @StateObject private var weatherViewModel = WeatherViewModel()
    @State private var tappedCoordinate: CLLocationCoordinate2D?
    @State private var locationString: String = ""
    @State private var isLoadingLocation: Bool = false
    
    var body: some View {
        VStack {
            MapKitView(tappedCoordinate: $tappedCoordinate, locationString: $locationString, isLoadingLocation: $isLoadingLocation)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // To handle tap gesture on the map
                    print("Tapped on the map")
                    if let coordinate = tappedCoordinate {
                        fetchLocationAndWeather(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    }
                }
            
            if !locationString.isEmpty {
                Text("Location: \(locationString)")
            }
            
            if let weatherResponse = weatherViewModel.weatherResponse {
                let roundedTemperature = String(format: "%.1f", weatherResponse.current.temp)
                Text("Current Temperature: \(roundedTemperature) °C")
                Text("Weather: \(weatherResponse.current.weather[0].description)")
            } else {
                Text("No weather information available")
                    .padding()
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
