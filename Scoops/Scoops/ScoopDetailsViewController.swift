//
//  ScoopDetailsViewController.swift
//  Scoops
//
//  Created by Charles Moncada on 23/10/16.
//  Copyright © 2016 Charles Moncada. All rights reserved.
//

import UIKit
import CoreLocation

class ScoopDetailsViewController: UITableViewController {

    
    @IBOutlet weak var titleText: UITextField!
    @IBOutlet weak var scoopText: UITextView!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var photoImage: UIImageView!
    @IBOutlet weak var addPhotoLabel: UILabel!
    @IBOutlet weak var actionButton: UIBarButtonItem!
    @IBOutlet weak var publishSwitch: UISwitch!
    
    // MARK: - Location Properties
    let locationManager = CLLocationManager()
    var location: CLLocation?
    var coordinate: CLLocationCoordinate2D?
    var updatingLocation = false
    var lastLocationError: NSError?
    var timer: Timer?
    
    var image: UIImage?
    var authorName: String?
    
    var descriptionText = "(Inserte texto aqui)"
    
    var scoopToEdit: ScoopRecord? {
        didSet {
            print("consegui los datos")
            updateLabels()
        }
    }
    
    var id: String? {
        didSet {
            print("debo cargar el objecto con id: \(id!)")
            
        }
    }
    
    var model: ScoopRecord?
    var client: MSClient?
    
    var container: AZSCloudBlobContainer?
    var blobName: String?
    var sas: String?

// MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // conseguimos datos del usuario de Facebook
        client?.invokeAPI("getFacebookInfo", body: nil, httpMethod: "GET", parameters: nil, headers: nil, completion: { (result, response, error) in
            
            if let _ = error {
                print("error al invocar la api: \(error)")
                return
            }
            
            if let _ = result {
                let json = result as! NSDictionary
                self.authorName = json["name"] as? String
            }
        })
        
        if let _ = id {
            print("no busco localizacion")
            actionButton.title = "Update"
            loadScoop(id!)
        } else {
            getLocation()
            publishSwitch.isEnabled = false
        }
        
        updateLabels()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

// MARK: - IBAction
    
    @IBAction func saveNewScoop(_ sender: AnyObject) {
        
        if actionButton.title == "Save" {
            print("Se grabara Scoop")
            addNewScoop()
        } else {
            print("Se actualizara el registro")
            updateScoop()
        }
        
    }

    // Cancel Button Action
    @IBAction func cancelAction(_ sender: AnyObject) {
        
        print("Apretaron boton para cancelar")
        dismissView()
        
    }

}

// MARK: - Utils

extension ScoopDetailsViewController {
    
    // Dismiss the view
    func dismissView() {
        
        let storyBoardL = UIStoryboard(name: "Logged", bundle: Bundle.main)
        let vc = storyBoardL.instantiateViewController(withIdentifier: "loggedScene")
        
        //vc.modalTransitionStyle = .flipHorizontal
        
        present(vc, animated: true, completion: nil)
        
    }
    
    /// Update the labels in the view
    func updateLabels() {
        
        if let location = location {
            latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
            longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
        } else if let coordinate = coordinate {
            latitudeLabel.text = String(format: "%.8f", coordinate.latitude)
            longitudeLabel.text = String(format: "%.8f", coordinate.longitude)
        } else {
            latitudeLabel.text = ""
            longitudeLabel.text = ""
        }
        
        if let _ = scoopToEdit {
            scoopText.text = scoopToEdit?["scooptext"] as? String
            titleText.text = scoopToEdit?["title"] as? String
            latitudeLabel.text = String(format: "%.8f", (scoopToEdit?["latitude"]! as? Double)!)
            longitudeLabel.text = String(format: "%.8f", (scoopToEdit?["longitude"]! as? Double)!)
        }
        
    }
    
    func showImage(_ image: UIImage) {
        photoImage.image = image
        photoImage.isHidden = false
        photoImage.frame = CGRect(x: 10, y: 10, width: 260, height: 260)
        addPhotoLabel.isHidden = true
    }
    
