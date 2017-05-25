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
    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmPassordField : UITextField!
    @IBOutlet weak var confirmPasswordLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var recoveryLabel: UILabel!
    @IBOutlet weak var recoveryQuestionLabel: UILabel!
    @IBOutlet weak var recoveryQuestionField: UITextField!
    @IBOutlet weak var recoveryAnswerLabel: UILabel!
    @IBOutlet weak var recoveryAnswerField: UITextField!
    @IBOutlet weak var forgottenPasswordButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var user: User?
    var usedRecovery = false
    
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
        
        // Keyboard handling for the message text area
        NotificationCenter.default.addObserver(self, selector: #selector(LoginViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(LoginViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = true
        errorLabel.text = ""
        forgottenPasswordButton.isHidden = true
        
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
                        if( user != nil && user!.passKey != nil ) {
                                DispatchQueue.main.async(execute: {
                                    self.user = user
                                    self.confirmPassordField.isHidden = true
                                    self.confirmPasswordLabel.isHidden = true
                                    if( user!.recoveryQuestion != nil ) {
                                        self.recoveryLabel.isHidden = true
                                        self.recoveryAnswerLabel.isHidden = true
                                        self.recoveryAnswerField.isHidden = true
                                        self.recoveryQuestionLabel.isHidden = true
                                        self.recoveryQuestionField.isHidden = true
                                        self.forgottenPasswordButton.isHidden = false
                                        self.recoveryQuestionField.isEnabled = false
                                        self.recoveryQuestionField.text = user!.recoveryQuestion
                                    }
                                })
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
        
        if( user == nil ) {
            saveUser(userInfo: userInfo!)
        } else {
            if( usedRecovery ) {
                if( LoginFunctions.verify(user: user!, recoveryAnswer: recoveryAnswerField.text!) ) {
                    saveUser(userInfo: userInfo!)
                } else {
                    let alertCtrler = UIAlertController(
                        title: "Invalid recovery answer",
                        message: "Please retry",
                        preferredStyle: .alert
                    )
                    alertCtrler.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alertCtrler, animated: true, completion: nil)
                }
            } else {
                if( LoginFunctions.verify(user: user!, password: passwordField.text!) ) {
                    if( user!.recoveryQuestion == nil ) {
                        saveUser(userInfo: userInfo!)
                    } else {
                        done()
                    }
                } else {
                    let alertCtrler = UIAlertController(
                        title: "Invalid password",
                        message: "Please retry",
                        preferredStyle: .alert
                    )
                    alertCtrler.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alertCtrler, animated: true, completion: nil)
                }
            }
        }
    }
    
    func done() {
        // Store password in KeyChain
        let keychain = KeychainSwift()
        keychain.synchronizable = true
        keychain.set(passwordField.text!, forKey: "password")
        
        // Pop this controller
        _ = navigationController?.popViewController(animated: true)
        navigationController?.isNavigationBarHidden = false
    }
    
    // TextField delegate for all text fields in the view
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Test textfields.
        loginButton.isEnabled = (!userName.text!.isEmpty) && (!telephone.text!.isEmpty) && (!passwordField.text!.isEmpty) && (confirmPassordField.isHidden == true || (!confirmPassordField.text!.isEmpty) && (confirmPassordField.text! == passwordField.text!) && !recoveryQuestionField.text!.isEmpty && !recoveryAnswerField.text!.isEmpty)
        
        if( loginButton.isEnabled ) {
            errorLabel.text = ""
        } else {
            if( confirmPassordField.text! != passwordField.text! ) {
                errorLabel.text = "password mismatch"
            }
        }
        
        if( user == nil ) {
            // Test validity of phone number
            let phoneNumberKit = PhoneNumberKit()
            do {
                let phoneNumber = try phoneNumberKit.parse(telephone.text!)
                let telephoneNumber = phoneNumberKit.format(phoneNumber, toType: .international)
                
                // Get User and if exist already hide password confirmation and enable login.
                model.getUser(phoneNumber: telephoneNumber, completion: { (user) in
                    if( user != nil ) {
                        DispatchQueue.main.async(execute: {
                            self.user = user
                            if( user!.passKey != nil ) {
                                self.confirmPassordField.isHidden = true
                                self.confirmPasswordLabel.isHidden = true
                            }
                            if( user!.recoveryQuestion != nil ) {
                               self.recoveryLabel.isHidden = true
                               self.recoveryAnswerLabel.isHidden = true
                               self.recoveryAnswerField.isHidden = true
                               self.recoveryQuestionLabel.isHidden = true
                               self.recoveryQuestionField.isHidden = true
                               self.forgottenPasswordButton.isHidden = false
                               self.recoveryQuestionField.text = user!.recoveryQuestion
                               self.recoveryQuestionField.isEnabled = false
                            }
                            self.userName.text = user!.label
                            self.loginButton.isEnabled = (!self.userName.text!.isEmpty) && (!self.passwordField.text!.isEmpty) &&
                                (self.recoveryAnswerField.isHidden == true || !self.recoveryAnswerField.text!.isEmpty )
                        })
                    }
                })
                
                errorLabel.text = "Will use " + telephoneNumber
                
            } catch let error as PhoneNumberError {
                errorLabel.text = error.errorDescription
                loginButton.isEnabled = false
                
                // To use old test accounts!
                model.getUser(phoneNumber: telephone.text!, completion: { (user) in
                    if( user != nil && user!.passKey != nil ) {
                        DispatchQueue.main.async(execute: {
                            self.user = user
                            self.confirmPassordField.isHidden = true
                            self.confirmPasswordLabel.isHidden = true
                            self.userName.text = user!.label
                            self.loginButton.isEnabled = (!self.userName.text!.isEmpty) && (!self.passwordField.text!.isEmpty)
                        })
                    }
                })
                
                
            } catch {
                print("something went wrong")
            }
        }
    }
    
    @IBAction func forgotPasswd(_ sender: Any) {
        self.recoveryLabel.isHidden = false
        self.recoveryAnswerLabel.isHidden = false
        self.recoveryLabel.text = "Please provide recovery information:"
        self.recoveryAnswerField.isHidden = false
        self.recoveryQuestionLabel.isHidden = false
        self.recoveryQuestionField.isHidden = false
        self.confirmPasswordLabel.isHidden = false
        self.confirmPassordField.isHidden = false
        self.passwordLabel.text = "Please reenter password information:"
        
        usedRecovery = true
    }
    
    func endEditing() {
        telephone.resignFirstResponder()
        userName.resignFirstResponder()
        passwordField.resignFirstResponder()
        confirmPassordField.resignFirstResponder()
        recoveryQuestionField.resignFirstResponder()
        recoveryAnswerField.resignFirstResponder()
    }
    
    // Keyboard handling
    func keyboardWillHide(_ sender: Notification) {
        if let userInfo = (sender as NSNotification).userInfo {
            if let _ = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height {
                //key point 0,
                self.bottomConstraint.constant = 10
                
                //textViewBottomConstraint.constant = keyboardHeight
                UIView.animate(withDuration: 0.25, animations: { () -> Void in
                    self.view.layoutIfNeeded()
                })
            }
        }
    }
    func keyboardWillShow(_ sender: Notification) {
        if let userInfo = (sender as NSNotification).userInfo {
            if let keyboardHeight = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height {
                self.bottomConstraint.constant = keyboardHeight
                UIView.animate(withDuration: 0.25, animations: { () -> Void in
                    self.view.layoutIfNeeded()
                })
            }
        }
    }

    
    func saveUser(userInfo: UserInfo) {
        if( user == nil ) {
            // Create user. Store passkey into DB
            let user0 = User(
                id: RecordId(), label: userInfo.name!, phoneNumber: userInfo.telephoneNumber!
            )
            user0.recoveryQuestion = self.recoveryQuestionField.text!
            
            let augmented_password = user0.id.id + self.passwordField.text!
            user0.passKey = LoginFunctions.convertToKey(string: augmented_password)
            
            let recoveryAnswer = self.recoveryAnswerField.text!.lowercased()
            user0.recoveryKey = LoginFunctions.convertToKey(string: recoveryAnswer)
            
            model.saveUser(user: user0, completion: { status in
                DispatchQueue.main.async(execute: {
                    if( !status ) {
                        let alertCtrler = UIAlertController(
                            title: "Could not create user - Must be logged into ICloud",
                            message: "Please login to ICloud and retry",
                            preferredStyle: .alert
                        )
                        alertCtrler.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alertCtrler, animated: true, completion: nil)

                    } else {
                       self.done()
                    }
                })
            })
            
            model.getGroupInvitations(to_user: userInfo.telephoneNumber!, completion: { (invitations, groups) -> () in
                // implicitely accept all invitations
                for g in groups {
                    model.addUserToGroup(group: g, user: user0)
                }
                // Mark the invitation has accepted.
                for invitation in invitations {
                    invitation.accepted = true
                    model.saveUserInvitation(userInvitation: invitation)
                }
            })
        } else {
            var modified = false
            let augmented_password = user!.id.id + self.passwordField.text!
            if( user!.passKey == nil || user!.passKey!.isEmpty ) {
                // For users created before password was necessary.
                user!.passKey! = LoginFunctions.convertToKey(string: augmented_password)
                modified = true
            }
            
            if( usedRecovery ) {
                // Overwrite password
                let augmented_password = user!.id.id + self.passwordField.text!
                user!.passKey = LoginFunctions.convertToKey(string: augmented_password)
                modified = true
            }
            
            if( user!.recoveryQuestion == nil && self.recoveryQuestionField.text != nil ) {
                // For users created before recovery question existed.
                user!.recoveryQuestion = self.recoveryQuestionField.text!
                let recoveryAnswer = self.recoveryAnswerField.text!.lowercased()
                user!.recoveryKey = LoginFunctions.convertToKey(string: recoveryAnswer)
                modified = true
            }
            
            if( modified ) {
                model.saveUser(user: user!, completion: { status in
                    DispatchQueue.main.async(execute: {
                        self.done()
                    })
                })
            } else {
                done()
            }
        }
    }
}

class LoginFunctions {
    // Code duplicated from Model.getUserInfo()
    private class func hash(string: String) -> Int {
        var h = 5381
        for v in string.unicodeScalars {
            let v = v.value
            h = ((h << 5) &+ h) &+ Int(v)
        }
        return h
    }
    private class func hexKey(value: Int) -> String {
        var number = value
        let data = NSData(bytes: &number, length: MemoryLayout<Int>.size)
        return data.base64EncodedString(options: [])
    }
    
    class func convertToKey(string: String) -> String {
        return hexKey(value: hash(string: string))
    }
    
    class func verify(user: User, password: String) -> Bool {
        let augmented_password = user.id.id + password
        let passKey = hexKey(value: hash(string: augmented_password))
        return passKey == user.passKey
    }
    
    class func verify(user: User, recoveryAnswer: String) -> Bool {
        let lowerCase = recoveryAnswer.lowercased()
        let recoveryKey = hexKey(value: hash(string: lowerCase))
        return recoveryKey == user.recoveryKey!
    }

}
