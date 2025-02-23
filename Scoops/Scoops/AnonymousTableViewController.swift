//
//  AnonymousTableViewController.swift
//  Scoops
//
//  Created by Charles Moncada on 29/10/16.
//  Copyright © 2016 Charles Moncada. All rights reserved.
//

import UIKit

class AnonymousTableViewController: UITableViewController {

    var client: MSClient = MSClient(applicationURL: URL(string: "https://practicascoops.azurewebsites.net")!)
    
    var model: [Dictionary<String,AnyObject>]? = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        readAllItemsInTable()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if (model?.isEmpty)! {
            return 0
        }
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (model?.isEmpty)! {
            return 0
        }
        
        return (model?.count)!
    }
    
    // MARK: - IBAction
    
    @IBAction func backAction(_ sender: AnyObject) {
        
        print("Apretaron boton para ir a vista inicial")
            
        let storyBoardL = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc = storyBoardL.instantiateViewController(withIdentifier: "mainScene")
        
        present(vc, animated: true, completion: nil)
        
    }
    
    // MARK: - Utils
    
    func readAllItemsInTable() {
        
        
        let tableMS =  client.table(withName: "Scoops")
        
        let predicate = NSPredicate(format: "status == 'published'")
        //let predicate = NSPredicate(format: "authorID == %@", (client.currentUser?.userId!)!)
        
        let query = tableMS.query(with: predicate)
        
        query.order(byAscending: "createdAt")
        
        query.selectFields = ["id","title", "author", "imageURL"]
        
        query.read { (results, error) in
            
            if let _ = error {
                print("Error al leer la table: \(error)")
                return
            }
            
            print("lei algo")
            if let items = results {
                
                for item in items.items! {
                    self.model?.append(item as! ScoopRecord)
                }
                //print(items.items)
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        
        
    }
 
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "readingScoop", for: indexPath)

        // Configure the cell...
        let item = model?[indexPath.row]
        
        cell.textLabel?.text = item?["title"] as? String
        cell.detailTextLabel?.text = item?["author"] as? String
        
        // carga imagen del storage
        let photo = item?["imageURL"] as? String
        
        if let photo = photo {
            
            let urlString = "https://practicascoops.blob.core.windows.net/scoops/\(photo)"
            let url = NSURL(string: urlString)
            do {
                let imageData = try NSData(contentsOf: url as! URL, options: NSData.ReadingOptions())
                cell.imageView?.image = UIImage(data: imageData as Data)
            } catch {
                print(error)
            }
            
        } else {
            cell.imageView?.image = UIImage(named: "no-image-available")
        }

        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "readScoop" {
            let controller = segue.destination as! ScoopReadingViewController
            
            if let indexPath = tableView.indexPath(for: sender as! UITableViewCell) {
                let item = model?[indexPath.row]
                //print(item?["id"])
                controller.id = item?["id"] as! String?
                //controller.title = "Scoop Details"
                controller.client = client
            }
            
        }
        
    }

}
