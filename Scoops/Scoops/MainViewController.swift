//
//  MainViewController.swift
//  Scoops
//
//  Created by Charles Moncada on 22/10/16.
//  Copyright © 2016 Charles Moncada. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - IBAction
    
    @IBAction func userLoggedAction(_ sender: AnyObject) {
    
        print("Apretaron boton de usuario Logeado")
        
        let storyBoardL = UIStoryboard(name: "Logged", bundle: Bundle.main)
        let vc = storyBoardL.instantiateViewController(withIdentifier: "loggedScene")
        
        present(vc, animated: true, completion: nil)
        
    }

    @IBAction func userAnonymousAction(_ sender: AnyObject) {
    
        print("Apretaron boton de usuario Anonimo")
        
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
