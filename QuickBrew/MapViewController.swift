//
//  MapViewController.swift
//  QuickBrew
//
//  High-level purpose:
//  This screen displays a live, interactive map inside the app.
//  It shows:
//   - the user’s starting location
//   - the destination
//   - an optional coffee stop
//   - the driving route drawn directly on the map
//
//  This controller does NOT calculate ETAs.
//  It only VISUALIZES the route that was already chosen.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController, MKMapViewDelegate {

    // ================================
    // OUTLET
    // ================================
    
    // map view dragged from storyboard
    @IBOutlet weak var mapView: MKMapView!
    
    
    
    // ================================
    // DATA PASSED FROM OptionsViewController
    // ================================
    
    var userCoordinate: CLLocationCoordinate2D?
    var destinationCoordinate: CLLocationCoordinate2D?
    var selectedShop: CoffeeShop?   // nil = direct route, non-nil = coffee route

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // let MapViewController handle overlays (polylines)
        mapView.delegate = self
        
        // optional but helpful: show blue dot for user
        mapView.showsUserLocation = true
        
        // kick off route rendering
        showRouteOnMap()
    }
    
    // ================================
    // CORE LOGIC: SHOW ROUTE
    // ================================
    
    func showRouteOnMap() {
        guard let start = userCoordinate,
              let destination = destinationCoordinate else {
            print("MapView missing coordinates")
            return
        }
        
        // clear any old overlays / annotations
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        
        // always add destination pin
        let destinationAnnotation = MKPointAnnotation()
        destinationAnnotation.coordinate = destination
        destinationAnnotation.title = "Destination"
        mapView.addAnnotation(destinationAnnotation)
        
        // if a coffee shop was selected, we draw TWO route legs
        if let shop = selectedShop {
            drawRoute(from: start, to: shop.coordinate)
            drawRoute(from: shop.coordinate, to: destination)
            
            // add coffee shop pin
            let shopAnnotation = MKPointAnnotation()
            shopAnnotation.coordinate = shop.coordinate
            shopAnnotation.title = shop.name
            mapView.addAnnotation(shopAnnotation)
            
        } else {
            // otherwise, just draw direct route
            drawRoute(from: start, to: destination)
        }
    }
    
    // ================================
    // ROUTE DRAWING HELPER
    // ================================
    
    // this function asks Apple Maps for directions
    // and draws the resulting polyline on the map
    func drawRoute(from start: CLLocationCoordinate2D,
                   to end: CLLocationCoordinate2D) {
        
        let startPlacemark = MKPlacemark(coordinate: start)
        let endPlacemark = MKPlacemark(coordinate: end)
        
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startPlacemark)
        request.destination = MKMapItem(placemark: endPlacemark)
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        
        directions.calculate { response, error in
            if let error = error {
                print("Directions error:", error.localizedDescription)
                return
            }
            
            guard let route = response?.routes.first else {
                return
            }
            
            // add route line to map
            self.mapView.addOverlay(route.polyline)
            
            // IMPORTANT:
            // fit the map region to the actual route,
            // this fixes the "blank grid" issue for direct routes
            self.mapView.setVisibleMapRect(
                route.polyline.boundingMapRect,
                edgePadding: UIEdgeInsets(top: 80, left: 40, bottom: 120, right: 40),
                animated: true
            )
        }
    }
    
    // ================================
    // OVERLAY RENDERER
    // ================================
    
    // this tells MapKit how to draw the route line
    func mapView(_ mapView: MKMapView,
                 rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .systemBlue
            renderer.lineWidth = 5
            return renderer
        }
        
        return MKOverlayRenderer(overlay: overlay)
    }
    
    // ================================
    // START NAVIGATION BUTTON
    // ================================
    
    // this launches Apple Maps once the user confirms then taps
    @IBAction func startNavigationTapped(_ sender: UIButton) {
        guard let start = userCoordinate,
              let destination = destinationCoordinate else {
            print("MapView missing coordinates for navigation")
            return
        }
        
        var items: [MKMapItem] = []
        
        let startItem = MKMapItem(placemark: MKPlacemark(coordinate: start))
        items.append(startItem)
        
        if let shop = selectedShop {
            let shopItem = MKMapItem(placemark: MKPlacemark(coordinate: shop.coordinate))
            items.append(shopItem)
        }
        
        let destItem = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        items.append(destItem)
        
        // taken to apple maps
        MKMapItem.openMaps(
            with: items,
            launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ]
        )
    }
}
