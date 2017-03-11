//
//  MessagesViewController.swift
//  ChitChat
//
//  Created by next-shot on 3/7/17.
//  Copyright © 2017 next-shot. All rights reserved.
//

import UIKit

protocol MessageBaseCellDelegate {
    func userIcon() -> UIImageView
    func containerView() -> UIView
    
    func initialize(message: Message)
}

class MessageCell : UICollectionViewCell, MessageBaseCellDelegate {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var labelView: UIView!
    @IBOutlet weak var icon: UIImageView!
    
    func userIcon() -> UIImageView {
        return icon
    }
    func containerView() -> UIView {
        return labelView
    }
    
    func initialize(message: Message) {
        label.text = message.text
        
        if( message.user_id.id == model.me().id.id ) {
            labelView.backgroundColor = UIColor.lightGray
        } else {
            let activity = model.getMyActivity(threadId: message.conversation_id)
            if( activity == nil || activity!.last_read < message.last_modified ) {
                labelView.backgroundColor = UIColor.darkGray
            }
        }
    }
}

class EditableMessageCell : UICollectionViewCell, MessageBaseCellDelegate {
    var message: Message?
    @IBOutlet weak var labelView: UIView!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var textView: UITextView!
    
    func userIcon() -> UIImageView {
        return icon
    }
    func containerView() -> UIView {
        return labelView
    }
    
    func initialize(message: Message) {
        self.message = message
        textView.text = message.text
    }
    
    @IBAction func send(_ sender: Any) {
        message!.text = textView.text
        message!.last_modified = Date()
        textView.endEditing(true)
        
        model.saveMessage(message: message!)
        model.updateMyActivity(thread: model.getConversationThread(threadId: message!.conversation_id)!, date: message!.last_modified)
    }
}

class PictureMessageCell : UICollectionViewCell, MessageBaseCellDelegate  {
    
    @IBOutlet weak var labelView: UIView!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var caption: UILabel!
    
    func userIcon() -> UIImageView {
        return icon
    }
    func containerView() -> UIView {
        return labelView
    }
    func initialize(message: Message) {
        imageView.image = message.image
        caption.text = message.text
    }
}

protocol MessageBaseCellSizeDelegate {
    func size(message: Message, collectionView: UICollectionView) -> CGSize
}

class TextMessageCellSizeDelegate : MessageBaseCellSizeDelegate {
    func size(message: Message, collectionView: UICollectionView) -> CGSize {
        let text = message.text
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

class ImageMessageCellSizeDelegate : MessageBaseCellSizeDelegate {
    func size(message: Message, collectionView: UICollectionView) -> CGSize {
        return CGSize(width: 290, height: 215)
    }
}

class MessageCellFactory {
    enum messageType { case text, editable, image }
    
    class func getType(message: Message, collectionView: UICollectionView, indexPath: IndexPath) -> messageType {
        if( message.image != nil ) {
            return .image
        }
        if( message.user_id.id == model.me().id.id &&
            indexPath.row == collectionView.numberOfItems(inSection: indexPath.section)-1
        ) {
            // If last message written by me
            return .editable
        }
    
        return .text
    }
    
    class func create(message: Message, collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        let type = getType(message: message, collectionView: collectionView, indexPath: indexPath)
        switch( type ) {
        case .text :
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: "MessageCell", for: indexPath
            )
        case .editable:
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: "EditableMessageCell", for: indexPath
            )
        case .image:
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: "PictureMessageCell", for: indexPath
            )
        }
    }
    
    class func sizer(message: Message, collectionView: UICollectionView, indexPath: IndexPath) -> MessageBaseCellSizeDelegate {
        let type = getType(message: message, collectionView: collectionView, indexPath: indexPath)
        switch( type ) {
        case .text :
            return TextMessageCellSizeDelegate()
        case .editable:
            return TextMessageCellSizeDelegate()
        case .image:
            return ImageMessageCellSizeDelegate()
        }
    }
}

class MessagesData : NSObject, UICollectionViewDataSource {
    var messages = [Message]()
    
