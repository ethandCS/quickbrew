//
//  OptionsViewController.swift
//  QuickBrew
//
//  Screen 2: summary + decision screen.
//  This screen shows the user:
//    - their arrival deadline (what they must reach by)
//    - direct ETA (driving straight to destination w/ no coffee stop)
//    - ON TIME vs LATE based on comparing ETA to allowed minutes
//    - a list of nearby coffee shops to optionally detour to
//
//  Logic note: this view DOES NOT calculate routes.
//  All heavy work (routing + coffee search) is done BEFORE arriving here.
//  This screen only *displays* the results and handles user navigation choices.
//

import UIKit
import MapKit

// handles table view logic + updating labels based on passed-in inputs
class OptionsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    
    // ================================
    // DATA PASSED IN FROM FIRST SCREEN
    // (we do not compute these here, they are assigned before this VC loads)
    // ================================
    
    var minutesAvailable: Int?              // total time the user has to complete trip (arrival-leaving)
    var directTravelMinutes: Int?           // time needed to drive directly to destination
    var arrivalDeadline: Date?              // the arrival time the user picked on screen 1
    var coffeeShops: [CoffeeShop] = []      // nearby coffee shops found earlier
    var coffeeStopMinutes: Int = 10         // fixed time estimate for grabbing a coffee (tweakable later)
    
    // coords used ONLY if user chooses "Go Directly" → opens Apple Maps route
    var userCoordinate: CLLocationCoordinate2D?
    var destinationCoordinate: CLLocationCoordinate2D?
    
    
    // ================================
    // OUTLETS (hooked up to storyboard)
    // ================================
      
    @IBOutlet weak var arrivalLabel: UILabel!   // shows arrival deadline (formatted)
    @IBOutlet weak var etaLabel: UILabel!       // shows direct ETA in minutes
    @IBOutlet weak var statusLabel: UILabel!    // displays ON TIME or LATE!
    @IBOutlet weak var tableView: UITableView!  // shows list of coffee shops
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // connect the tableView to this class (so it knows who provides rows + responds to taps)
        tableView.dataSource = self
        tableView.delegate = self
        
        // fill the labels with whatever values were passed in
        // (this is basically "initial UI setup")
        updateHeaderLabels()
    }
    
    
    // ================================
    // UPDATING THE HEADER INFO SECTION
    // ================================
    func updateHeaderLabels() {
        print("Options Screen:")
        print("minutesAvailable =", minutesAvailable ?? -1)
        print("directTravelMinutes =", directTravelMinutes ?? -1)
        print("arrivalDeadline =", arrivalDeadline ?? Date())
        print("coffee shops =", coffeeShops.count)

        // ----- arrival deadline -----
        if let deadline = arrivalDeadline {
            let formatter = DateFormatter()
            formatter.timeStyle = .short // EX: "5:30 PM"
            arrivalLabel.text = "Arrival Deadline: \(formatter.string(from: deadline))"
        } else {
            arrivalLabel.text = "Arrival Deadline: --"
        }
        
        
        // ----- direct ETA -----
        if let direct = directTravelMinutes {
            etaLabel.text = "Direct ETA: \(direct) min"
        } else {
            etaLabel.text = "Direct ETA: --"
        }
        
        
        // ----- ON TIME vs LATE -----
        // comparing direct driving time vs allowed time window
        if let available = minutesAvailable, let direct = directTravelMinutes {
            
            if direct <= available {
                // direct route fits within allowed time → GOOD
                statusLabel.text = "STATUS: ON TIME"
                statusLabel.textColor = .systemGreen
            } else {
                // user cannot reach in time even without coffee → BAD
                statusLabel.text = "STATUS: LATE!"
                statusLabel.textColor = .systemRed
            }
            
        } else {
            // in case something failed to pass into this VC
            statusLabel.text = "STATUS: unknown"
            statusLabel.textColor = .label
        }
    }


    // ================================
    // TABLE VIEW DATA SOURCE (rows + display)
    // ================================
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // one row per coffee shop found earlier
        return coffeeShops.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // grabs "CoffeeCell" from storyboard (make sure identifier matches)
        let cell = tableView.dequeueReusableCell(withIdentifier: "CoffeeCell", for: indexPath)
        
        // grab whichever coffee shop this row represents
        let shop = coffeeShops[indexPath.row]
        
        // basic display for now (later we can add distance, rating, etc.)
        // second line for eta
        cell.textLabel?.numberOfLines = 2
        
        // first line = name + detour
        if let detour = shop.detourMinutes {
            cell.textLabel?.text = "\(shop.name) (+\(detour) min)"
        } else {
            cell.textLabel?.text = shop.name
        }
        
        // second line = eta + on time/late
        var detail = ""
        
        if let eta = shop.arrivalTimeAtDestination {
            let f = DateFormatter()
            f.timeStyle = .short
            
            detail += "ETA: \(f.string(from: eta))"
        }
        
        if let onTime = shop.isOnTime {
            detail += onTime ? " * ON TIME" : " * LATE"
        }
        
        cell.detailTextLabel?.text = detail
        
        return cell
    }
    
    
    // ================================
    // TABLE VIEW DELEGATE (tap behavior)
    // ================================
    
    // producing 3 stop driving route with coffee shop like we did for direct just with one more param
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let shop = coffeeShops[indexPath.row]
        
        guard let user = userCoordinate,
              let destination = destinationCoordinate else {
            print("missing coordinates")
            return
        }
        
        let userItem = MKMapItem(placemark: MKPlacemark(coordinate: user))
        userItem.name = "Start"
        
        let shopItem = MKMapItem(placemark: MKPlacemark(coordinate: shop.coordinate))
        shopItem.name = shop.name
        
        let destItem = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        destItem.name = "Destination"
        
        MKMapItem.openMaps(
            with: [userItem, shopItem, destItem],
            launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ]
        )
    }
    
    
    // ================================
    // BUTTON: "GO DIRECTLY"
    // launches Apple Maps navigation from user → destination
    // ================================
    
    @IBAction func goDirectlyTapped(_ sender: UIButton) {
        print("Go Directly tapped")
        
        // make sure coords were passed from screen 1
        guard let start = userCoordinate,
              let dest = destinationCoordinate else {
            print("missing coordinates for Apple Maps")
            return
        }
        
        // wrap start + dest coords as MKMapItems (Apple Maps requirement)
        let startItem = MKMapItem(placemark: MKPlacemark(coordinate: start))
        let destItem = MKMapItem(placemark: MKPlacemark(coordinate: dest))
        
        // open Apple Maps w/ driving directions
        MKMapItem.openMaps(
            with: [startItem, destItem],
            launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        )
    }
}
