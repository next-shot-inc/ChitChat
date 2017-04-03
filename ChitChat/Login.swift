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
import PhoneNumberKit
import KeychainSwift

class LoginViewController : UIViewController, UITextFieldDelegate {
    @IBOutlet weak var telephone: UITextField!
    @IBOutlet weak var userName: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var passwordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginButton.isEnabled = false
        
        telephone.delegate = self
        userName.delegate = self
        passwordField.delegate = self
        
        let tapper = UITapGestureRecognizer(target: self, action:#selector(endEditing))
        tapper.cancelsTouchesInView = false
        view.addGestureRecognizer(tapper)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Fetch app data for users that had used the app before but did not provide all information.
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "UserInfo")
        do {
            let entities = try managedContext.fetch(fetchRequest)
            if( entities.count >= 1 ) {
                let userInfo = entities[0] as? UserInfo
                telephone.text = userInfo?.telephoneNumber
                userName.text = userInfo?.name
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        // Wait until the bounds are ok
        loginButton.applyGradient(withColours: [UIColor.white, UIColor.lightGray], gradientOrientation: .vertical)
        loginButton.setNeedsDisplay()
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
        do {
            let phoneNumberKit = PhoneNumberKit()
            let phoneNumber = try phoneNumberKit.parse(telephone.text!)
            userInfo?.telephoneNumber = phoneNumberKit.format(phoneNumber, toType: .international)
        } catch {
            userInfo?.telephoneNumber = telephone.text!
        }
        
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        
        let keychain = KeychainSwift()
        keychain.synchronizable = true
        keychain.set(passwordField.text!, forKey: "password")
        
        // Pop this controller
        _ = navigationController?.popViewController(animated: true)
    }
    
    // TextField delegate
    func textFieldDidEndEditing(_ textField: UITextField) {
        loginButton.isEnabled = (!userName.text!.isEmpty) && (!telephone.text!.isEmpty) && (!passwordField.text!.isEmpty)
    }
    
    func endEditing() {
        telephone.resignFirstResponder()
        userName.resignFirstResponder()
        passwordField.resignFirstResponder()
    }
}
