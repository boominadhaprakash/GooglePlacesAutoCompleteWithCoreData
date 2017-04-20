//
//  ViewController.swift
//  GoogleMapTask
//
//  Created by Boominadha Prakash on 18/04/17.
//  Copyright © 2017 Boomi. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import CoreLocation
import CoreData

class ViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,UISearchControllerDelegate,GMSMapViewDelegate {

    @IBOutlet weak var searchbar: UISearchBar!
    @IBOutlet weak var mapview: GMSMapView!
    @IBOutlet weak var tableview: UITableView!
    var latitude:Double!
    var longitude:Double!
    var placeid:String!
    var address:String!
    var placeArray = [String]()
    let locationManager = CLLocationManager()
    var location: [NSManagedObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.tableview.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {

    //To delete the core data entity values uncomment the below function
        //self.deleteAllRecords()
        
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        mapview.isMyLocationEnabled = true
        mapview.settings.myLocationButton = true
        locationManager.startUpdatingLocation()
        mapview.delegate=self
        mapview.settings.allowScrollGesturesDuringRotateOrZoom = false
        if locationManager.location != nil && self.location.count < 0
        {
            let camera = GMSCameraPosition.camera(withLatitude: locationManager.location!.coordinate.latitude, longitude: locationManager.location!.coordinate.longitude, zoom: 10)
            self.mapview.camera = camera
        }
        else
        {

            guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
                    return
            }
            
            let managedContext =
                appDelegate.persistentContainer.viewContext

            let fetchRequest =
                NSFetchRequest<NSManagedObject>(entityName: "Location")

            do {
                location = try managedContext.fetch(fetchRequest)
                for loc in location as [NSManagedObject] {
                    let position = CLLocationCoordinate2D(latitude: Double(loc.value(forKey: "latitude") as! NSNumber), longitude: Double(loc.value(forKey: "longitude") as! NSNumber))
                    let marker = GMSMarker(position: position)
                    
                    let camera = GMSCameraPosition.camera(withLatitude: Double(loc.value(forKey: "latitude") as! NSNumber), longitude: Double(loc.value(forKey: "longitude") as! NSNumber), zoom: 10)
                    self.mapview.camera = camera
                    if loc.value(forKey: "address") != nil
                    {
                        marker.title = "\(loc.value(forKey: "address")!)"
                    }
                    marker.map = self.mapview
                }
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }

        }
        
        
    }
    func deleteAllRecords() {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        let context = appDelegate.persistentContainer.viewContext
        
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print ("There was an error")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return self.total
        return self.placeArray.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        
    }
    
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell:AddressDisplayTableViewCell = tableView.dequeueReusableCell(withIdentifier: "AddressDisplayTableViewCell", for: indexPath) as! AddressDisplayTableViewCell
        if placeArray.count > 0
        {
            cell.addressdisplaylabel.text = self.placeArray[indexPath.row]
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath){
        if self.placeArray.count > 0
        {
            let correctedAddress:String! = self.placeArray[indexPath.row]
            let urlstring = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=\(correctedAddress!)&types=geocode&key=\(googleapikey)"
            let encodeurlstring = urlstring.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
            let encodeurl = NSURL(string: encodeurlstring!)
            
            let task = URLSession.shared.dataTask(with: encodeurl! as URL) { (data, response, error) -> Void in
                do {
                    if data != nil{
                        let dic = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableLeaves) as! NSDictionary
                        print("Dictionary:\(dic)")
                        
                        let place_id = ((dic["predictions"] as! NSArray).object(at: 0) as AnyObject).value(forKey: "place_id")
                        self.placeid = place_id as! String
                        self.address = self.placeArray[indexPath.row]
                        print("Place ID:\(self.placeid)")
                        
                        self.performSelector(onMainThread: #selector(ViewController.calllocationfunc), with: nil, waitUntilDone: true)
                        
                    }
                    
                }catch {
                    print("Error")
                }
            }
            task.resume()
        }
        else
        {
            //place array is empty
            print("Place array is empty")
        }
    }
    func calllocationfunc()
    {
        self.tableview.isHidden = true
        let urlstring = "https://maps.googleapis.com/maps/api/place/details/json?input=\(self.address)&placeid=\(self.placeid!)&key=\(googleapikey)"
        let encodeurlstring = urlstring.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let encodeurl = NSURL(string: encodeurlstring!)
        print("URL:\(urlstring)")
        print("Encode URL:\(encodeurlstring!)")
        let task = URLSession.shared.dataTask(with: encodeurl! as URL) { (data, response, error) -> Void in
            do {
                if data != nil{
                    let dic = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableLeaves) as! NSDictionary
                    print("Location Dictionary:\(dic)")
                    let lat = ((((dic["result"] as AnyObject).value(forKey: "geometry") as AnyObject).value(forKey: "location") as AnyObject).value(forKey: "lat") as AnyObject) as! Double
                     let lon = ((((dic["result"] as AnyObject).value(forKey: "geometry") as AnyObject).value(forKey: "location") as AnyObject).value(forKey: "lng") as AnyObject) as! Double
                     print("Lat:\(lat), Long:\(lon)")
                    self.latitude = lat
                    self.longitude = lon
                    self.performSelector(onMainThread: #selector(ViewController.setmarker), with: nil, waitUntilDone: true)
                }
                
            }catch {
                print("Error")
            }
        }
        task.resume()
    }
    
