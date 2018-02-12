//
//  LocationMessage.swift
//  ChitChat
//
//  Created by next-shot on 11/10/17.
//  Copyright © 2017 next-shot. All rights reserved.
//

import Foundation
import MapKit

// The expense record itself.
// Extract from the MessageRecord payLoad the amount and reason for the expense.
class LocationRecord : MessageRecord, MessageRecordDelegate {
    var loc: CLLocation
    var status = String()
    
    init(id: RecordId, user_id: RecordId, share_location_event_id: RecordId, location: CLLocation) {
        self.loc = location
        super.init(id: id, message_id: share_location_event_id, user_id: user_id, type: "LocationRecord")
        self.delegate = self
        self.payLoad = getPayLoad()
    }
    
    init(message: Message, user: User, location: CLLocation) {
        self.loc = location
        super.init(message: message, user: user, type: "LocationRecord")
        self.delegate = self
        self.payLoad = self.getPayLoad()
    }
    
    init(record: MessageRecord) {
        self.loc = CLLocation()
        super.init(record: record, type: "LocationRecord")
        self.delegate = self
        
        initFromPayload(string: record.payLoad)
    }
    
    func put(dict: NSMutableDictionary) {
        dict.setValue(NSNumber(value: loc.coordinate.latitude), forKey: "latitude")
        dict.setValue(NSNumber(value: loc.coordinate.longitude), forKey: "longitude")
        dict.setValue(NSString(string: status), forKey: "status")
    }
    
    func fetch(dict: NSDictionary) {
        let latitude = (dict["latitude"] as! NSNumber) as! Double
        let longitude = (dict["longitude"] as! NSNumber) as! Double
        loc = CLLocation(latitude: latitude, longitude: longitude)
        let status = dict["status"] as? NSString
        if( status != nil ) {
            self.status = status! as String
        }
    }
    
}

// Classes for the TableView showing user status

class LocationMessageTableCell : UITableViewCell {
    @IBOutlet weak var user_name: UILabel!
    
    @IBOutlet weak var user_status: UILabel!
}

class LocationMessageTableViewDataSource : NSObject, UITableViewDataSource {
    let locationRecords : [LocationRecord]
    
    init(locationRecords: [LocationRecord]) {
        self.locationRecords = locationRecords
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locationRecords.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationMessageTableCell") as! LocationMessageTableCell
        let row = indexPath.row
        let locr = locationRecords[row]
        if( locr.user_id == model.me().id ) {
            cell.user_name.text = "Me"
            cell.user_status.text = locr.status
        } else {
            cell.user_name.text = model.getUser(userId: locr.user_id)?.label
            cell.user_status.text = locr.status
        }
        
        return cell
    }
}

/*******************************************************************/

// MKAnnotation linked to a LocationRecord associated to the Message.
class LocationMessageAnnotation : NSObject, MKAnnotation {
    let loc : LocationRecord
    init(loc: LocationRecord) {
        self.loc = loc
    }
    var title: String? {
        if( loc.user_id == model.me().id ) {
            return "Me"
        }
        let user = model.getUser(userId: loc.user_id)
        return user?.label
    }
    
    var subtitle: String? {
        return DateFormatter.localizedString(from: loc.date_created, dateStyle: DateFormatter.Style.medium, timeStyle: DateFormatter.Style.short)
    }
    
    var coordinate: CLLocationCoordinate2D {
        return loc.loc.coordinate
    }
}

/************** Overlay management *********************/

// MKMapViewDelegate to display overlays
class LocationMessageMapViewDelegate : NSObject, MKMapViewDelegate {
    weak var cell : LocationMessageCell?
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if( overlay is MKCircle ) {
            let renderer = MKCircleRenderer(overlay: overlay as! MKCircle)
            renderer.strokeColor = UIColor.black
            renderer.lineWidth = 0.5
            return renderer
        } else if( overlay is RadarArcOverlay ) {
            let renderer = RadarArcRenderer(overlay: overlay)
            renderer.strokeColor = (overlay as! RadarArcOverlay).color
            renderer.lineWidth = 2
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
         // Update user location in DB
        if( cell != nil && userLocation.location != nil ) {
            cell!.setLocationFromMap(newLocation: userLocation.location!)
        }
    }
}

