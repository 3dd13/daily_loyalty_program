//
//  AppDelegate.swift
//  DailyLoyaltyProgram
//
//  Created by Eddie Lau on 16/8/14.
//  Copyright (c) 2014 42 Labs. All rights reserved.
//

import UIKit
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {
                            
    var window: UIWindow?
    var locationManager: CLLocationManager?
    var lastProximity: CLProximity?
    var detectedBeacons = Array<PFObject>()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool {
        // Override point for customization after application launch.
        setupParse()
        setupLocationManager(application)
        setupUserBeaconHistory()
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func showDailyAd(inRegionBeacons: AnyObject[]!) {
        if (inRegionBeacons.count > 0) {
            for inRegionBeacon in inRegionBeacons {
                let beacon:CLBeacon = inRegionBeacon as CLBeacon
                
                switch beacon.proximity {
                case CLProximity.Far:
                    let deviceFullId = "\(beacon.proximityUUID) \(beacon.major) \(beacon.minor)"
                    let result = detectedBeacons.filter { ($0.valueForKey("deviceFullId") as String) == deviceFullId }

                    if (result.count > 0) {
                        let lastVisitedAt = result[0].valueForKey("lastVisitedAt") as NSDate
                        if (lastVisitedAt.timeIntervalSinceNow < -86400) {
                            refreshDeviceLastVisitedAt(result[0])
                            
                            sendLocalNotificationWithMessage(beacon)
                        }
                    } else {
                        createVisitHistory(deviceFullId)
                        
                        sendLocalNotificationWithMessage(beacon)
                    }
                default:
                    continue
                }
            }
        }
    }
    
    func setupParse() {
        let parseAppId = "hGsFyhrhf5bJxAxiqiQmMOXF6DHUeJ9NZR5gRdWQ"
        let parseClientKey = "1OnagQR3BcwgEUOYknAEcb45PGqyWou0aeehVJQF"
        Parse.setApplicationId("hGsFyhrhf5bJxAxiqiQmMOXF6DHUeJ9NZR5gRdWQ", clientKey: parseClientKey)
        PFUser.enableAutomaticUser()
    }
    
    func setupLocationManager(application: UIApplication) {
        // Garage Society iBeacon UUID
        let uuidString = "B9407F30-F5F8-466E-AFF9-25556B57FE6D"
        let beaconIdentifier = "iBeaconGarageSociety"
        let beaconUUID:NSUUID = NSUUID(UUIDString: uuidString)
        let beaconRegion:CLBeaconRegion = CLBeaconRegion(proximityUUID: beaconUUID, identifier: beaconIdentifier)
        
        locationManager = CLLocationManager()
        if(locationManager!.respondsToSelector("requestAlwaysAuthorization")) {
            locationManager!.requestAlwaysAuthorization()
        }
        locationManager!.delegate = self
        locationManager!.pausesLocationUpdatesAutomatically = false
        
        locationManager!.startMonitoringForRegion(beaconRegion)
        locationManager!.startRangingBeaconsInRegion(beaconRegion)
        locationManager!.startUpdatingLocation()
        
        if(application.respondsToSelector("registerUserNotificationSettings:")) {
            application.registerUserNotificationSettings(
                UIUserNotificationSettings(
                    forTypes: UIUserNotificationType.Alert | UIUserNotificationType.Sound,
                    categories: nil
                )
            )
        }
    }
    
    func setupUserBeaconHistory() {
        var query = PFQuery(className: "VisitHistory")
        query.whereKey("userId", equalTo: PFUser.currentUser().objectId)
        query.findObjectsInBackgroundWithBlock({(NSArray objects, NSError error) in
            if (error != nil) {
                NSLog("error " + error.localizedDescription)
            } else {
                NSLog("objects %@", objects as NSArray)
                self.detectedBeacons = objects as Array<PFObject>
            }
        })
    }
    
    func refreshDeviceLastVisitedAt(record: PFObject) {
        record.setValue(NSDate(), forKey: "lastVisitedAt")
        record.saveInBackgroundWithBlock {
            (success: Bool!, error: NSError!) -> Void in
            if (success) {
                NSLog("Object updated with id: \(record.objectId)")
            } else {
                NSLog("%@", error)
            }
        }
    }
    
    func createVisitHistory(deviceFullId: String) {
        let visitHistory = PFObject(className: "VisitHistory")
        visitHistory.setValue(PFUser.currentUser().objectId, forKey: "userId")
        visitHistory.setValue(deviceFullId, forKey: "deviceFullId")
        visitHistory.setValue(NSDate(), forKey: "lastVisitedAt")
        visitHistory.saveInBackgroundWithBlock {
            (success: Bool!, error: NSError!) -> Void in
            if (success) {
                NSLog("Object created with id: \(visitHistory.objectId)")
            } else {
                NSLog("%@", error)
            }
        }
    }
}

extension AppDelegate: CLLocationManagerDelegate {
    func sendLocalNotificationWithMessage(beacon: CLBeacon) {
        let message = "Within Far Region of \(beacon.proximityUUID) \(beacon.major) \(beacon.minor)"
        NSLog("%@", message)
        
        let notification:UILocalNotification = UILocalNotification()
        notification.alertBody = message
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
    }
    
    func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: AnyObject[]!, inRegion region: CLBeaconRegion!) {
        NSLog("didRangeBeacons");
    
        let viewController:ViewController = window!.rootViewController as ViewController
        viewController.beacons = beacons as CLBeacon[]?
        viewController.tableView.reloadData()
        
        showDailyAd(beacons)
    }
    
    func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
        manager.startRangingBeaconsInRegion(region as CLBeaconRegion)
        manager.startUpdatingLocation()
        
        NSLog("You entered the region")
    }
    
    func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!) {
        manager.stopRangingBeaconsInRegion(region as CLBeaconRegion)
        manager.stopUpdatingLocation()
        
        NSLog("You exited the region")
    }
}