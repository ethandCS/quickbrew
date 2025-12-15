QuickBrew

QuickBrew is a lightweight iOS application that helps commuters decide whether they have enough time to stop for coffee on the way to their destination.
 The app calculates direct travel time, evaluates coffee shop detours, and determines whether each option still allows the user to arrive on time.
The goal of the project is clarity and explainability rather than visual complexity. The application emphasizes clean architecture, readable Swift code, and a clear flow of data across multiple screens.

Overview
QuickBrew allows a user to enter:
 - A leaving time
 - An arrival deadline
 - A destination address

The app then:
 1. Retrieves the user’s current location
 2. Geocodes the destination address
 3. Calculates the direct driving route
 4. Searches for nearby coffee shops
 5. Computes detour routes through each shop
 6. Displays whether each option keeps the user on time
 7. Visualizes the chosen route on an in-app map
 8. Optionally launches Apple Maps for turn-by-turn navigation

This results in a complete, end-to-end commute planning experience across three screens.

Core Features
- User input for leaving time, arrival deadline, and destination
- Current location retrieval using CoreLocation
- Destination geocoding using MapKit
- Driving route calculation using MapKit directions
- Coffee shop search using MKLocalSearch
- Per-shop detour analysis:
    ~ User → Coffee Shop → Destination
    ~ Fixed stop time (+10 minutes)
    ~ Total detour minutes
    ~ Arrival ETA
    ~ On-time vs late determination
- Results displayed in a table view
- In-app map visualization of selected route
- Apple Maps navigation with multi-stop routing

Application Flow
 1. User enters commute details on the first screen
 2. App retrieves GPS location
 3. Destination address is geocoded
 4. Direct route ETA is calculated
 5. Nearby coffee shops are searched
 6. For each shop:
--Route from user to shop
--Route from shop to destination
--Stop time added
--Arrival time calculated
--On-time status determined
 7. Results are passed to the options screen
 8. User selects:
--Direct route, or
--A coffee shop route
 9. Selected route is displayed on an in-app map
 10. User can start Apple Maps navigation

Project Structure and File Responsibilities

***ViewController.swift

This is the main input and coordination controller.
 It performs all heavy computation before transitioning to the results screen.
 
Responsibilities:
--Reading leaving time, arrival deadline, and destination address
--Validating user input
--Requesting GPS permission and retrieving current location
--Geocoding the destination address
--Calculating direct route travel time
--Searching for nearby coffee shops
--Calculating detour times for each shop
--Computing arrival times and on-time status
--Passing all processed data forward

This controller acts as the core “orchestrator” of the app.

***OptionsViewController.swift

This controller is responsible for presentation and user decisions only.

Responsibilities:
--Displaying arrival deadline and direct ETA
--Showing overall on-time vs late status
--Displaying a table of coffee shop options:
----Shop name
----Extra detour minutes
----Arrival ETA
----On-time / late indicator
--Handling user selection:
----Coffee shop selection
----Direct route selection
--Passing the chosen route to MapViewController

No routing or search logic exists here.

***MapViewController.swift

This controller displays a live, interactive map inside the app.

Responsibilities:
--Visualizing the selected route using polylines
--Displaying:
----User location
----Destination
----Optional coffee stop
--Drawing:
----Direct route, or
----Two-leg route (user → shop → destination)
--Automatically fitting the map region to the route
--Launching Apple Maps when the user confirms navigation

This screen focuses entirely on visualization and navigation handoff.

***CoffeeShop.swift

A lightweight data model representing a coffee shop.

Stores:
--Name
--Geographic coordinate
--Total detour minutes
--Arrival time at destination
--On-time / late boolean

The model is populated incrementally as routing data is computed.

***CoffeeShopSearchService.swift

Encapsulates all coffee shop search logic.

Responsibilities:
--Performing local searches using MKLocalSearch
--Searching around the user’s location
--Returning clean CoffeeShop model objects

This keeps search logic out of view controllers.

RoutingService.swift
Encapsulates all routing logic using MapKit.
Responsibilities:
--Calculating driving travel time between two coordinates
--Returning travel time in minutes
--Used for:
----Direct routes
----User → coffee shop routes
----Coffee shop → destination routes

This isolates routing complexity behind a simple interface.

Main.storyboard
Defines the UI and navigation structure.
Contains:
 1. ViewController (Input screen)
 2. OptionsViewController (Results screen)
 3. MapViewController (In-app map screen)
 4. NavigationController (handles back navigation)


Segues:
ViewController → OptionsViewController
OptionsViewController → MapViewController



***Simulator Setup Instructions

QuickBrew relies on simulated GPS data when running in the iOS Simulator.

Recommended Test Location

Since the simulator defaults to San Francisco, use the following destination for consistent testing:

Coit Tower
 1 Telegraph Hill Blvd, San Francisco

How to Set Simulator Location
 1. Run the app in the iOS Simulator
 2. From the top menu bar:
    
    Select Features
    Select Location
    Choose Custom Location
    
 3. Enter coordinates near downtown San Francisco, for example:

    Latitude: 37.785834
    Longitude: -122.406417

 4. If location errors occur:
    
    Stop the simulator
    Restart the simulator
    Run the app again

If the user location is not available, routing will not proceed.

***How to Run the Application
 1. Open the project in Xcode
 2. Select an iOS Simulator device
 3. Ensure location permissions are allowed when prompted
 4. Enter:
    Leaving time
    Arrival deadline
    Destination address
 5. Tap Get Directions
 6. Review options\
 7. Select a route
 8. View route on the in-app map
 9. Tap Start Navigation to open Apple Maps


Technologies Used
UIKit
Used for:

    View controllers
    Navigation controller
    Table views
    Buttons, labels, and layout

CoreLocation
Used for:

    Requesting location permission
    Retrieving the user’s current GPS coordinates

MapKit
Used for:
    
    Geocoding destination addresses
    Route calculations
    Coffee shop searches
    In-app route visualization
    Apple Maps navigation

Swift
Primary programming language used throughout the project.

Summary
QuickBrew is a fully functional, multi-screen iOS application that demonstrates:
Real-world API usage
--Asynchronous coordination
--Clean separation of concerns
--Clear data flow
--Practical routing and mapping logic


The project emphasizes readability, correctness, and explainability, making it well-suited for academic evaluation and portfolio presentation.