// Model of the RadarArc identicating a potential user direction
class RadarArcOverlay : NSObject, MKOverlay {
    var coordinate: CLLocationCoordinate2D
    var boundingMapRect: MKMapRect
    var radius : CLLocationDistance
    var angle : Double
    var color: UIColor
    var thickness: CLLocationDistance
    init(center: CLLocationCoordinate2D, radius: CLLocationDistance, angle: Double,
         color: UIColor, thickness: CLLocationDistance) {
        self.coordinate = center
        self.radius = radius
        self.angle = angle
        self.color = color
        self.thickness = thickness
        let mapCenter = MKMapPointForCoordinate(center)
        self.boundingMapRect = MKMapRect(
            origin: MKMapPoint(x: mapCenter.x - radius, y: mapCenter.y - radius),
            size: MKMapSize(width: radius*2, height: radius*2)
        )
    }
}

// Render a thick arc which location is given by the RadarArcOverlay
class RadarArcRenderer : MKOverlayPathRenderer {
    var endGradient = CGPoint()
    var startGradient = CGPoint()
    
    override func createPath() {
        let arcOverlay = overlay as! RadarArcOverlay
        let arcMidAngle = CGFloat(arcOverlay.angle)
        let cgpath = CGMutablePath()
        let arcHalfAngle : CGFloat = CGFloat(10/180*Double.pi)
        
        let center = MKMapPointForCoordinate(arcOverlay.coordinate)
        let scale = MKMetersPerMapPointAtLatitude(arcOverlay.coordinate.latitude)
        let radius : CGFloat = CGFloat(arcOverlay.radius/scale)
        let thick = CGFloat(arcOverlay.thickness/scale)
    
        // Compute start and end of gradient
        let start = point(for: center)
        let end = CGPoint(x: start.x + radius*cos(arcMidAngle), y: start.y + radius*sin(arcMidAngle))
        startGradient = start
        endGradient = end
        
        //cgpath.move(to: point(for: center))
        cgpath.addRelativeArc(
            center: point(for: center), radius: radius-thick,
            startAngle: arcMidAngle+arcHalfAngle, delta: -arcHalfAngle*2
        )
        cgpath.addArc(
            center: point(for: center), radius: radius,
            startAngle: arcMidAngle-arcHalfAngle, endAngle: arcMidAngle+arcHalfAngle, clockwise: false
        )
        cgpath.closeSubpath()
        
        self.path = cgpath
    }
    
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        //context.setStrokeColor(strokeColor!.cgColor)
        //context.setLineWidth(self.lineWidth/zoomScale)
        //context.addPath(path)
        //context.strokePath()
        //context.setShadow(offset: CGSize(width: 3, height: 3), blur: 5)
        //context.addPath(path)
        //context.setFillColor(UIColor.white.cgColor)
        //context.fillPath()
        
        context.saveGState()
        //2 - get the current context
        let colors = [UIColor.white.cgColor.copy(alpha: 0.2), strokeColor!.cgColor.copy(alpha: 0.2)]
        
        //3 - set up the color space
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        //4 - set up the color stops
        let colorLocations:[CGFloat] = [0.0, 1.0]
        
        //5 - create the gradient
        let gradient = CGGradient(colorsSpace: colorSpace,colors: colors as CFArray, locations: colorLocations)
        
        context.addPath(self.path)
        
        // Compute start (white) and end point (stroke color) of gradient line
        context.clip()
        context.drawLinearGradient(
            gradient!, start: startGradient, end: endGradient, options: CGGradientDrawingOptions(rawValue: 0)
        )
        context.restoreGState()
    }
}

// Manage MKMapView overlay drawings
// which consist of 3 circles around the center location
// and arcs in the direction of the other users on the appropriate circle.
class RadarCircles {
    var circles = [MKCircle]()
    var arcs = [RadarArcOverlay]()
    init(loc: CLLocation, mapView: MKMapView, maxDistance: CLLocationDistance,
         otherLocations: [CLLocation]
    ) {
        let minRadius = getNiceNumber(maxDistance/10)
        for i in 1...3 {
            let circle = MKCircle(center: loc.coordinate, radius: minRadius*CLLocationDistance(i))
            circles.append(circle)
        }
        mapView.addOverlays(circles)
        
        initArcs(loc: loc, minRadius: minRadius, otherLocations: otherLocations)
        mapView.addOverlays(arcs)
    }
    
    // Compute location of the arcs indicating for each other user's locations
    // the direction into which the other user is and a distance range.
    func initArcs(loc: CLLocation, minRadius: CLLocationDistance, otherLocations: [CLLocation]) {
        let center = MKMapPointForCoordinate(loc.coordinate)
        let colors = [UIColor.red, UIColor.cyan, UIColor.blue]
        for ol in otherLocations {
            let d = loc.distance(from: ol)
            // Locate on which circle should we draw the arc.
            var index = Int(d/minRadius)
            index = min(index, 3)
            index = max(index, 1)
            // Find arc center angle.
            let opt = MKMapPointForCoordinate(ol.coordinate)
            let angle = atan2(opt.y - center.y, opt.x - center.x)
            let arc = RadarArcOverlay(
                center: loc.coordinate, radius: minRadius*CLLocationDistance(index),
                angle: angle, color: colors[index-1], thickness: minRadius*0.3
            )
            arcs.append(arc)
        }
    }
    
