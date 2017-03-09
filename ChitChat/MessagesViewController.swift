//
//  MessagesViewController.swift
//  ChitChat
//
//  Created by next-shot on 3/7/17.
//  Copyright © 2017 next-shot. All rights reserved.
//

import UIKit

class MessageCell : UICollectionViewCell {
    
    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var labelView: UIView!
    @IBOutlet weak var icon: UIImageView!
}

class MessagesData : NSObject, UICollectionViewDataSource {
    var messages = [Message]()
    
    init(threadId: RecordId) {
        messages = db_model.getMessagesForThread(threadId: threadId)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MessageCell", for: indexPath) as! MessageCell
        let m = messages[indexPath.row]
        cell.label.text = m.text
        let user = db_model.getUser(userId: m.user_id)
        cell.icon.image = user?.icon
        
        if( m.user_id.id == db_model.me().id.id ) {
            cell.labelView.backgroundColor = UIColor.lightGray
        } else {
            let activity = db_model.getActivity(userId: db_model.me().id, threadId: m.conversation_id)
            if( activity == nil || activity!.last_read < m.last_modified ) {
                cell.labelView.backgroundColor = UIColor.darkGray
            }
        }
        
        cell.labelView.layer.masksToBounds = true
        cell.labelView.layer.cornerRadius = 6
        cell.labelView.layer.borderColor = UIColor.gray.cgColor
        cell.labelView.layer.borderWidth = 1.0
        
        return cell
    }
}

class MessagesViewDelegate : NSObject, UICollectionViewDelegateFlowLayout {
    let messageData : MessagesData
    
    init(data: MessagesData) {
        messageData = data
    }
    
    // Compute the size of a message
    func collectionView(
        _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let m = messageData.messages[indexPath.row]
        let text = m.text
        //let nstext = NSString(string: text)
        
        let spacing : CGFloat = 10
        let width = collectionView.bounds.width - 3*spacing
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.text = text
        label.font = UIFont.systemFont(ofSize: 17)
        
        let size = label.sizeThatFits(CGSize(width: width, height: 1500))
        //let rect = nstext.boundingRect(with: CGSize(width: width, height: 1500), options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 17)], context: nil)
        return CGSize(width: width, height: max(24,size.height) + 4*spacing)
    }
}


class MessagesViewController: UIViewController {
    @IBOutlet weak var messagesView: UICollectionView!
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var textView: GrowingTextView!
    @IBOutlet weak var inputContainerView: UIView!
    
    var data : MessagesData?
    var delegate : MessagesViewDelegate?
    var threadId : RecordId?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Manage the collection view.
        data = MessagesData(threadId: threadId!)
        messagesView.dataSource = data
        delegate = MessagesViewDelegate(data: data!)
        messagesView.delegate = delegate
        
        // Keyboard handling for the message text area
        NotificationCenter.default.addObserver(self, selector: #selector(MessagesViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MessagesViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        // Finish configuring the textView.
        self.textView.layer.cornerRadius = 4
        self.textView.backgroundColor = UIColor(white: 0.9, alpha: 1)
        self.textView.textContainerInset = UIEdgeInsets(top: 16, left: 0, bottom: 4, right: 0)
        self.textView.placeholderAttributedText = NSAttributedString(
            string: "Type a message...",
            attributes: [NSForegroundColorAttributeName: UIColor.gray, NSFontAttributeName: self.textView.font!]
        )
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        messagesView.scrollToItem(
            at: IndexPath(row: data!.messages.count-1, section: 0), at: UICollectionViewScrollPosition.bottom, animated: true
        )
        
        // Mark the fact that I just did read that thread
        db_model.updateActivity(userId: db_model.me().id, threadId: threadId!, date: Date())
    }
    
    @IBAction func handleSendButton(_ sender: Any) {
        let myId = db_model.me().id
        
        // Create Message
        let m = Message(threadId: threadId!, user_id: myId)
        m.text = self.textView.text
        
        // Add it to DB
        db_model.messages.append(m)
        db_model.updateActivity(userId: myId, threadId: threadId!, date: m.last_modified)
        
        // Add it to interface
        data?.messages.append(m)
        messagesView.insertItems(at: [IndexPath(row: data!.messages.count-1, section: 0)])
        messagesView.scrollToItem(at: IndexPath(row: data!.messages.count-1, section: 0), at: UICollectionViewScrollPosition.bottom, animated: true)
        
        // Empty text view and end the editing.
        self.textView.text = ""
        self.view.endEditing(true)
    }
    
    // Keyboard handling
    func keyboardWillHide(_ sender: Notification) {
        if let userInfo = (sender as NSNotification).userInfo {
            if let _ = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height {
                //key point 0,
                self.bottomConstraint.constant =  0
                //textViewBottomConstraint.constant = keyboardHeight
                UIView.animate(withDuration: 0.25, animations: { () -> Void in self.view.layoutIfNeeded() })
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
}