    func addNewScoop() {
        
        // Creamos y subimos la foto al storage
        let data = UIImagePNGRepresentation(image!)
        print(sas!)
        uploadPhotoToAzureStorageWithData(data!, usingSAS: sas!)
        
        // Subimos los datos del scoop a la tabla
        let tableMS =  client?.table(withName: "Scoops")
        
        let scoop = ["title": titleText.text!, "imageURL": blobName! ,"scooptext": scoopText.text!, "author": authorName!, "latitude": NSNumber(value: (location?.coordinate.latitude)!) , "longitude": NSNumber(value: (location?.coordinate.longitude)!)] as [String : Any]
        
        tableMS?.insert(scoop) { (result, error) in
            
            if let _ = error {
                print("Error al insertar registro: \(error)")
                return
            }
            
            print("se inserto registro con exito: \(result)")
            
            DispatchQueue.main.async {
                self.dismissView()
            }
        }
    }
    
    func updateScoop() {
        
        let tableMS = client?.table(withName: "Scoops")
        
        if let newItem = (scoopToEdit! as NSDictionary).mutableCopy() as? NSMutableDictionary {
            newItem["title"] = titleText.text!
            newItem["scooptext"] = scoopText.text!
            if publishSwitch.isOn {
                newItem["status"] = "pending"
            }
            
            tableMS?.update(newItem as [NSObject: AnyObject], completion: { (result, error) in
                
                if let _ = error {
                    print("Error al hacer update: \(error)")
                }
                
                if let _ = result {
                    print("se actualizo el registro con exito: \(result)")
                }
                
                DispatchQueue.main.async {
                    self.dismissView()
                }
                
            })
            
        }
        
        
        
        
        
    }

    func loadScoop(_ id: String) {
        
        let tableMS =  client?.table(withName: "Scoops")
        
        let predicate = NSPredicate(format: "id == %@", id)
        
        let query = tableMS?.query(with: predicate)
        
        query?.selectFields = ["id","title", "scooptext", "latitude", "longitude", "status"]
        
        query?.read { (results, error) in
            
            if let _ = error {
                print("Error al leer la table: \(error)")
                return
            }
            
            if let _ = results {
                self.scoopToEdit = results?.items?[0] as! ScoopRecord?
            }
        }
    }
    
    func uploadPhotoToAzureStorageWithData(_ data: Data, usingSAS sas: String) {
        
        do {
            
            let credentials = AZSStorageCredentials(sasToken: sas, accountName: "practicascoops")
            
            let account = try AZSCloudStorageAccount(credentials: credentials, useHttps: true)
            
            let client = account.getBlobClient()
            
            let conti = client?.containerReference(fromName: "scoops")
            
            let theBlob = conti?.blockBlobReference(fromName: blobName!)
            
            theBlob?.upload(from: data, completionHandler: { (error) in
                
                if error != nil {
                    print(error)
                    return
                }
                //self.readAllBlobs()
                
            })
            
        } catch let ex {
            print(ex)
        }
        
    }
    
    func getNameFromFacebook() {
        
        
        
    }
    
}


// MARK: - Core Location methods

extension ScoopDetailsViewController: CLLocationManagerDelegate {
    
    func startLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
            
            timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(ScoopDetailsViewController.didTimeOut), userInfo: nil, repeats: false)
            
        }
    }
    
    func stopLocationManager() {
        if updatingLocation {
            if let timer = timer {
                timer.invalidate()
            }
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
        }
    }
    
    // Show a alert if the Location Services is disabled in the phone
    func showLocationServicesDeniedAlert() {
        let alert = UIAlertController(title: "Location Services Disabled ", message: "Please enable location services for this app in Settings.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    func didTimeOut() {
        if location == nil {
            stopLocationManager()
            lastLocationError = NSError(domain: "MyLocationsErrorDomain", code: 1, userInfo: nil)
            updateLabels()
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        let code = (error as NSError).code
        if code == CLError.Code.locationUnknown.rawValue {
            return
        }
        
        lastLocationError = error as NSError?
        
        stopLocationManager()
        updateLabels()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        
        // Check if the time was too long
        if newLocation.timestamp.timeIntervalSinceNow < -5 {
            return
        }
        // Check if accuracy is less than zero (invalid) so we ignored it
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        
        var distance = CLLocationDistance(DBL_MAX)
        if let location = location {
            distance = newLocation.distance(from: location)
        }
        
        if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
            
            lastLocationError = nil
            location = newLocation
            updateLabels()
            
            if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
                stopLocationManager()
            }
        } else if distance < 1.0 {
            
            let timeInterval = newLocation.timestamp.timeIntervalSince(location!.timestamp)
            
            if timeInterval > 10 {
                stopLocationManager()
                updateLabels()
            }
            
        }
    }
    
    
    /// Start the location services to upload the labels of location
    func getLocation() {
        // Check the status of authorization
        let authStatus = CLLocationManager.authorizationStatus()
        
        // if the stauts is not determined, ask permission
        if authStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        
        // Show a Alert if the authorization status is Denied or restricted
        if authStatus == .denied || authStatus == .restricted {
            showLocationServicesDeniedAlert()
            return
        }
        
        startLocationManager()
    }
    
}

// MARK: - UITableViewDelegate

extension ScoopDetailsViewController {
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if ((indexPath as NSIndexPath).section == 3 ) {
            return nil
        } else {
            return indexPath
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).section == 0 || (indexPath as NSIndexPath).section == 1 {
            scoopText.becomeFirstResponder()
        } else if (indexPath as NSIndexPath).section == 2 && (indexPath as NSIndexPath).row == 0 {
            tableView.deselectRow(at: indexPath, animated: true)
            pickPhoto()
        }
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        switch ((indexPath as NSIndexPath).section, (indexPath as NSIndexPath).row) {
        case (1,0):
            return 88
        case (2,_):
            return photoImage.isHidden ? 44 : 280
        default:
            return 44
        }
    }
}

// MARK: - UIImagePickerControllerDelegate & Camera methods

extension ScoopDetailsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func pickPhoto() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            showPhotoMenu()
        } else {
            choosePhotoFromLibrary()
        }
    }
    
    func showPhotoMenu() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let takePhotoAction = UIAlertAction(title: "Take Photo", style: .default, handler: { _ in self.takePhotoWithCamera() })
        let chooseFromLibrary = UIAlertAction(title: "Choose From Library", style: .default, handler: { _ in self.choosePhotoFromLibrary() })
        
        alertController.addAction(cancelAction)
        alertController.addAction(takePhotoAction)
        alertController.addAction(chooseFromLibrary)
        
        alertController.popoverPresentationController?.sourceView = view
        alertController.popoverPresentationController?.sourceRect = view.frame
        
        present(alertController, animated: true, completion: nil)
    }
    
    func takePhotoWithCamera() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    func choosePhotoFromLibrary() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        
        imagePicker.modalPresentationStyle = .popover
        
        imagePicker.popoverPresentationController?.sourceView = view
        imagePicker.popoverPresentationController?.sourceRect = view.frame
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let rawImage = info[UIImagePickerControllerEditedImage] as? UIImage
        
        blobName = UUID().uuidString
        
        let parameters = ["blobName": blobName]
        
        DispatchQueue.global(qos: .default).async {
            self.image = rawImage?.resizedImageWithContentMode(.scaleAspectFit, bounds: CGSize(width: 260, height: 260), interpolationQuality: .medium)
            
            DispatchQueue.main.async {
                if let image = self.image {
                    //print("Tengo imagen")
                    self.showImage(image)
                    self.client?.invokeAPI("getURLForBlobInContainer", body: nil, httpMethod: "GET", parameters: parameters, headers: nil, completion: { (result, response, error) in
                        
                        if let _ = error {
                            print("error al invocar la api: \(error)")
                            return
                        }
                      
                        if let _ = result {
                            
                            let json = result as! NSDictionary
                            self.sas = json["token"] as? String
                            
                        }
                        
                        //print(result as! NSDictionary)
                        
                    })
                }
                
                self.tableView.reloadData()
            }
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
}




