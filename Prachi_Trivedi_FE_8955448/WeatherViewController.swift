//
//  WeatherViewController.swift
//  Prachi_Trivedi_FE_8955448
//
//  Created by user236101 on 4/12/24.
//

import UIKit
import MapKit
import CoreLocation

class WeatherViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var lblCity: UILabel!
    @IBOutlet weak var lblLocation: UILabel!
    @IBOutlet weak var lblWeather: UILabel!
    @IBOutlet weak var lblTemp: UILabel!
    @IBOutlet weak var imgIcon: UIImageView!
    @IBOutlet weak var lblHumidity: UILabel!
    @IBOutlet weak var lblWind: UILabel!
    
    var currentCity: String?

    let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
                
        let plusButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(btnPlus(_:)))
        plusButton.tintColor = .black // Set tint color to black
        self.navigationItem.rightBarButtonItem = plusButton
        
        let homeImage = UIImage(systemName: "house.fill") // Use a home icon
        let homeButton = UIBarButtonItem(image: homeImage, style: .plain, target: self, action: #selector(btnHome(_:)))
        homeButton.tintColor = .black // Set tint color to black
        self.navigationItem.leftBarButtonItem = homeButton
    }

    @IBAction func btnHome(_ sender: Any) {
        navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func btnPlus(_ sender: Any) {
        let alertController = UIAlertController(title: "Change City", message: "Enter the name of the city", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "City Name"
        }
        let submitAction = UIAlertAction(title: "Go", style: .default) { [unowned alertController, weak self] _ in
            guard let cityName = alertController.textFields?.first?.text, !cityName.isEmpty else {
                print("No city name entered")
                return
            }
            self?.fetchWeather(city: cityName)
        }
        alertController.addAction(submitAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        DispatchQueue.main.async {
            self.present(alertController, animated: true)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            fetchWeather(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            locationManager.stopUpdatingLocation()  // Optionally stop location updates if not needed further
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }

    func fetchWeather(latitude: Double? = nil, longitude: Double? = nil, city: String? = nil) {
        var urlString = ""
        if let city = city {
            urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(city)&appid=04154027bebd9233d8c3f15a13c6abce"
        } else if let latitude = latitude, let longitude = longitude {
            urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=04154027bebd9233d8c3f15a13c6abce"
        } else {
            print("Invalid request parameters")
            return
        }
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching data: \(error?.localizedDescription ?? "No error details available")")
                return
            }
            self?.decodeWeatherData(data)
        }.resume()
    }

    func decodeWeatherData(_ data: Data) {
        do {
            let weatherData = try JSONDecoder().decode(Weather.self, from: data)
            DispatchQueue.main.async {
                self.updateUI(with: weatherData)
            }
        } catch {
            print("Error decoding data: \(error)")
        }
    }

    func updateUI(with weather: Weather) {
        lblCity.text = weather.name
        lblLocation.text=weather.name
        lblTemp.text = String(format: "%.1f°C", weather.main.temp - 273.15)
        lblHumidity.text = "Humidity: \(weather.main.humidity)%"
        lblWind.text = "Wind: \(String(format: "%.1f km/h", weather.wind.speed * 3.6))"
        lblWeather.text = weather.weather.first?.description.capitalized ?? "Description not available"

        if let iconCode = weather.weather.first?.icon {
            let iconURLString = "https://openweathermap.org/img/w/\(iconCode).png"
            guard let iconURL = URL(string: iconURLString) else {
                print("Invalid icon URL")
                return
            }
            URLSession.shared.dataTask(with: iconURL) { data, _, error in
                guard let data = data, error == nil, let image = UIImage(data: data) else {
                    print("Error fetching image: \(error?.localizedDescription ?? "No error information")")
                    return
                }
                DispatchQueue.main.async {
                    self.imgIcon.image = image
                }
            }.resume()
        }
    }
}