    init(thread: ConversationThread) {
        messages = model.getMessagesForThread(thread: thread)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let m = messages[indexPath.row]
        let cell = MessageCellFactory.create(message: m, collectionView: collectionView, indexPath: indexPath)
        
        let delegate = cell as? MessageBaseCellDelegate
        initialize(message: m, cell: delegate!)
        
        return cell
    }
    
    func initialize(message: Message, cell: MessageBaseCellDelegate) {
        cell.initialize(message: message)
        
        // common behavior to all cells
        let uiView = cell.containerView()
        uiView.layer.masksToBounds = true
        uiView.layer.cornerRadius = 6
        uiView.layer.borderColor = UIColor.gray.cgColor
        uiView.layer.borderWidth = 1.0

        let user = model.getUser(userId: message.user_id)
        cell.userIcon().image = user?.icon

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
        let sizer = MessageCellFactory.sizer(message: m, collectionView: collectionView, indexPath: indexPath)
        return sizer.size(message: m, collectionView: collectionView)
    }
}


class MessagesViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var messagesView: UICollectionView!
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var textView: GrowingTextView!
    @IBOutlet weak var inputContainerView: UIView!
    
    var data : MessagesData?
    var delegate : MessagesViewDelegate?
    var conversationThread : ConversationThread?
    var curMessage: Message?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Manage the collection view.
        data = MessagesData(thread: conversationThread!)
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
        model.updateMyActivity(thread: conversationThread!, date: Date())
    }
    
    @IBAction func handleSendButton(_ sender: Any) {
        let myId = model.me().id
        
        // Create Message
        if( curMessage == nil ) {
            let m = Message(threadId: conversationThread!.id, user_id: myId)
            m.text = self.textView.text
            
            // Add it to DB
            model.saveMessage(message: m)
            
            // Add it to interface
            data?.messages.append(m)
            messagesView.insertItems(at: [IndexPath(row: data!.messages.count-1, section: 0)])
            messagesView.scrollToItem(at: IndexPath(row: data!.messages.count-1, section: 0), at: UICollectionViewScrollPosition.bottom, animated: true)
        } else {
            // Finish message
            curMessage!.text = self.textView.text
            curMessage!.last_modified = Date()
            
            // Update Interface
            messagesView.reloadItems(at: [IndexPath(row: data!.messages.count-1, section: 0)])
            
            // Add it to DB
            model.saveMessage(message: curMessage!)
            model.updateMyActivity(thread: conversationThread!, date: curMessage!.last_modified)

            // Reset placeholder
            self.textView.placeholderAttributedText = NSAttributedString(
                string: "Type a message...",
                attributes: [NSForegroundColorAttributeName: UIColor.gray, NSFontAttributeName: self.textView.font!]
            )
        }
        
        self.textView.text = ""
        self.view.endEditing(true)
        self.curMessage = nil
    }
    
    @IBAction func handleSendPicture(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }
    
    // Image picker
    func imagePickerController(
        _ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]
    ) {
        let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage
        if( selectedImage != nil ) {
            let size = selectedImage!.size
            let sx = 234/size.width
            let sy = 166/size.height
            let scale = min(sx, sy)
            let image = selectedImage!.resize(newSize: CGSize(width: size.width*scale, height: size.height*scale))
            
            // Create Message
            let myId = model.me().id
            let m = Message(threadId: conversationThread!.id, user_id: myId)
            m.text = self.textView.text
            m.image = image
            
            // Add it to interface
            data?.messages.append(m)
            messagesView.insertItems(at: [IndexPath(row: data!.messages.count-1, section: 0)])
            messagesView.scrollToItem(at: IndexPath(row: data!.messages.count-1, section: 0), at: UICollectionViewScrollPosition.bottom, animated: true)
            
            curMessage = m
            
            self.textView.placeholderAttributedText = NSAttributedString(
                string: "Enter a caption...",
                attributes: [NSForegroundColorAttributeName: UIColor.gray, NSFontAttributeName: self.textView.font!]
            )
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
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

