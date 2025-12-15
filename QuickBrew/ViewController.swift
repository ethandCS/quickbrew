//
//  ViewController.swift
//  QuickBrew
//
//  High-level purpose:
//  This screen collects all initial user inputs needed to plan a trip.
//  -- User selects a leaving time, arrival deadline, and destination address.
//  -- The app fetches the user's current GPS location.
//  -- We validate the inputs and calculate total available travel time.
//  -- The address is converted into coordinates (geocoding).
//  -- We delegate routing and coffee-shop searching to service classes.
//  -- When all data is ready, it will be passed to the next screen
//    for route     comparison and coffee-stop decision making.
//

//

import UIKit // gives access to all ios ui components
import CoreLocation // lets us convert addresses to coordinates
import MapKit // to calculate routes + travel times

// main screen for user input( in our case times and destination)


// delegagte used to receive events from an associated location manager object
// view controller managers hierarchy
// adopt CLLocationManagerDelagate so this screen can receive gps updates

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    
    // ui elements connected from storyboard,reference to elements, weak since "deep"
    // mem not needed or also called
    // ===============
    // IBOutlets
    // ===============
    
    @IBOutlet weak var leavingTimePicker: UIDatePicker! // users chosen depart time reference
    @IBOutlet weak var arrivalTimePicker: UIDatePicker! // user arrival time deeadline
    @IBOutlet weak var addressTextField: UITextField! // text field where user types their  work address/destination
    
    //handles asking user location updates
    let locationManager = CLLocationManager()
    //stores last known user coord (for later use)
    var userCoordinate: CLLocationCoordinate2D?
    //  delagating routing + coffee search to helper service files
    let routingService = RoutingService()
    let coffeeService = CoffeeShopSearchService()
    
    
    // stored values so we can passs into next screen
    var lastMinutesAvailable: Int?
    var lastDirectTravelMinutes: Int?
    var lastArrivalDeadline: Date?
    var lastDestinationCoordinate: CLLocationCoordinate2D?
    var lastCoffeeShops: [CoffeeShop] = []
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // runs when screen first loads
        // Do any additional setup after loading the view.
        
        // basic location setup
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization() // ask user for permission while app in use
        locationManager.requestLocation() //request a single location update
    }

    
    // called when user clicks button(get directions press)
        @IBAction func getDirectionsTapped(_ sender: UIButton) {
            // get selected times above
            let leavingTime = leavingTimePicker.date
            let arrivalTime = arrivalTimePicker.date
            // get address from text, if empty return empty string
            let destinationAddress = addressTextField.text ?? ""
            
            // making sure user typed by removing white spaces at ends and seeing ?empty
            if destinationAddress.trimmingCharacters(in: .whitespaces).isEmpty {
                print("error: no address entered")
                return // stop function
            }
            
            // then make sure arrival time is after or greater than leaving
            if arrivalTime <= leavingTime {
                print("error: arrival time must be after leaving time")
                return
            }
            
            //calculate time user has for the whole commute + possible coffee stop
            let timeInterval = arrivalTime.timeIntervalSince(leavingTime) // in secs
            // timeIntervalSince func gets seconds between arrival and passed in leaving
            let minutesAvailable = Int(ceil(timeInterval / 60)) // turned min and round up do to int div
            print("total minutes available:", minutesAvailable)
            
            // storing vals for next screen
            self.lastMinutesAvailable = minutesAvailable
            self.lastArrivalDeadline = arrivalTime
            
            // now working on address part, need to convert address to coordinates to be able to use
            // create a geocoder obj to convert address into coords
            let geocoder = CLGeocoder()
            
            // run geocoding on typed address
            // funcion below submits foward geocoding request with string passed
            // placemark is user friendly description of geograohic coord ie address place and relevant descript
            geocoder.geocodeAddressString(destinationAddress) { placemarks, error in // either return array of locations data (placemarks) or err
                
                // handle errors(bad address, no internet etc
                if let error = error {
                    print("geocoding fail:", error.localizedDescription)
                    return
                }
                
                // making sure we at least have one result for address
                guard let placemark = placemarks?.first,
                      let location = placemark.location else {
                    print ("no location found for address")
                    return
                }
                
                // extract coords ( lat and long) from location which was the first placemark found
                let destinationCoord = location.coordinate
                print("destination coordinates:", destinationCoord.latitude, destinationCoord.longitude)
                
                self.lastDestinationCoordinate = destinationCoord
                // later we will pass coords to routing + coffeee logic  \/ \/ \/
                
                // make sure we have user gps coord
                guard let userCoord = self.userCoordinate else {
                    print("error user location not avail yet")
                    return
                }
                
                // =======================
                // CALL ROUTING SERVICE
                // =======================
                self.routingService.calculateRoute(from: userCoord, to: destinationCoord) {travelMinutes in
                    
                    // if nil returned -> fail silentley
                    guard let travelMinutes = travelMinutes else {
                        print("route failed silently")
                        return
                    }
                
                    print("travel time destination:", travelMinutes, "minutes")
                    self.lastDirectTravelMinutes = travelMinutes
                    
                        
                    // ==========================
                    // CALL COFFEE SEARCH SERVICE
                    // ==========================
                    let numberOfShopsWanted = 5 // will change to adjustable/or hardcoded
                
                    self.coffeeService.searchCoffeeShops(
                        near: userCoord,
                        maxResults: numberOfShopsWanted
                    ) { shops in
                        
                        self.lastCoffeeShops = shops
                        print("=== Nearby Coffee Shops ===")
                        
                        for shop in shops {
                            print("- \(shop.name) @ \(shop.coordinate)")
                    }
                    // this calls helper to calc eta assuming selected coffee shops (user->shop->+coffeewait(hardcoded as now)-->dest)
                        
                    self.calculateDetourTimes(
                        user: userCoord,
                        destination: destinationCoord,
                        shops: shops
                    ) { updatedShops in
                        
                        self.lastCoffeeShops = updatedShops
                        
                        // ============
                        // ALL DATA READY → MOVE TO SCREEN 2
                        // ============
                        self.performSegue(withIdentifier: "toOptions", sender: self)
                    }
                }
            }
        }
    }
    
    // gps success!
    // called when gps works and grabs first location stores coords and prints for debug
    
    // this func auto called by ios , we are not calling, ios calls because of earlier line locationManager.delegate = self
    // locations is array of gps readings from ios, we use first and unrap and save then print
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            userCoordinate = location.coordinate
            print("user location:", userCoordinate!) // debug print
        }
    }
    
    // gps fail, this occurs if user denied location, airplane mode/no gps, simulator glitch, ios timeout, location disabled in settings
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("location error:", error.localizedDescription)
    }
    
    // this func runs auto BEFORE we switch screens
    // This is where we pass all computed data into options view controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // make sure this is the segue we want(connection between screens)
        if segue.identifier == "toOptions" {
            
            // try converting destination VC intro out OptionsViewControll type
            if let optionsVC = segue.destination as? OptionsViewController {
                
                // now pass total minutes acail
                optionsVC.minutesAvailable = lastMinutesAvailable
                
                // pass direct travel time (no coffee)
                optionsVC.directTravelMinutes = lastDirectTravelMinutes
                
                // pass arrival deadline time user selected
                optionsVC.arrivalDeadline = lastArrivalDeadline
                
                //coords to launch Apple Maps Later
                optionsVC.userCoordinate = userCoordinate
                optionsVC.destinationCoordinate = lastDestinationCoordinate
                
                // pass coffee shop list
                optionsVC.coffeeShops = lastCoffeeShops
            }
        }
    }
    
    func calculateDetourTimes(
        user: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        shops: [CoffeeShop],
        completion: @escaping ([CoffeeShop]) -> Void
    ) {
        var updated = shops
        let dispatchGroup = DispatchGroup() // dispatch group is tasks monitored as single unit then deployed as once to make sure all succeed or if not then don't deploy
        for i in 0..<shops.count {
            dispatchGroup.enter()
            
            let shop = shops[i]
            
            // Route A : user -> shop
            routingService.calculateRoute(from: user, to: shop.coordinate) { leg1 in
                
                guard let leg1 = leg1 else {
                    dispatchGroup.leave()
                    return
                }
                
                // route b shop -> dest
                self.routingService.calculateRoute(from: shop.coordinate, to: destination) { leg2 in
                    
                    guard let leg2 = leg2 else {
                        dispatchGroup.leave()
                        return
                    }
                    
                    let total = leg1 + leg2 + 10 // include 10 min for the actual stopping for coffee
                    updated[i].detourMinutes = total
                    
                    // compute arrival time AFTER this coffee shop setting eta including specific shop
                    let arrival = self.leavingTimePicker.date.addingTimeInterval(TimeInterval(total) * 60)
                    updated[i].arrivalTimeAtDestination = arrival
                    
                    // compare against the user deadline && setting BOOL
                    if let deadline = self.lastArrivalDeadline {
                        updated[i].isOnTime = (arrival <= deadline)
                    } else {
                        updated[i].isOnTime = nil
                    }
                    
                    
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(updated)
        }
    }
}
