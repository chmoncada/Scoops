//
//  LoggedTableViewController.swift
//  Scoops
//
//  Created by Charles Moncada on 22/10/16.
//  Copyright © 2016 Charles Moncada. All rights reserved.
//

import UIKit

typealias ScoopRecord = Dictionary<String, AnyObject>

class LoggedTableViewController: UITableViewController {

    var client: MSClient = MSClient(applicationURL: URL(string: "https://practicascoops.azurewebsites.net")!)
    
    var loggedUser: String?
    var token: String?
    
    @IBOutlet weak var tableType: UISegmentedControl!
    
    var predicate: NSPredicate?
    
    var model: [Dictionary<String,AnyObject>]? = []
    
    fileprivate let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    // MARK: lifecycle
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadAuthInfo()
        
        if let _ = client.currentUser {
            print("ya tengo usuario logeado")
            readAllItemsInTable()
        } else {
            doLoginInFacebook()
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: IBAction
    
    @IBAction func tableTypeChanged(_ sender: UISegmentedControl) {
        
        switch tableType.selectedSegmentIndex {
        case 0:
            predicate = NSPredicate(format: "authorID == %@ AND status == 'No Publicado'", (client.currentUser?.userId!)!)
            model = []
            readAllItemsInTable()
        case 1:
            predicate = NSPredicate(format: "authorID == %@ AND status == 'pending'", (client.currentUser?.userId!)!)
            model = []
            readAllItemsInTable()
        case 2:
            predicate = NSPredicate(format: "authorID == %@ AND status == 'published'", (client.currentUser?.userId!)!)
            model = []
            readAllItemsInTable()
        default:
            break
        }
        
    }
    
    @IBAction func AddNewScoopAction(_ sender: AnyObject) {
    
        print("Apretaron boton para añadir scoop nuevo")
        
        let storyBoardL = UIStoryboard(name: "ScoopDetails", bundle: Bundle.main)
        let vc = storyBoardL.instantiateViewController(withIdentifier: "scoopDetailsScene")
        
        present(vc, animated: true, completion: nil)
    
    }
    
    @IBAction func backAction(_ sender: AnyObject) {
    
        print("Apretaron boton para ir a vista inicial")
        client.currentUser = nil
        removeAuthInfo()
        
        let storyBoardL = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc = storyBoardL.instantiateViewController(withIdentifier: "mainScene")
        
        present(vc, animated: true, completion: nil)
        
    }
    
    // MARK: - Utils
    
    func readAllItemsInTable() {
        
        let tableMS =  client.table(withName: "Scoops")
        
        if predicate != nil {
            print("usare el nuevo predicate")
        } else {
            predicate = NSPredicate(format: "authorID == %@ AND status == 'No Publicado'", (client.currentUser?.userId!)!)
        }
        
        let query = tableMS.query(with: predicate!)
        
        query.order(byAscending: "createdAt")
        
        query.selectFields = ["id","title", "status", "imageURL"]
        
        query.read { (results, error) in
            
            if let _ = error {
                print("Error al leer la table: \(error)")
                return
            }
            
            //print("lei algo")
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
    
    func formatDate(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    func doLoginInFacebook() {
        client.login(withProvider: "facebook", parameters: nil, controller: self, animated: true) { (user, error) in
            
            if let _ = error {
                print("Error al hacer login: \(error)")
                return
            }
            
            if let _ = user {
                self.readAllItemsInTable()
                print(user?.mobileServiceAuthenticationToken)
                
                //print(user?.userId)
                print("client current user: \(self.client.currentUser!.userId)")
                self.saveAuthInfo(user!)
            }
            
        }
    }
    
    func saveAuthInfo(_ user:MSUser) {
        UserDefaults.standard.set(user.userId!, forKey: "userID")
        UserDefaults.standard.set(user.mobileServiceAuthenticationToken!, forKey: "token")
        UserDefaults.standard.synchronize()
    }
    
    func loadAuthInfo() {
        
        loggedUser = UserDefaults.standard.object(forKey: "userID") as? String
        token = UserDefaults.standard.object(forKey: "token") as? String
        
        if let _ = loggedUser {
            self.client.currentUser = MSUser(userId: loggedUser)
            self.client.currentUser?.mobileServiceAuthenticationToken = token
        }
        
    }
    
    func removeAuthInfo() {
        
        UserDefaults.standard.removeObject(forKey: "userID")
        UserDefaults.standard.removeObject(forKey: "token")
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

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "authorScoops", for: indexPath)

        // Configure the cell...
        let item = model?[indexPath.row]
        
        cell.textLabel?.text = item?["title"] as! String?
        //let date = item?["createdAt"] as! NSDate
        //cell.detailTextLabel?.text = formatDate(date as Date)
        cell.detailTextLabel?.text = item?["status"] as! String?
        
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

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showScoopDetails" {
            let controller = segue.destination as! ScoopDetailsViewController
            
            if let indexPath = tableView.indexPath(for: sender as! UITableViewCell) {
                let item = model?[indexPath.row]
                //print(item?["id"])
                controller.id = item?["id"] as! String?
                controller.title = "Scoop Details"
            }
            controller.client = client
        }
        
        if segue.identifier == "addNewScoop" {
            let controller = segue.destination as! ScoopDetailsViewController
            
            controller.client = client
        }

        
    }


}
