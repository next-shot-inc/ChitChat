//
//  ContactsController.swift
//  ChitChat
//
//  Created by next-shot on 3/8/17.
//  Copyright © 2017 next-shot. All rights reserved.
//

import Foundation
import UIKit
import Contacts
import ContactsUI

class Contact {
    let label : String
    var phoneNumber = String()
    
    init(label: String) {
        self.label =  label
    }
}

class ContactCell : UITableViewCell {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var checkButton: UIButton!
    @IBOutlet weak var phoneNumber: UILabel!
}

class ContactData : NSObject, UITableViewDataSource {
    var contacts = [Contact]()
    
    override init() {
    }
    
    func update() {
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell") as! ContactCell
        
        let contact = contacts[indexPath.row]
        cell.label.text = contact.label
        cell.phoneNumber.text = contact.phoneNumber
        
        cell.checkButton.setImage(UIImage(named: "checked"), for: .selected)
        cell.checkButton.setImage(UIImage(named: "unchecked"), for: .normal)
        
        cell.checkButton.isSelected = !contact.phoneNumber.isEmpty
        return cell
    }
}

class NewGroupController : UIViewController, CNContactPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    var contactsController: ContactsController?
    
    @IBOutlet weak var groupName: UITextField!
    @IBOutlet weak var contactsView: UITableView!
    @IBOutlet weak var groupIconButton: UIButton!
    @IBOutlet weak var createButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        contactsController = ContactsController()
        contactsController?.tableView = contactsView
        contactsView.delegate = contactsController
        contactsView.dataSource = contactsController?.data
        
        createButton.applyGradient(withColours: [UIColor.white, UIColor.lightGray], gradientOrientation: .vertical)
        createButton.isEnabled = false
        
        groupName.delegate = self
    }
    
    // Contacts Picker (done selected)
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
        let formatter = CNContactFormatter()
        formatter.style = .fullName
        
        contactsController?.data.contacts.removeAll()
        
        for contact in contacts {
            let lc = Contact(label: formatter.string(from: contact) ?? "???")
            
            // Get phone number
            if( contact.phoneNumbers.count == 1 ) {
                lc.phoneNumber = contact.phoneNumbers[0].value.stringValue
            } else {
                for phn in contact.phoneNumbers {
                    if( phn.label?.lowercased(with: nil) == "iphone" ||
                        phn.label?.lowercased(with: nil) == "mobile"
                    ) {
                        lc.phoneNumber = phn.value.stringValue
                    }
                }
                if( lc.phoneNumber.isEmpty && contact.phoneNumbers.count > 0 ) {
                    lc.phoneNumber = contact.phoneNumbers[0].value.stringValue
                }
            }
            contactsController?.data.contacts.append(lc)
        }
        
        contactsController?.tableView.reloadData()
        createButton.isEnabled = !(groupName.text?.isEmpty)! && contacts.count > 0
    }
    
    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        contactsController?.data.contacts.removeAll()
        
        contactsController?.tableView.reloadData()
    }
    
    // Image picker
    func imagePickerController(
        _ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]
    ) {
        let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        groupIconButton.setImage(chosenImage.resize(newSize: CGSize(width: 32, height: 32)), for: .normal)
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // TextField delegate
    func textFieldDidEndEditing(_ textField: UITextField) {
        createButton.isEnabled = !(groupName.text?.isEmpty)! && (contactsController?.data.contacts.count)! > 0
    }
    
    // Display the Contact Picker
    @IBAction func selectMembers(_ sender: Any) {
        let contactPicker = CNContactPickerViewController()
        contactPicker.delegate = self
        self.present(contactPicker, animated: true, completion: nil)
    }
    
    // Display the Image Picker
    @IBAction func selectGroupIcon(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }
    
    @IBAction func createGroup(_ sender: Any) {
        if( groupName.text != nil ) {
            // Creeate Group
            let group = Group(id: RecordId(), name: groupName.text!)
            group.icon = groupIconButton.image(for: .normal)
            model.saveGroup(group: group)
            
            var details = String()
            for c in contactsController!.data.contacts {
                // Create user
                if( !c.phoneNumber.isEmpty ) {
                    model.getUser(phoneNumber: c.phoneNumber, completion: {(user) -> () in
                        if( user == nil ) {
                            let newUser = User(
                              id: RecordId(), label: c.label, phoneNumber: c.phoneNumber
                            )
                            model.saveUser(user: newUser)
                            model.addUserToGroup(group: group, user: newUser)
                        } else {
                            model.addUserToGroup(group: group, user: user!)
                        }
                    })
                }
                
                if( !details.isEmpty ) {
                    details += ", "
                }
                details += c.label
                details += " "
                group.details = details
            }
            
            model.addUserToGroup(group: group, user: model.me())
            
            // Create default thread
            let cthread = ConversationThread(id: RecordId(), group_id: group.id)
            cthread.title = "Main"
            model.saveConversationThread(conversationThread: cthread)
            
            // Create first message
            let message = Message(thread: cthread, user: model.me())
            message.text = "Welcome to ChitChat's group " + groupName.text!
            model.saveMessage(message: message)
            
            // Pop this controller.
            _ = navigationController?.popViewController(animated: true)
        }
    }
}


class ContactsController : UITableViewController {
    var data = ContactData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tableView.dataSource = data
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
}
