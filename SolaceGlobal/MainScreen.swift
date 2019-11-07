//
//  ViewController.swift
//  SolaceGlobal
//
//  Created by Jack Sherwood on 02/11/2019.
//  Copyright © 2019 Jack Sherwood. All rights reserved.
//

import UIKit
import MapKit
import RealmSwift
import Realm


// Structures for ParsingJSON
struct Alerts: Decodable {
    let alerts: [Alert]
}
struct Alert: Decodable {
    let title: String
    let description: String
    let latitude: String
    let longitude: String
    let notes: String
}


//Class for realm objects
class RealmAlerts: Object {
    @objc dynamic var title = ""
    @objc dynamic var information = ""
    @objc dynamic var latitude = ""
    @objc dynamic var longitude = ""
    @objc dynamic var notes = ""
    
}

//URL for get request
let url = URL(string: "https://solacesecure.com/api/candidate/alerts?candidateId=8D0544F3-70E2-4263-93FD-3DCFBDBAB3F5&nDays=1")


class MainScreen: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var alertView: UIView!
    @IBOutlet weak var alertTitle: UILabel!
    @IBOutlet weak var alertInformation: UITextView!
    @IBOutlet weak var alertNotes: UITextView!
    
    
    let locationManager = CLLocationManager()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        
        
        
        print(Realm.Configuration.defaultConfiguration.fileURL)
        
    
        
        
        //This checks if there is an internet connection
        if ReachabilityTest.isConnectedToNetwork() {
            print("Internet connection available")
            setupLocationManager()
            DispatchQueue.global(qos: .userInteractive).async {
                self.getJSONDataFromNet()
            }
            
            
        }
        else{
            print("No internet connection available")
            DispatchQueue.global(qos: .userInteractive).async {
                self.populateFromLocalDB()
            }
            
        }

    
    }
    
    
    //If internet connection is available then parse the JSON data
    func getJSONDataFromNet(){
        URLSession.shared.dataTask(with: url!) {(data, response, error) in
            do {
                let alerts = try JSONDecoder().decode(Alerts.self, from: data!)
                let realm = try! Realm()
                
                
                //Removes all items in the database (Mainly to ensure all alerts are up to data)
                try! realm.write {
                    realm.deleteAll()
                }
                
                for alert in alerts.alerts {
                    let longitude = CLLocationDegrees(alert.longitude)
                    let latitude = CLLocationDegrees(alert.latitude)
                    let pin = AlertPin()
                    pin.title = alert.title
                    pin.notes = alert.notes
                    pin.coordinate = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
                    self.mapView.addAnnotation(pin)
                    
                    
                    let realmAlert = RealmAlerts()
                    realmAlert.title = alert.title
                    realmAlert.information = alert.description
                    realmAlert.latitude = alert.latitude
                    realmAlert.longitude = alert.longitude
                    realmAlert.notes = alert.notes
                    
                    try! realm.write {
                        realm.add(realmAlert)
                        
                    }
                    
                }
                
            }
            catch {
                print(error)
            }
            }.resume()
    }
    
    //Loads the location manager
    func setupLocationManager(){
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
    //If no net connection then this function will get the data from the realm database
    func populateFromLocalDB(){
        print("Database Populated")
        let realm = try! Realm()
        let realmAlerts = realm.objects(RealmAlerts.self)
        
        for alert in realmAlerts {
            let longitude = CLLocationDegrees(alert.longitude)
            let latitude = CLLocationDegrees(alert.latitude)
            let pin = AlertPin()
            pin.title = alert.title
            pin.notes = alert.notes
            pin.coordinate = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
            self.mapView.addAnnotation(pin)
        }
        
    
    }


}


extension MainScreen: CLLocationManagerDelegate, MKMapViewDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        if let location = locations.last {
            let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            self.mapView.setRegion(region, animated: true)
            self.mapView.showsUserLocation = true;
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation as? AlertPin {
            alertInformation.text = annotation.title!
            alertNotes.text = annotation.notes!
        }
    }
    
}
