import Foundation
import CoreLocation
import Combine

class WeatherManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var weather: WeatherData?
    @Published var locationStatus: CLAuthorizationStatus?
    @Published var isLoading = false
    @Published var error: String?
    
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    private let apiKey = "ba3b00ab9fd280556f8096d95869ccaa" // <-- Test API key
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func requestWeather() {
        isLoading = true
        error = nil
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationStatus = status
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        } else if status == .denied || status == .restricted {
            error = "Location permission denied."
            isLoading = false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.error = error.localizedDescription
        isLoading = false
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            error = "Failed to get location."
            isLoading = false
            return
        }
        fetchWeather(for: location.coordinate)
    }
    
    private func fetchWeather(for coordinate: CLLocationCoordinate2D) {
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&appid=\(apiKey)&units=metric"
        guard let url = URL(string: urlString) else {
            error = "Invalid weather URL."
            isLoading = false
            return
        }
        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: WeatherData.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let err) = completion {
                    self?.error = err.localizedDescription
                }
                self?.isLoading = false
            }, receiveValue: { [weak self] weather in
                self?.weather = weather
            })
            .store(in: &cancellables)
    }
}

struct WeatherData: Codable {
    let main: Main
    let weather: [Weather]
    let name: String
    
    struct Main: Codable {
        let temp: Double
    }
    struct Weather: Codable {
        let main: String
        let description: String
        let icon: String
    }
    
    var temperatureString: String {
        "\(Int(main.temp.rounded()))°"
    }
    var condition: String {
        weather.first?.main ?? ""
    }
    var descriptionText: String {
        weather.first?.description.capitalized ?? ""
    }
    var iconName: String {
        weather.first?.icon ?? ""
    }
} 