//
//  ViewController.swift
//  AutocompleteTextfieldSwift
//
//  Created by Mylene Bayan on 2/21/15.
//  Copyright (c) 2015 MaiLin. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, AutocompleteTextFieldDelegate, AutocompleteTextFieldDataSource, NSURLConnectionDataDelegate{

  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var autocompleTextfield: AutocompleteTextfield!
  
  private var responseData:NSMutableData?
  private var selectedPointAnnotation:MKPointAnnotation?
  private var locationManager = CLLocationManager()
  private var connection:NSURLConnection?
  
  private let googleMapsKey = "AIzaSyD8-OfZ21X2QLS1xLzu1CLCfPVmGtch7lo"
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    configureView()
    //initializeLocationServices()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  private func configureView(){
    autocompleTextfield.autoCompleteTextColor = UIColor.redColor()
    autocompleTextfield.autoCompleteTextFont = UIFont(name: "HelveticaNeue-Heavy", size: 12.0)
    autocompleTextfield.autoCompleteDelegate = self
    autocompleTextfield.autoCompleteDataSource = self
  }
  
  //MARK: AutocompleteTextFieldDelegate
  func textFieldDidChange(text: String) {
    if !text.isEmpty{
      if connection != nil{
        connection!.cancel()
        connection = nil
      }
      let baseURLString = "https://maps.googleapis.com/maps/api/place/autocomplete/json"
      let url = NSURL(string: "\(baseURLString)?key=\(googleMapsKey)&input=\(text)")
      if url != nil{
        let urlRequest = NSURLRequest(URL: url!)
        connection = NSURLConnection(request: urlRequest, delegate: self)
      }
    }
  }
  
  func didSelectAutocompleteText(text: String, indexPath: NSIndexPath) {
    println("You selected: \(text)")
    processSelectedAddress(text)
  }
  
  //MARK: AutocompleteTextFieldDelegate
  var autoCompleteCellHeight:CGFloat = 35.0
  var maximumAutoCompleteCount = 3
  var autoCompleEdgeInset = UIEdgeInsetsMake(0, 10, 0, 10)
  
  //MARK: NSURLConnectionDelegate
  func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
    responseData = NSMutableData()
  }
  
  func connection(connection: NSURLConnection, didReceiveData data: NSData) {
    responseData = NSMutableData(data: data)
  }

  func connectionDidFinishLoading(connection: NSURLConnection) {
    if responseData != nil{
      var error:NSError?
      if let result = NSJSONSerialization.JSONObjectWithData(responseData!, options: nil, error: &error) as? NSDictionary{
        let status = result["status"] as? String
        if status == "OK"{
          if let predictions = result["predictions"] as? NSArray{
            var locations = [String]()
            for dict in predictions as [NSDictionary]{
              locations.append(dict["description"] as String)
            }
            self.autocompleTextfield.autoCompleteStrings = locations
          }
        }
      }
    }
  }
  
  func connection(connection: NSURLConnection, didFailWithError error: NSError) {
    println("Error: \(error.localizedDescription)")
  }
  
  //MARK: Map Utilities
  private func processSelectedAddress(address:String){
    Location.geocodeAddressString(address, completion: { (placemark, error) -> Void in
      if placemark != nil{
        let coordinate = placemark!.location.coordinate
        self.addAnnotation(coordinate, address: address)
        self.mapView.setCenterCoordinate(coordinate, zoomLevel: 12, animated: true)
      }
    })
  }
  
  private func addAnnotation(coordinate:CLLocationCoordinate2D, address:String?){
    if selectedPointAnnotation != nil{
      mapView.removeAnnotation(selectedPointAnnotation)
    }
    
    selectedPointAnnotation = MKPointAnnotation()
    selectedPointAnnotation?.coordinate = coordinate
    selectedPointAnnotation?.title = address
    mapView.addAnnotation(selectedPointAnnotation)
  }
}