    func setmarker()
    {
        let position = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
        let marker = GMSMarker(position: position)
        
        let camera = GMSCameraPosition.camera(withLatitude: self.latitude, longitude: self.longitude, zoom: 10)
        self.mapview.camera = camera
        if self.address != nil
        {
            marker.title = "\(address!)"
        }
        marker.map = self.mapview
        
        //Core Data
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Location")
        let entity = NSEntityDescription.entity(forEntityName: "Location", in: managedContext)
        let locationCore = NSManagedObject(entity: entity!, insertInto: managedContext)
        locationCore.setValue(self.latitude, forKey: "latitude")
        locationCore.setValue(self.longitude, forKey: "longitude")
        locationCore.setValue(self.address, forKey: "address")
        var found:Bool = true
        do
        {
            location = try managedContext.fetch(fetchRequest)
            for loc in location as [NSManagedObject] {
                if loc.value(forKey: "latitude") as? Double != self.latitude && loc.value(forKey: "longitude") as? Double != self.longitude
                {
                    found = false
                }
            }
            if found == false
            {
                try managedContext.save()
                location.append(locationCore)
            }
            else
            {
                print("Location already exist")
            }
            
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        //searchActive = true;
        let keyboardDoneButtonShow = UIToolbar(frame: CGRect(x:0, y:0,  width:self.view.frame.size.width, height:self.view.frame.size.height/17))
        //Setting the style for the toolbar
        keyboardDoneButtonShow.barStyle = UIBarStyle .blackTranslucent
        //Making the done button and calling the textFieldShouldReturn native method for hidding the keyboard.
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.done, target: self, action: #selector(ViewController.keyboardhide))
        //Calculating the flexible Space.
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        //Setting the color of the button.
        doneButton.tintColor = UIColor(red: 240.0/255.0, green: 168.0/255.0, blue: 65.0/255.0, alpha: 1.0)
        //Making an object using the button and space for the toolbar
        let toolbarButton = [flexSpace,doneButton]
        //Adding the object for toolbar to the toolbar itself
        keyboardDoneButtonShow.setItems(toolbarButton, animated: false)
        //Now adding the complete thing against the desired textfield
        searchbar.inputAccessoryView = keyboardDoneButtonShow
    }
    
    func keyboardhide()
    {
        self.view.endEditing(true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.searchbar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    }
    
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        let notAllowedCharacters = " ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_"
        
        print("Text:\(text)")
        
        let set = NSCharacterSet(charactersIn: notAllowedCharacters)
        let inverted = set.inverted
        
        let filtered = text.components(separatedBy: inverted).joined(separator: "")
        
        if text == "\n"
        {
            print("Search bar search button clicked")
            self.searchBarSearchButtonClicked(self.searchbar)
        }
        
        return filtered == text
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        self.view.endEditing(true)

    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        let placeClient = GMSPlacesClient()

        placeClient.autocompleteQuery(searchText, bounds: nil, filter: nil) { (results, err) in
            self.placeArray.removeAll()
            if results == nil {
                return
            }
            
            for result in results! {
                if let result:GMSAutocompletePrediction = result {
                    self.placeArray.append(result.attributedFullText.string)
                }
            }
            
            print("Place array:\(self.placeArray)")
            if self.searchbar.text!.characters.count > 0
            {
                self.tableview.isHidden = false
            }
            else
            {
                self.tableview.isHidden = true
            }
            self.tableview.reloadData()
        }
        
    }
    

}

extension ViewController: CLLocationManagerDelegate {
    
    private func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        //Checking whether Current location is enabled in GPS or not.
        
        if status == .authorizedAlways {
            print("Running always")
            locationManager.startUpdatingLocation()
            mapview.isMyLocationEnabled = true
            mapview.settings.myLocationButton = true
        }
        else if status == .authorizedWhenInUse
        {
            print("Running when in use")
            locationManager.startUpdatingLocation()
            mapview.isMyLocationEnabled = true
            mapview.settings.myLocationButton = true
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        if let location = locations.first
        {

            print("currLat:",location.coordinate.latitude)
            print("CurrLong:",location.coordinate.longitude)
            let currentLat = location.coordinate.latitude
            let currentLong = location.coordinate.longitude
            
            if currentLat != 0.0 && currentLong != 0.0
            {
                mapview.camera = GMSCameraPosition(target: CLLocationCoordinate2DMake(currentLat, currentLat), zoom: 14, bearing: 0, viewingAngle: 0)
            }

            self.locationManager.stopUpdatingLocation()
        }
    }
}

