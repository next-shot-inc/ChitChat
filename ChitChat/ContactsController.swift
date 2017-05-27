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
import MessageUI

class Contact {
    let label : String
    var phoneNumber = String()
    var errorPhone = String()
    var email = String()
    var existing = false
    var existingUser : Bool?
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
    @IBOutlet weak var userStatus: UILabel!
    
    @IBOutlet weak var statusImageView: UIImageView!
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
            cell.checkButton.isEnabled = false
        }
        
        cell.checkButton.setImage(UIImage(named: "checked"), for: .selected)
        cell.checkButton.setImage(UIImage(named: "unchecked"), for: .normal)
        
        if( contact.existingUser != nil ) {
           if( !contact.existingUser! ) {
               cell.checkButton.setImage(UIImage(named: "checked_hollow"), for: .selected)
               cell.statusImageView.image = UIImage(named: "checked_hollow")
               cell.userStatus.text = "Non existing user - Need invitation"
           } else {
               cell.userStatus.text = "Existing user"
               cell.statusImageView.image = UIImage(named: "checked")
           }
        } else {
            cell.userStatus.text = "Checking user status... "
            cell.statusImageView.image = UIImage(named: "checked")
        }
        
        cell.checkButton.isSelected = !contact.phoneNumber.isEmpty
        if( contact.phoneNumber.isEmpty ) {
            cell.statusImageView.image = UIImage(named: "unchecked")
        }
        
        if( contact.existing ) {
            cell.checkButton.isEnabled = false
        }

        return cell
    }
}

class NewGroupController : UIViewController, CNContactPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate , MFMailComposeViewControllerDelegate {
    var contactsController: ContactsController?
    
    @IBOutlet weak var groupName: UITextField!
    @IBOutlet weak var contactsView: UITableView!
    @IBOutlet weak var groupIconButton: UIButton!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var iconGroupView: UIView!
    @IBOutlet weak var selectButton: UIButton!
    
    var existingGroup : Group?
    var canEdit = true
    var activityView: UIActivityIndicatorView?
    
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
            selectButton.isEnabled = false
            if( canEdit ) {
                createButton.setTitle("Save", for: .normal)
                self.title = "Edit Group"
            } else {
                groupIconButton.isEnabled = false
                groupName.isEnabled = false
                self.title = "View Group"
            }
            
            // As we need to wait for existing users to be displayed.
            activityView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
            
            model.getUsersAndInvitedForGroup(group: existingGroup!, completion: { (users, invitations) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    for user in users {
                        let lc = Contact(label: user.label!)
                        lc.phoneNumber = user.phoneNumber
                        lc.existing = true
                        lc.existingUser = true
                        self.contactsController?.data.contacts.append(lc)
                    }
                    for invite in invitations {
                        if( invite.to_user_label != nil ) {
                            let lc = Contact(label: invite.to_user_label!)
                            lc.phoneNumber = invite.to_user
                            lc.existing = true
                            self.contactsController?.data.contacts.append(lc)
                        }
                    }
                    self.contactsView.reloadData()
                    
                    // Enable buttons only when the in-memory model is ok.
                    if( self.canEdit ) {
                        self.createButton.isEnabled = true
                        self.selectButton.isEnabled = true
                    }
                    
                    if( self.activityView != nil ) {
                        self.activityView!.stopAnimating()
                        self.activityView!.removeFromSuperview()
                        self.activityView = nil
                    }
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

        if( existingGroup != nil && existingGroup!.icon != nil ) {
            groupIconButton.setImage(existingGroup!.icon, for: .normal)
            groupIconButton.setNeedsDisplay()
        }
        
        if( activityView != nil ) {
            activityView!.color = UIColor.blue
            activityView!.center = self.view.center
            activityView!.startAnimating()
            self.view.addSubview(activityView!)
        }
    }
    
    // Contacts Picker (done selected)
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
        let formatter = CNContactFormatter()
        formatter.style = .fullName
        
        let existing = contactsController?.data.contacts.filter({ (contact) -> Bool in
            return contact.existing == true
        })
        if( existing != nil ) {
            contactsController?.data.contacts = existing!
        } else {
            contactsController?.data.contacts.removeAll()
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
            
            model.getUser(phoneNumber: lc.phoneNumber, completion: {(user) -> () in
                DispatchQueue.main.async(execute: { () -> Void in
                    lc.existingUser = user != nil
                    let index = self.contactsController?.data.contacts.index(where: { (c) -> Bool in
                        lc === c
                    })
                    if( index != nil ) {
                        self.contactsController?.tableView.reloadRows(at: [IndexPath(row: index!, section: 0)], with: .none)
                    }
                })
            })
            
            if( contact.emailAddresses.count == 1 ) {
                lc.email = String(contact.emailAddresses[0].value)
            } else {
                for email in contact.emailAddresses {
                    if( email.label == CNLabelEmailiCloud ) {
                        lc.email = String(email.value)
                    }
                }
                if( lc.email.isEmpty && contact.emailAddresses.count > 0 ) {
                    lc.email = String(contact.emailAddresses[0].value)
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
            var details = String()
            
            for c in contactsController!.data.contacts {
                // Remove bad contacts.
                if( c.phoneNumber.isEmpty ) {
                    continue
                }
                if( !c.existing ) {
                    // Add user to group or create an invitation.
                    model.getUser(phoneNumber: c.phoneNumber, completion: {(user) -> () in
                        if( user == nil ) {
                            let newUserInvitation = UserInvitation(
                                id: RecordId(), from_user_id: model.me().id,
                                to_group_id: self.existingGroup!.id, to_user: c.phoneNumber
                            )
                            model.saveUserInvitation(userInvitation: newUserInvitation)
                        } else {
                            model.addUserToGroup(group: self.existingGroup!, user: user!)
                        }
                    })
                }
                if( !details.isEmpty ) {
                    details += ", "
                }
                details += c.label
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
    
    @IBAction func inviteContact(_ sender: Any) {
        if( contactsController == nil ) {
            return
        }
        
        let mailComposer = MFMailComposeViewController()
        mailComposer.setSubject("Invitation to join ChitChat conversations")
        
        var recipients = [String]()
        for c in contactsController!.data.contacts {
            if( !(c.existingUser ?? true) && !c.email.isEmpty ) {
                recipients.append(c.email)
            }
        }
        mailComposer.setToRecipients(recipients)
        let image = UIImage(named: "icon60x60")
        let imageString = returnEmailStringBase64EncodedImage(image: image!)
        let emailBody = "<html>"
             + "<body>"
             + "Check out this messaging App!"
             + "<img src='data:image/png;base64,\(imageString)' width='60' height='60'>"
             + "</body>"
             + "</html>"
        
        mailComposer.setMessageBody(emailBody, isHTML: true)
        mailComposer.mailComposeDelegate = self
        
        present(mailComposer, animated: true, completion: nil)
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        print(result)
        controller.dismiss(animated: true, completion: nil)
    }

    func returnEmailStringBase64EncodedImage(image:UIImage) -> String {
        let imgData:NSData = UIImagePNGRepresentation(image)! as NSData;
        let dataString = imgData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        return dataString
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
