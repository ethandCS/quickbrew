QuickBrew

    A lightweight iOS app that helps commuters decide whether they have enough time to stop for coffee on the way to their destination.
    The app calculates direct travel time, evaluates coffee shop detours, and determines whether each option still allows on-time arrival.

Overview

QuickBrew allows a user to enter a leaving time, arrival deadline, and destination address.
The app retrieves the user’s current location, calculates direct route travel time, finds nearby coffee shops, and computes detour routes. For each coffee shop,
the app calculates the total added minutes, the predicted ETA at the destination, and whether the user remains on time. Users can select any option to open Apple Maps
with a multi-stop route.

Core Features

  User inputs: leaving time, arrival deadline, destination address
  Current location retrieval via CoreLocation
  Geocoding destination address
  Driving route calculation using MapKit
  Coffee shop search using MKLocalSearch
  Per-shop detour routing:

    User → Coffee Shop → Destination
    Added fixed stop time (default 10 minutes)
    Total detour minutes
    Arrival ETA
    On-time / late determination
  
  Results displayed in a table view
  Selecting any option opens the route in Apple Maps

Project Structure and File Responsibilities

ViewController.swift
  
  Handles all user inputs and performs core logic before transitioning to the results screen.
  Responsibilities include:
  
      Reading leaving time, arrival deadline, and destination text
      
      Validating inputs
      
      Requesting the user’s GPS location
      
      Geocoding destination address
      
      Calculating the direct route travel time
      
      Searching for nearby coffee shops
      
      Calculating detour times for each shop (user → shop → destination)
      
      Preparing and passing all data into OptionsViewController
  
  This file acts as the "coordinator" of all heavy computation.

OptionsViewController.swift

  Displays all processed information to the user.
  Responsibilities include:
  
    Showing arrival deadline, direct ETA, and overall on-time status
    
    Displaying a table of coffee shop options
  
      Shop name
      
      Extra minutes for detour
      
      ETA at final destination
      
      On-time / late indicator
      
    Launching Apple Maps with navigation
  
      Direct route: user → destination
      
      Coffee stop route: user → shop → destination
  
  This file contains no routing or search logic; it only presents results.


CoffeeShop.swift

  A lightweight data model struct representing each coffee shop.
  Stores:

    Name
    
    Location coordinate
    
    Detour minutes (total travel time including shop stop)
    
    Arrival time at destination
    
    Boolean on-time status

  This model is updated after routing results are computed.

CoffeeShopSearchService.swift

    Encapsulates MKLocalSearch logic.
    Responsibilities include:
    
    Searching for nearby coffee shops based on the user’s coordinate
    
    Returning a list of CoffeeShop objects containing names and coordinates

  This keeps search logic separate from view controllers.

RoutingService.swift

  Encapsulates MapKit routing logic.
  Responsibilities include:

    Calculating driving travel time between two coordinates
    
    Returning the travel time in minutes
    
    Used for both direct route and detour route calculations

This service isolates routing complexity behind a simple interface.



Main.storyboard

Defines the app’s UI.
Contains two screens:

  1.Input Screen (ViewController)
  
  2.Results Screen (OptionsViewController)
  Embedded in a Navigation Controller to provide automatic back navigation.

Connected outlets include:

  UIDatePickers
  
  UITextField
  
  UILabels
  
  UITableView
  

Info.plist Changes

  Added usage descriptions required for location services:
  
    NSLocationWhenInUseUsageDescription
  
  This allows CoreLocation to prompt the user for permission.


Technologies Used
  UIKit

    Used for all user interface elements, view controllers, navigation, table views, and interaction handling.

  CoreLocation

    Used to:

    Request user permission
    
    Retrieve current GPS coordinates

  MapKit

    Used for:
    
    Geocoding destination addresses
    
    Route calculations for:
    
      Direct travel
      
      User → Coffee Shop
      
      Coffee Shop → Destination
    
    Searching for coffee shops using MKLocalSearch
    
    Opening Apple Maps for navigation

  Swift

    Core application language used throughout, leveraging closures, structs, model objects, async coordination, and UIKit patterns.

How Data Flows Through the App

1. User enters inputs and presses “Get Directions”.

2. ViewController retrieves user location.

3. Destination address is geocoded.

4. Direct route travel time is calculated.

5. Coffee shops are searched around the user’s location.

    For each shop:
    
    Route 1: user → shop
    
    Route 2: shop → destination
    
    +10 minute stop time

    Detour total, new ETA, and on-time status are computed

7. All results are passed to OptionsViewController.

8. OptionsViewController displays formatted results.

9. User can tap any row to open Apple Maps with a multi-stop route.
