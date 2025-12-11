//
//  CoffeeShop.swift
//  QuickBrew
//
//

import Foundation // imports core swift library
import CoreLocation // lets us convert addresses to coordinates

struct CoffeeShop {
    let name: String
    let coordinate: CLLocationCoordinate2D // lat and longi of specified shop
    
    var detourMinutes: Int? // total extra mins vs direct
    
    var arrivalTimeAtDestination: Date? // what time youd reach work after coffee shop
    var isOnTime: Bool?     // true = arrivaltimedestination <= arrivalDeadline
}
