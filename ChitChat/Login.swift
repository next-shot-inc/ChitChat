//
//  Login.swift
//  ChitChat
//
//  Created by next-shot on 3/8/17.
//  Copyright © 2017 next-shot. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class LoginViewController : UIViewController, UITextFieldDelegate {
    @IBOutlet weak var telephone: UITextField!
    @IBOutlet weak var userName: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginButton.applyGradient(withColours: [UIColor.white, UIColor.lightGray], gradientOrientation: .vertical)
        loginButton.isEnabled = false
        
        telephone.delegate = self
        userName.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.        
    }
    
    @IBAction func doLogin(_ sender: Any) {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
    
        // Store User Information inside Application Core Data
        var userInfo : UserInfo?
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "UserInfo")
        do {
            let entities = try managedContext.fetch(fetchRequest)
            if( entities.count >= 1 ) {
                userInfo = entities[0] as? UserInfo
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }

        if( userInfo == nil ) {
            let entity = NSEntityDescription.insertNewObject(forEntityName: "UserInfo", into: managedContext)
            userInfo = entity as? UserInfo
        }
        
        userInfo?.name = userName.text!
        userInfo?.telephoneNumber = telephone.text!
        
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        
        // Pop this controller
        _ = navigationController?.popViewController(animated: true)
    }
    
    // TextField delegate
    func textFieldDidEndEditing(_ textField: UITextField) {
        loginButton.isEnabled = !(userName.text?.isEmpty)! && (telephone.text?.isEmpty)!
    }
}