    // The current user location has changed or other users location has changed.
    // Update the circles positions and arcs.
    func update(
        loc: CLLocation, mapView: MKMapView, maxDistance: CLLocationDistance,
        otherLocations: [CLLocation]
    ) {
        let minRadius = getNiceNumber(maxDistance/10)
        mapView.removeOverlays(circles)
        for i in 1...3 {
            let circle = MKCircle(center: loc.coordinate, radius: minRadius*CLLocationDistance(i))
            circles[i-1] = circle
        }
        mapView.addOverlays(circles)
        
        mapView.removeOverlays(arcs)
        arcs.removeAll()
        initArcs(loc: loc, minRadius: minRadius, otherLocations: otherLocations)
        mapView.addOverlays(arcs)
    }
    
    func getNiceNumber(_ v: CLLocationDistance) -> CLLocationDistance {
        let expt = floor(log10(v))
        let frac = v/pow(10, expt)
        let nice : CLLocationDistance = {
            if( frac <= 1.0 ) {
                return 1.0
            } else if( frac <= 2.0 ) {
                return 2.0
            } else if( frac <= 5.0 ) {
                return 5.0
            } else {
                return 10.0
            }
        }()
        return nice*pow(10, expt)
    }
}

/***********************************/

// ModelView to update the display of the cell when MessageRecord insert/changes occur
class LocationCellModelView : ModelView {
    weak var cell : LocationMessageCell?
    
    init(cell: LocationMessageCell) {
        self.cell = cell
        super.init()
        
        self.notify_new_message_record = new_location_record
        self.notify_edit_message_record = edit_location_record
    }
    
    func new_location_record(record: MessageRecord) {
        cell?.updateLocations()
    }
    func edit_location_record(record: MessageRecord) {
        cell?.updateLocations()
    }
}

