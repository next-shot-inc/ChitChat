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
    @IBOutlet weak var confirmPassordField : UITextField!
    @IBOutlet weak var confirmPasswordLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginButton.isEnabled = false
        
        telephone.delegate = self
        userName.delegate = self
        passwordField.delegate = self
        confirmPassordField.delegate = self
        
        let tapper = UITapGestureRecognizer(target: self, action:#selector(endEditing))
        tapper.cancelsTouchesInView = false
        view.addGestureRecognizer(tapper)
        
        navigationController?.navigationItem.backBarButtonItem?.isEnabled = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        errorLabel.text = ""
        
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
                
                // See if the user already exist in the DB.
                // If it does, hide the confirm password UI elements
                if( userInfo != nil ) {
                    model.getUser(phoneNumber: userInfo!.telephoneNumber!, completion: { (user) in
                        if( user != nil ) {
                            if( user!.passKey != nil ) {
                                DispatchQueue.main.async(execute: {
                                    self.confirmPassordField.isHidden = true
                                    self.confirmPasswordLabel.isHidden = true
                                })
                            }
                        }
                    })
                }
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
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
        
        // Store password in KeyChain
        let keychain = KeychainSwift()
        keychain.synchronizable = true
        keychain.set(passwordField.text!, forKey: "password")
        
        // Pop this controller
        _ = navigationController?.popViewController(animated: true)
    }
    
    // TextField delegate for all text fields in the view
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Test textfields.
        loginButton.isEnabled = (!userName.text!.isEmpty) && (!telephone.text!.isEmpty) && (!passwordField.text!.isEmpty) && (confirmPassordField.isHidden == true || (!confirmPassordField.text!.isEmpty) && (confirmPassordField.text! == passwordField.text!))
        
        if( loginButton.isEnabled ) {
            errorLabel.text = ""
        } else {
            if( confirmPassordField.text! != passwordField.text! ) {
                errorLabel.text = "password mismatch"
            }
        }
        
        // Test validity of phone number
        let phoneNumberKit = PhoneNumberKit()
        do {
            try _ = phoneNumberKit.parse(telephone.text!)
        } catch let error as PhoneNumberError {
            errorLabel.text = error.errorDescription
            loginButton.isEnabled = false
        } catch {
            print("something went wrong")
        }
        
        // Get User and if exist already hide password confirmation and enable login.
        model.getUser(phoneNumber: telephone.text!, completion: { (user) in
            if( user != nil && user!.passKey != nil ) {
                DispatchQueue.main.async(execute: {
                    self.confirmPassordField.isHidden = true
                    self.confirmPasswordLabel.isHidden = true
                    self.loginButton.isEnabled = (!self.userName.text!.isEmpty) && (!self.passwordField.text!.isEmpty)
                })
            }
        })
    }
    
    func endEditing() {
        telephone.resignFirstResponder()
        userName.resignFirstResponder()
        passwordField.resignFirstResponder()
        confirmPassordField.resignFirstResponder()
    }
}
