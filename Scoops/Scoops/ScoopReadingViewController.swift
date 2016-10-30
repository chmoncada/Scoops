//
//  ScoopReadingViewController.swift
//  Scoops
//
//  Created by Charles Moncada on 30/10/16.
//  Copyright © 2016 Charles Moncada. All rights reserved.
//

import UIKit

class ScoopReadingViewController: UIViewController {

    var id: String? {
        didSet {
            print("debo cargar el objecto con id: \(id!)")
            
        }
    }
    
    var client: MSClient?
    var scoopToRead: ScoopRecord? {
        didSet {
            updateLabels()
        }
    }
    
    var valueNumber: Int?
    
    @IBOutlet weak var titleText: UILabel!
    
    @IBOutlet weak var photo: UIImageView!
    
    @IBOutlet weak var scoopText: UITextView!
    
    @IBOutlet weak var valueLabel: UILabel!
    
    @IBAction func valueSliderChanged(_ sender: UISlider) {
        let interval = 1
        valueNumber = Int(sender.value / Float(interval))
        sender.value = Float(valueNumber!)
        valueLabel.text = "\(valueNumber!)"

    }
    
    
    // Manda la valoracion a Backend y recalcula la valoracion promedio
    @IBAction func updateValueAction(_ sender: UIButton) {
        
        print("recalculado valoracion del scoop en Backend....")
        let parameters = ["idScoop": id!, "score": "\(valueNumber!)"]
        
        client?.invokeAPI("scoreScoop", body: nil, httpMethod: "GET", parameters: parameters, headers: nil, completion: { (result, response, error) in
            print("listo el average")
        })
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let _ = id {
            loadScoop(id!)
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
// MARK: - Utils
    
    func updateLabels() {
        
        if let _ = id {
            
            titleText.text = scoopToRead?["title"] as? String
            scoopText.text = scoopToRead?["scooptext"] as? String
            
            // carga imagen del storage
            let photoImage = scoopToRead?["imageURL"] as? String
            
            if let photoImage = photoImage {
                
                let urlString = "https://practicascoops.blob.core.windows.net/scoops/\(photoImage)"
                let url = NSURL(string: urlString)
                do {
                    let imageData = try NSData(contentsOf: url as! URL, options: NSData.ReadingOptions())
                    photo.image = UIImage(data: imageData as Data)
                } catch {
                    print(error)
                }
                
            } else {
                photo.image = UIImage(named: "no-image-available")
            }
            
            
            
        }
        
    }

    func loadScoop(_ id: String) {
        
        let tableMS =  client?.table(withName: "Scoops")
        
        let predicate = NSPredicate(format: "id == %@", id)
        
        let query = tableMS?.query(with: predicate)
        
        query?.selectFields = ["id","title", "scooptext", "imageURL"]
        
        query?.read { (results, error) in
            
            if let _ = error {
                print("Error al leer la tabla: \(error)")
                return
            }
            
            if let _ = results {
                self.scoopToRead = results?.items?[0] as! ScoopRecord?
            }
        }
    }
    
}
