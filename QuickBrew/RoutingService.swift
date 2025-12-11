//
//  RoutingService.swift
//  QuickBrew
//
//

import Foundation // imports core swift library
import CoreLocation // lets us convert addresses to coordinates
import MapKit // to calculate routes + travel times

class RoutingService {
    // calculates ETA from user's Location -> destination
    func calculateRoute(from start: CLLocationCoordinate2D,
                        to end: CLLocationCoordinate2D,
                        completion: @escaping (Int?) -> Void) {// what func is returning if not void
        
        // creat mapkit placemarks for start and end --  placemark def. is at begin of geocode func in viewcontroller
        // wrapping the placemarks into map items so we can pass to apple maps needed for routing
        
        let startPlacemark = MKPlacemark(coordinate: start)
        let endPlacemark = MKPlacemark(coordinate: end) // coordinate is defined above(viewcontroller) and is input coords
        
        // build the route request
        let request = MKDirections.Request() // is object apple maps uses to figure out where we want to go
        request.source = MKMapItem(placemark: startPlacemark) // where starting
        request.destination = MKMapItem(placemark: endPlacemark) // where going
        request.transportType = .automobile // driving route we are assuming, how we getting there
        
        // calculating the route
        let directions = MKDirections(request: request)
        directions.calculate{ response, error in
            if let error = error {
                print("route error:", error.localizedDescription)
                completion(nil) // conpletions returns val to calling func and in this case nil but whatever passed
                return
            }
            
            // checking and getting the first route returned
            guard let route = response?.routes.first else {
                print("no route found")
                completion(nil)
                return
            }
            
            // travel time is in seconds, we will convert and round up
            let minutes = Int(ceil(route.expectedTravelTime / 60))
            completion(minutes)
        }
    }
}
