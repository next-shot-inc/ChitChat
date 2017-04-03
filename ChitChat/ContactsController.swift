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
import PhoneNumberKit

class Contact {
    let label : String
    var phoneNumber = String()
    var errorPhone = String()
    init(label: String) {
        self.label =  label
    }
    func setNumber(number: String) {
        let phoneNumberKit = PhoneNumberKit()
        do {
           let phoneNumber = try phoneNumberKit.parse(number)
           self.phoneNumber = phoneNumberKit.format(phoneNumber, toType: .international)
        } catch let error {
            let phoneNumberError = error as! PhoneNumberError
            let string = phoneNumberError.localizedDescription
            self.errorPhone = string
        }
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
        if( contact.phoneNumber.isEmpty ) {
            cell.phoneNumber.text = contact.errorPhone
        }
        
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
    @IBOutlet weak var iconGroupView: UIView!
    @IBOutlet weak var selectButton: UIButton!
    
    var existingGroup : Group?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        contactsController = ContactsController()
        contactsController?.tableView = contactsView
        contactsView.delegate = contactsController
        contactsView.dataSource = contactsController?.data
        
        createButton.isEnabled = false
        
        groupName.delegate = self
        
        if( existingGroup != nil ) {
            groupName.text = existingGroup!.name
            groupIconButton.imageView?.image = existingGroup!.icon
            createButton.setTitle("Edit", for: .normal)
            createButton.isEnabled = true
            self.title = "Edit Group"
            
            model.getUsersForGroup(group: existingGroup!, completion: { (users) -> Void in
                for user in users {
                    let lc = Contact(label: user.label!)
                    lc.phoneNumber = user.phoneNumber
                    self.contactsController?.data.contacts.append(lc)
                }
                DispatchQueue.main.async(execute: { () -> Void in
                    self.contactsView.reloadData()
                })
            })

        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Wait until the bounds are ok
        createButton.applyGradient(withColours: [UIColor.white, UIColor.lightGray], gradientOrientation: .vertical)
        createButton.setNeedsDisplay()
        
        selectButton.applyGradient(withColours: [UIColor.white, UIColor.lightGray], gradientOrientation: .vertical)
        selectButton.setNeedsDisplay()
        
        iconGroupView!.layer.masksToBounds = true
        iconGroupView!.layer.cornerRadius = 10
        iconGroupView!.layer.borderColor = UIColor.darkGray.cgColor
        iconGroupView!.layer.borderWidth = 1.0

    }
    
    // Contacts Picker (done selected)
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
        let formatter = CNContactFormatter()
        formatter.style = .fullName
        
        contactsController?.data.contacts.removeAll()
        if( existingGroup != nil ) {
            let users = model.getUsers(group: existingGroup!)
            for user in users {
                let lc = Contact(label: user.label!)
                lc.phoneNumber = user.phoneNumber
                self.contactsController?.data.contacts.append(lc)
            }
        }
        
        for contact in contacts {
            let lc = Contact(label: formatter.string(from: contact) ?? "???")
            
            // Get phone number
            if( contact.phoneNumbers.count == 1 ) {
                lc.setNumber(number: contact.phoneNumbers[0].value.stringValue)
            } else {
                for phn in contact.phoneNumbers {
                    if( phn.label?.lowercased(with: nil) == "iphone" ||
                        phn.label?.lowercased(with: nil) == "mobile"
                    ) {
                        lc.setNumber(number:phn.value.stringValue)
                    }
                }
                if( lc.phoneNumber.isEmpty && contact.phoneNumbers.count > 0 ) {
                    lc.setNumber(number: contact.phoneNumbers[0].value.stringValue)
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
        
        let imageSize = chosenImage.size
        let sx = 32/imageSize.width
        let sy = 32/imageSize.height
        let sc = min(sx, sy)
        let imageScaledSize = CGSize(width: imageSize.width*sc, height: imageSize.height*sc)

        groupIconButton.setImage(chosenImage.resize(newSize: imageScaledSize), for: .normal)
        
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
        if( existingGroup != nil ) {
            let users = model.getUsers(group: existingGroup!)
            var details = String()
            
            for c in contactsController!.data.contacts {
                // Create user
                if( !c.phoneNumber.isEmpty ) {
                    model.getUser(phoneNumber: c.phoneNumber, completion: {(user) -> () in
                        if( user == nil ) {
                            let newUserInvitation = UserInvitation(
                                id: RecordId(), from_user_id: model.me().id,
                                to_group_id: self.existingGroup!.id, to_user: c.phoneNumber
                            )
                            model.saveUserInvitation(userInvitation: newUserInvitation)
                        } else {
                            let contained = users.contains(where: { (u) -> Bool in return u.id == user!.id })
                            if( !contained ) {
                                model.addUserToGroup(group: self.existingGroup!, user: user!)
                            }
                        }
                    })
                    
                    if( !details.isEmpty ) {
                        details += ", "
                    }
                    details += c.label
                    details += " "
                }
            }
            existingGroup!.name = groupName.text!
            existingGroup!.details = details
            existingGroup!.icon = groupIconButton.image(for: .normal)
            model.saveGroup(group: existingGroup!)
            
        } else if( groupName.text != nil ) {
            
            // Create Group
            let group = Group(id: RecordId(), name: groupName.text!)
            group.icon = groupIconButton.image(for: .normal)
            
            let groupActivity = GroupActivity(group_id: group.id)
            model.saveActivity(groupActivity: groupActivity)
            group.activity_id = groupActivity.id
            
            var details = String()
            for c in contactsController!.data.contacts {
                // Create user
                if( !c.phoneNumber.isEmpty ) {
                    if( !details.isEmpty ) {
                        details += ", "
                    }
                    details += c.label
                    details += " "
                }
            }
            group.details = details
            model.saveGroup(group: group)
            
            // Add users to group
            for c in contactsController!.data.contacts {
                // Create user
                if( !c.phoneNumber.isEmpty ) {
                    model.getUser(phoneNumber: c.phoneNumber, completion: {(user) -> () in
                        if( user == nil ) {
                            let newUserInvitation = UserInvitation(
                                id: RecordId(), from_user_id: model.me().id, to_group_id: group.id, to_user: c.phoneNumber
                            )
                            model.saveUserInvitation(userInvitation: newUserInvitation)
                        } else {
                            // Should we automatically add the user to the group or go through the invitation process
                            model.addUserToGroup(group: group, user: user!)
                        }
                    })
                }
            }

            model.addUserToGroup(group: group, user: model.me())
            
            // Create default thread
            let cthread = ConversationThread(id: RecordId(), group_id: group.id, user_id: model.me().id)
            cthread.title = "Main"
            model.saveConversationThread(conversationThread: cthread)
            
            // Create first message
            let message = Message(thread: cthread, user: model.me())
            message.text = "Welcome to ChitChat's group " + groupName.text!
            model.saveMessage(message: message, completion:  {})
        }
        
        // Pop this controller.
        _ = navigationController?.popViewController(animated: true)
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
