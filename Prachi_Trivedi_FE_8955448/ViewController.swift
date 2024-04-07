//
//  ViewController.swift
//  Prachi_Trivedi_FE_8955448
//
//  Created by user236101 on 4/7/24.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate{

    @IBOutlet weak var imgBackground: UIImageView!
    
    @IBOutlet weak var lblTemp: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var lblWind: UILabel!
    @IBOutlet weak var lblHumidity: UILabel!
    
    @IBOutlet weak var imgWeatherIcon: UIImageView!
    
    let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Setup location manager
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // Set MapView properties
        mapView.showsUserLocation = true
    }
    // MARK: - Location Manager Delegate Methods
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let location = locations.last else { return }
            
            let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            
            mapView.setRegion(region, animated: true)
            makeAPICall()
        }
        
        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            print("Error requesting location: \(error.localizedDescription)")
        }
        func makeAPICall() {
        guard let currentLocation = locationManager.location else {
            print("Unable to get current location.")
            return
        }
        
        let latitude = currentLocation.coordinate.latitude
        let longitude = currentLocation.coordinate.longitude
        print(latitude)
        print(longitude)
        
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=04154027bebd9233d8c3f15a13c6abce"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let jsonData = try JSONDecoder().decode(Weather.self, from: data)
                    DispatchQueue.main.async {
                        self.updateUI(with: jsonData)
                        
                        //Fatching icon and setting it in imageview
                        if let iconCode = jsonData.weather.first?.icon {
                            let iconURLString = "https://openweathermap.org/img/w/\(iconCode).png"
                            if let iconURL = URL(string: iconURLString){
                                print(iconURL)
                                URLSession.shared.dataTask(with: iconURL){ data, response, error in
                                    if let error = error{
                                        print("Error fetching image data: \(error)")
                                        return
                                    }
                                    guard let data = data else {
                                        print("No image data received")
                                        return
                                    }
                                    DispatchQueue.main.async {
                                        if let image = UIImage(data: data) {
                                            self.imgWeatherIcon.image = image
                                        } else {
                                            print("Error: Couldn't create image from data")
                                        }
                                    }
                                }.resume()
                            } else {
                                print("Error: Invalid icon URL")
                            }
                        } else {
                            print("Error: Icon code not found")
                        }

                    }
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            } else {
                print("Error fetching data: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
        task.resume()
    }
    // MARK: - Update UI
        
    func updateUI(with weather: Weather) {
        // Make sure to access temperature as a formatted string if needed
        //let tempFormatted = String(format: "%.1f °C", weather.main.temp - 273.15) // Convert Kelvin to Celsius
        //lblTemp.text = tempFormatted
        // Convert Kelvin to Celsius and prepare the label with superscript 'C'
            let temperature = weather.main.temp - 273.15
            let tempFormatted = String(format: "%.1f", temperature)
            let tempString = NSMutableAttributedString(string: tempFormatted + " °C")
            
            // Attributes for superscript style
            let superscriptFont = UIFont.systemFont(ofSize: lblTemp.font.pointSize * 0.6) // Smaller font size for superscript
            let superscriptAttributes: [NSAttributedString.Key: Any] = [
                .font: superscriptFont,
                .baselineOffset: lblTemp.font.pointSize * 0.3 // Adjust baseline to make superscript
            ]
            
            // Apply superscript to the "C" in "°C"
            tempString.addAttributes(superscriptAttributes, range: NSRange(location: tempFormatted.count + 2, length: 1))
            
            // Set the attributed string to the label
            lblTemp.attributedText = tempString
        let windSpeedKmH = weather.wind.speed * 3.6
        lblWind.text = "Wind: \(String(format: "%.1f", windSpeedKmH)) km/h"
        lblHumidity.text = "Humidity: \(weather.main.humidity)%"
    }
}

