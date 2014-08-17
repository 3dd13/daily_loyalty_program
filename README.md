# Daily Loyalty Program


## Description

Display notification when user visit a location. It only display maximum once per day.


## Tech Stack

* iOS8
* Swift
* Parse (via Cocoapods)
* iBeacon (using CoreLocation)


## Workflow

Everything is in AppDelegate now

* setup Parse
* create anonymous Parse user
* ask for all iOS permission required
* start ranging beacons (only Garage Society Estimote)
* create or update visit history when the device is in "Far" region
* create notification for particular beacon in notification center if it hasn't displayed within 24 hours