class LocationMessageCell : UICollectionViewCell, MessageBaseCellDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var labelView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var sharingLocationButton: UIButton!
    
    @IBOutlet weak var userTableStatus: UITableView!
    
    weak var controller: MessagesViewController?
    var message: Message?
    var locationManager: CLLocationManager?
    var bestEffortAtLocation : CLLocation?
    var locationRecord: LocationRecord?
    var mapViewDelegate = LocationMessageMapViewDelegate()
    var messageAnnotations = [MKAnnotation]()
    var radarCircles : RadarCircles?
    var locationHidden = false
    var modelView: LocationCellModelView?
    var userTableStatusDataSource : LocationMessageTableViewDataSource?
    
    deinit {
        if( modelView != nil ) {
            model.removeViews(views: [modelView!])
        }
    }
    
    func initialize(message: Message, controller : MessagesViewController?) {
        self.message = message
        self.controller = controller
        self.mapView.delegate = mapViewDelegate
        
        let mo = controller?.curMessageOption ?? MessageOptions(options: message.options)
        locationHidden = mo.decorated
        if( locationHidden ) {
            // Hide the button to take location. It is done automatically by the mapView
            sharingLocationButton.isHidden = true
            mapViewDelegate.cell = self
        } else {
            userTableStatus.isHidden = true
        }
        
        fromLabel.text = message.text
        
        // Listen to MessageRecords notifications
        if( modelView == nil ) {
            modelView = LocationCellModelView(cell: self)
            model.setupNotificationsForMessageRecord(messageId: message.id, view: self.modelView!)
        }
        
        updateLocations()
    }
    
    func initLocationManager(locationRecords: [LocationRecord]) {
        if( locationHidden ) {
            mapView.showsUserLocation = true // Force the map to find user location
            mapView.setUserTrackingMode(.follow, animated: true)
            
        } else {
            if( locationManager == nil ) {
                locationManager = CLLocationManager()
                locationManager!.delegate = self
                // IMPORTANT!!! kCLLocationAccuracyBest should not be used for comparison with location coordinate or attidute
                // accuracy because it is a negative value. Instead, compare against some predetermined "real" measure of
                // acceptable accuracy, or depend on the timeout to stop updating.
                locationManager!.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                locationManager!.headingFilter = 5
                if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.notDetermined {
                    locationManager!.requestWhenInUseAuthorization()
                }
            }
        }
        
        if( locationHidden ) {
            // Initialize location table status
            userTableStatusDataSource = LocationMessageTableViewDataSource(locationRecords : locationRecords)
            userTableStatus.dataSource = self.userTableStatusDataSource!
            userTableStatus.reloadData()
            
            // Initialize game buttons
            let myRecordIndex = locationRecords.index(where: { (loc) -> Bool in
                loc.user_id == model.me().id
            })
            let masterRecordIndex = locationRecords.index(where: { (loc) -> Bool in
                loc.user_id == message!.user_id
            })
            if( locationRecords.count > 1 && myRecordIndex != nil && masterRecordIndex != nil ) {
                let masterRecord = locationRecords[masterRecordIndex!]
                if( masterRecord.status.isEmpty ) {
                    if( message!.user_id == model.me().id ) {
                        // The one that starts the message, gets to start the game
                        sharingLocationButton.isHidden = false
                        sharingLocationButton.setImage(UIImage(named: "start32"), for: .normal)
                    }
                } else {
                    // The game has started
                    if( message!.user_id != model.me().id ) {
                        if( locationRecord!.status.isEmpty ) {
                            // The ones that join the message, gets to stop their participation to the game
                            sharingLocationButton.isHidden = false
                            sharingLocationButton.setImage(UIImage(named: "end32"), for: .normal)
                        }
                    } else {
                        // For the game master,see if the all people have been found.
                        let unfoundRecords = locationRecords.filter({ (loc) -> Bool in
                            loc.status.isEmpty
                        })
                        if( unfoundRecords.count == 0 && locationRecord != nil && locationRecord!.status != "Done" ) {
                            // Mark the game has finished.
                            locationRecord!.status = "Done"
                            model.saveLocationItem(locationRecord: locationRecord!)
                            updateLocations()
                        }
                    }
                }
            }
        }
    }
    
    func userIcon() -> UIImageView? {
        return nil
    }
    func containerView() -> UIView? {
        return labelView
    }
    
    // Retrieve the locations from the DB and setup map overlays and annotations display
    func updateLocations() {
        mapView.removeAnnotations(messageAnnotations)
        messageAnnotations.removeAll()
        
        model.getLocationItems(share_location_message: message!, completion: { (records) in
            if( self.controller == nil || self.message == nil ) {
                return
            }
            DispatchQueue.main.async(execute: {
                for locationRecord in records {
                    if( locationRecord.user_id == model.me().id ) {
                        if( self.locationRecord != nil ) {
                            // Work around an old bug where too many location records where created.
                            // Take latest position
                            if( self.locationRecord!.date_created < locationRecord.date_created ) {
                                self.locationRecord = locationRecord
                            }
                        } else {
                            self.locationRecord = locationRecord
                        }
                    } else {
                        if( !self.locationHidden ) {
                            self.messageAnnotations.append(LocationMessageAnnotation(loc: locationRecord))
                        }
                    }
                }
                if( self.locationRecord != nil && !self.locationHidden ) {
                    self.messageAnnotations.append(LocationMessageAnnotation(loc: self.locationRecord!))
                }
                
                self.mapView.addAnnotations(self.messageAnnotations)
                
                self.centerMapOnLocation(locRecords: records)
                
                // Once we have retrieved the records we can start listening to the location manager
                self.initLocationManager(locationRecords: records)
            })
        })
    }
    
    // Compute map display boundaries
    // Initialize Circles and Arcs overlays
    func centerMapOnLocation(locRecords: [LocationRecord]) {
        var loc : MKMapPoint?
        for locr in locRecords {
            loc = MKMapPointForCoordinate(locr.loc.coordinate)
            break
        }
        if( loc == nil ) {
            return
        }
        
        var minX = loc!.x
        var minY = loc!.y
        var maxX = loc!.x
        var maxY = loc!.y
        var distanceMax : CLLocationDistance = 0.0
        var otherLocations = [CLLocation]()
        for locr in locRecords {
            loc = MKMapPointForCoordinate(locr.loc.coordinate)
            minX = min(loc!.x, minX)
            minY = min(loc!.y, minY)
            maxX = max(loc!.x, maxX)
            maxY = max(loc!.y, maxY)
            if( locationRecord != nil ) {
                distanceMax = max(distanceMax, locationRecord!.loc.distance(from: locr.loc))
                if( locr.user_id != locationRecord?.user_id && locationHidden ) {
                    otherLocations.append(locr.loc)
                }
            }
        }
        let size = MKMapSize(width: maxX-minX, height: maxY-minY)
        let rect = MKMapRect(origin: MKMapPoint(x: minX-size.width*0.1, y: minY-size.height*0.1), size: MKMapSize(width: size.width*1.2, height: size.height*1.2))
        let loc_rect = MKCoordinateRegionForMapRect(rect)
        
        mapView.setRegion(loc_rect, animated: true)
        
        if( distanceMax != 0 ) {
            if( radarCircles == nil ) {
                radarCircles = RadarCircles(
                    loc: locationRecord!.loc, mapView: mapView, maxDistance: distanceMax, otherLocations: otherLocations
                )
            } else {
                radarCircles!.update(
                    loc: locationRecord!.loc, mapView: mapView, maxDistance: distanceMax, otherLocations: otherLocations
                )
            }
        }
    }
    
    // Callback of the sharingLocationButton.
    // This button has many roles:
    // Either take the location, start the game or end each participant role
    @IBAction func takeLocation(_ sender: Any) {
        if( locationHidden ) {
            if( locationRecord != nil ) {
                if( message!.user_id == model.me().id ) {
                    locationRecord!.status = "Searching"
                } else {
                    locationRecord!.status = "Found"
                }
                model.saveLocationItem(locationRecord: locationRecord!)
                updateLocations()
            }
        } else {
            if (CLLocationManager.locationServicesEnabled()) {
                bestEffortAtLocation = nil
                self.getLocation()
            }
        }
    }
    
    func getLocation() {
        if (bestEffortAtLocation != nil) {
            let locationAge = bestEffortAtLocation!.timestamp.timeIntervalSinceNow
            if (abs(locationAge) > 60) {
                locationManager?.stopUpdatingLocation()
                locationManager?.startUpdatingLocation()
            } else {
                //keep current location value
            }
        } else {
            locationManager?.startUpdatingLocation()
        }
    }
    
    // Mark: CLManager Delegate Methods
    // this is called when authorization status changes and when locationManager is initialiazed
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedAlways || status == CLAuthorizationStatus.authorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }
    
    // Update location from LocationManager
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // test the age of the location measurement to determine if the measurement is cached
        // in most cases you will not want to rely on cached measurements
        let newLocation = locations.last!
        let locationAge = newLocation.timestamp.timeIntervalSinceNow;
        if ( bestEffortAtLocation != nil && (abs(locationAge) > 5.0 || newLocation.timestamp > bestEffortAtLocation!.timestamp) ) {
            return;
        }
        
        // test that the horizontal accuracy does not indicate an invalid measurement
        if (newLocation.horizontalAccuracy < 0) {
            return;
        }
        
        // test the measurement to see if it is more accurate than the previous measurement
        if (self.bestEffortAtLocation == nil || self.bestEffortAtLocation!.horizontalAccuracy > newLocation.horizontalAccuracy ) {
            // store the location as the "best effort"
            self.bestEffortAtLocation = newLocation;
            
            if( locationRecord == nil ) {
                locationRecord = LocationRecord(message: message!, user: model.me(), location: newLocation)
            } else {
                locationRecord!.loc = newLocation
            }
            
            // test the measurement to see if it meets the desired accuracy
            if (newLocation.horizontalAccuracy <= self.locationManager!.desiredAccuracy) {
                // we have a measurement that meets our requirements, so we can stop updating the location
                // IMPORTANT!!! Minimize power usage by stopping the location manager as soon as possible.
                if( !locationHidden ) {
                    locationManager!.stopUpdatingLocation()
                }
                
                model.saveLocationItem(locationRecord: locationRecord!)
                updateLocations()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager?.stopUpdatingLocation()
    }
    
    // Update location from Map
    func setLocationFromMap(newLocation: CLLocation) {
        if( locationRecord == nil ) {
            locationRecord = LocationRecord(message: message!, user: model.me(), location: newLocation)
        } else {
            locationRecord!.loc = newLocation
        }
        model.saveLocationItem(locationRecord: locationRecord!)
        updateLocations()
    }
}

class LocationMessageCellSizeDelegate : MessageBaseCellSizeDelegate {
    func size(message: Message, collectionView: UICollectionView) -> CGSize {
        let hspacing : CGFloat = 5
        let width = collectionView.bounds.width - 2*hspacing
        
        let heightFromLabels : CGFloat = 28
        let vspacing : CGFloat = 5
        let mapHeight : CGFloat = 200
        var tableHeight : CGFloat = 0
        
        let mo = MessageOptions(options: message.options)
        if( mo.decorated ) {
            let heightFromTableLabels : CGFloat = 16
            tableHeight = heightFromTableLabels*4
        }
        
        return CGSize(width: width, height: heightFromLabels + 4*vspacing + mapHeight + tableHeight)
    }
}
