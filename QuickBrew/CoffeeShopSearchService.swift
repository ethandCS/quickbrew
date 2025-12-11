//
//  CoffeeShopSearchService.swift
//  QuickBrew
//
//

import Foundation // imports core swift library
import MapKit // to calculate routes + travel times


// class is standalone hlper resposible ONLY for searching coffee shops
class CoffeeShopSearchService {
    // func accepts coords
    func searchCoffeeShops(near coordinate: CLLocationCoordinate2D,
                           maxResults: Int, // how many shops returned
                           completion: @escaping ([CoffeeShop]) -> Void) { // what func is returning if not void
        // when search is done for apple nmaps i will call you with an array of coffeeshop objects^^^^
        
        
        // using apple maps to search "coffee"
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "coffee"
        
        //region uses a rectangular region to query centered around an inputed coord
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 2000,
            longitudinalMeters: 2000
        )
        // assign region of coffee search to our rectangle we made with user as center
        request.region = region
        
        // now we start the search
        let search = MKLocalSearch(request: request)
        search.start { response, error in // the code below runs after apple maps responds
            
            
            // if no internet or api issue and return empty shop list
            if let error = error {
                print("coffee search error:", error.localizedDescription)
                completion([])
                return
            }
            
            // if nothing returned then return empty list and do not crash
            guard let items = response?.mapItems else {
                completion([])
                return
            }
            
            // take first ten results and check it has a name, convert to our struct and return array of clean app friendly objexts
            
            // compact maps returns non nil results
            let shops = items.prefix(maxResults).compactMap { item -> CoffeeShop? in
                guard let name = item.name else { return nil }
                return CoffeeShop(
                    name: name,
                    coordinate: item.placemark.coordinate
                )
            }
            // return array above ^
            completion(shops)
        }
    }
}
