//
//  MessagesViewController.swift
//  ChitChat
//
//  Created by next-shot on 3/7/17.
//  Copyright © 2017 next-shot. All rights reserved.
//

import UIKit

protocol MessageBaseCellDelegate {
    func userIcon() -> UIImageView?
    func containerView() -> UIView?
    
    func initialize(message: Message, controller : MessagesViewController?)
}

func getFromName(message: Message) -> String {
    let longDateFormatter = DateFormatter()
    longDateFormatter.locale = Locale.current
    longDateFormatter.setLocalizedDateFormatFromTemplate("MMM d, HH:mm")
    longDateFormatter.timeZone = TimeZone.current
    let longDate = longDateFormatter.string(from: message.last_modified)
    
    if( message.user_id == model.me().id ) {
        return longDate
    } else {
        return message.fromName + " " + longDate
    }
}

class MessageCell : UICollectionViewCell, MessageBaseCellDelegate {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var labelView: UIView!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var fromLabel: UILabel!
    
    func userIcon() -> UIImageView? {
        return icon
    }
    func containerView() -> UIView? {
        return labelView
    }
    
    func initialize(message: Message, controller : MessagesViewController?) {
        label.text = message.text
    
        fromLabel.text = getFromName(message: message)
        
        let bg = ColorPalette.backgroundColor(message: message)
        labelView.backgroundColor = bg
    }
}

class EditableMessageCell : UICollectionViewCell, MessageBaseCellDelegate, UITextViewDelegate {
    var message: Message?
    var controller : MessagesViewController?
    var tapper : UITapGestureRecognizer?
    
    @IBOutlet weak var labelView: UIView!
    @IBOutlet weak var textView: UITextView!
    
    func userIcon() -> UIImageView? {
        return nil
    }
    func containerView() -> UIView? {
        return labelView
    }
    
    func initialize(message: Message, controller : MessagesViewController?) {
        self.message = message
        self.controller = controller
        textView.text = message.text
        textView.delegate = self
    }
    
    @IBAction func send(_ sender: Any) {
        message!.text = textView.text
        message!.last_modified = Date()
        textView.endEditing(true)
        
        model.saveMessage(message: message!)
        model.updateMyActivity(
            thread: model.getConversationThread(threadId: message!.conversation_id)!,
            date: message!.last_modified,
            withNewMessage: message
        )
    }
    
    @IBAction func spellCheck(_ sender: UIButton) {
        sender.playSendSound()
        let checker = SpellChecker(textView: textView)
        checker.check()
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        controller?.inputContainerView.isHidden = true
        
        tapper = UITapGestureRecognizer(target: self, action:#selector(endEditingWithTouch))
        tapper!.cancelsTouchesInView = false
        controller?.view.addGestureRecognizer(tapper!)

        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if( controller != nil ) {
           controller!.inputContainerView.isHidden = false
           controller!.view.layoutIfNeeded()
           controller!.messagesView.scrollToItem(at: IndexPath(row: controller!.data!.messages.count-1, section: 0), at: UICollectionViewScrollPosition.bottom, animated: true)
            
            if( tapper != nil ) {
                controller!.view.removeGestureRecognizer(tapper!)
            }
        }
    }
    
    func endEditingWithTouch() {
        textView.resignFirstResponder()
    }
}

class PictureMessageCell : UICollectionViewCell, MessageBaseCellDelegate  {
    
    @IBOutlet weak var labelView: UIView!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var caption: UILabel!
    @IBOutlet weak var fromLabel: UILabel!
    
    func userIcon() -> UIImageView? {
        return icon
    }
    func containerView() -> UIView? {
        return labelView
    }
    func initialize(message: Message, controller : MessagesViewController?) {
        imageView.image = message.image
        caption.text = message.text
        fromLabel.text = getFromName(message: message)
    }
}

class ThumbUpMessageCell : UICollectionViewCell, MessageBaseCellDelegate {
    
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var fromLabel: UILabel!
    
    func containerView() -> UIView? {
        return nil
    }
    
    func userIcon() -> UIImageView? {
        return icon
    }
    
    func initialize(message: Message, controller : MessagesViewController?) {
        fromLabel.text = getFromName(message: message)
    }
}

class DecoratedMessageCell : UICollectionViewCell, MessageBaseCellDelegate {
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var textView: DrawingTextView!
    @IBOutlet weak var labelView: UIView!
    @IBOutlet weak var fromLabel: UILabel!
    
    func containerView() -> UIView? {
        return labelView
    }
    
    func userIcon() -> UIImageView? {
        return icon
    }
    
    func initialize(message: Message, controller : MessagesViewController?) {
        textView.text = message.text
        
        func setTheme(string: String) {
            var theme = DrawingTextView.theme.test
            if( string == "flowers" ) {
                theme = DrawingTextView.theme.flowers
            } else if( string == "clovers" ) {
                theme = DrawingTextView.theme.clover
            } else if( string == "hearts" ) {
                theme = DrawingTextView.theme.heart
            } else if ( string == "music notes" ) {
                theme = DrawingTextView.theme.musicnotes
            } else if ( string == "easter" ) {
                theme = DrawingTextView.theme.easter
            }
            textView.atheme = theme
            textView.setNeedsDisplay()
        }
        let mo = MessageOptions(options: message.options)
        setTheme(string: mo.theme)

        fromLabel.text = getFromName(message: message)
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

class DecoratedTextMessageCellSizeDelegate : TextMessageCellSizeDelegate {
    override func size(message: Message, collectionView: UICollectionView) -> CGSize {
        let text = message.text
        //let nstext = NSString(string: text)
        
        let spacing : CGFloat = 10
        let width = collectionView.bounds.width - 3*spacing
        let label = DrawingTextView()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.text = text
        label.font = UIFont.systemFont(ofSize: 17)
        
        let size = label.computeSize(CGSize(width: width, height: 1500))
        
        return CGSize(width: width, height: size.height)
    }
}

class ImageMessageCellSizeDelegate : MessageBaseCellSizeDelegate {
    func size(message: Message, collectionView: UICollectionView) -> CGSize {
        let spacing : CGFloat = 10
        let width = collectionView.bounds.width - 3*spacing
        return CGSize(width: width, height: 215)
    }
}

class ThumbUpMessageCellSizeDelegate : MessageBaseCellSizeDelegate {
    func size(message: Message, collectionView: UICollectionView) -> CGSize {
        let spacing : CGFloat = 10
        let width = collectionView.bounds.width - 3*spacing
        return CGSize(width: width, height: 60)
    }
}

class EditableMessageCellSizeDelate: TextMessageCellSizeDelegate {
    override func size(message: Message, collectionView: UICollectionView) -> CGSize {
        let cgsize = super.size(message: message, collectionView: collectionView)
        let buttonSize = 28
        let margin = 5
        return CGSize(width: cgsize.width, height: max(cgsize.height, CGFloat(3*(buttonSize+margin))))
    }
}

class MessageCellFactory {
    enum messageType { case text, editable, image, thumbUp, textDecorated }
    
    class func getType(message: Message, collectionView: UICollectionView, indexPath: IndexPath) -> messageType {
        if( message.image != nil ) {
            return .image
        }
        if( message.text == "%%Thumb-up%%" ) {
            return .thumbUp
        }
        if( !message.options.isEmpty ) {
            let options = MessageOptions(options: message.options)
            if( options.decorated ) {
                return .textDecorated
            }
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
        case .textDecorated :
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: "DecoratedMessageCell", for: indexPath
            )
        case .editable:
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: "EditableMessageCell", for: indexPath
            )
        case .image:
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: "PictureMessageCell", for: indexPath
            )
        case .thumbUp:
                return collectionView.dequeueReusableCell(
                    withReuseIdentifier: "ThumbUpMessageCell", for: indexPath
            )
        }
    }
    
    class func sizer(message: Message, collectionView: UICollectionView, indexPath: IndexPath) -> MessageBaseCellSizeDelegate {
        let type = getType(message: message, collectionView: collectionView, indexPath: indexPath)
        switch( type ) {
        case .text :
            return TextMessageCellSizeDelegate()
        case .textDecorated:
            return DecoratedTextMessageCellSizeDelegate()
        case .editable:
            return EditableMessageCellSizeDelate()
        case .image:
            return ImageMessageCellSizeDelegate()
        case .thumbUp:
            return ThumbUpMessageCellSizeDelegate()
        }
    }
}

class MessagesData : NSObject, UICollectionViewDataSource {
    var messages = [Message]()
    weak var controller : MessagesViewController?
    
    init(thread: ConversationThread, messages: [Message], ctrler: MessagesViewController) {
        self.messages = messages
        controller = ctrler
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
        cell.initialize(message: message, controller: controller)
        
        // common behavior to all cells
        let uiView = cell.containerView()
        if( uiView != nil ) {
           uiView!.layer.masksToBounds = true
           uiView!.layer.cornerRadius = 6
           uiView!.layer.borderColor = ColorPalette.colors[.borderColor]?.cgColor
           uiView!.layer.borderWidth = 1.0
        }

        if( cell.userIcon() != nil ) {
            let user = model.getUser(userId: message.user_id)
            cell.userIcon()!.image = user?.icon
        }
    }
}

// Manage modifications of the data model linked to 
// new messages or edited messages
class MessagesDataView : ModelView {
    weak var controller : MessagesViewController?

    init(ctrler: MessagesViewController) {
        self.controller = ctrler
            
        super.init()
            
        self.notify_new_message = newMessage
        self.notify_edit_message = editMessage
    }
    func newMessage(message: Message) {
        if( controller == nil || controller!.data == nil ) {
            return
        }
        if( message.user_id != model.me().id ) {
            
            model.getMessagesForThread(thread: controller!.conversationThread!, completion: { (messages) -> Void in
                self.controller!.data!.messages = messages
                self.controller!.messagesView.reloadData()
                self.controller!.messagesView.scrollToItem(at: IndexPath(row: self.controller!.data!.messages.count-1, section: 0), at: UICollectionViewScrollPosition.bottom, animated: true)
            })
        }
    }
    func editMessage(message: Message) {
        let dataHandler = self.controller!.data!
        let index = dataHandler.messages.index(where: { (mess)-> Bool in
            return mess.id == message.id
        })
        if( index != nil ) {
            dataHandler.messages.remove(at: index!)
            dataHandler.messages.insert(message, at: index!)
            self.controller!.messagesView.reloadItems(at: [IndexPath(row: index!, section: 0)])
        }

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

/***********************************************************************/
// Theme collection classes
class DecoratedMessageThemeCollectionViewCell : UICollectionViewCell {
    
    @IBOutlet weak var label: UILabel!
}

class DecoratedMessageThemesPickerSource : NSObject, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    let themes = ["flowers", "clovers", "hearts", "music notes", "easter"]
    weak var controller: MessagesViewController?
    
    init(controller: MessagesViewController) {
        self.controller = controller
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return themes.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DecoratedMessageThemeCollectionViewCell", for: indexPath) as! DecoratedMessageThemeCollectionViewCell
        cell.label.text = themes[indexPath.item]
        
        cell.layer.masksToBounds = true
        cell.layer.cornerRadius = 6
        cell.layer.borderColor = ColorPalette.colors[.borderColor]?.cgColor
        cell.layer.borderWidth = 1.0
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if( controller != nil && controller!.curMessage != nil ) {
            let m = controller!.curMessage!
            let mo = controller!.curMessageOption!
        
            mo.theme = themes[indexPath.item]
            
           let optionString = mo.getString()
           m.options = optionString ?? ""

            // Update message view
           controller!.messagesView.reloadItems(at: [IndexPath(row: controller!.data!.messages.count-1, section: 0)])
            
            // Update selected theme cell
            let cell = collectionView.cellForItem(at: indexPath)
            cell?.layer.backgroundColor = ColorPalette.colors[ColorPalette.States.unread]?.cgColor
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        // Update selected theme cell
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.layer.backgroundColor = nil
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing : CGFloat = 10
        
        let label = UILabel()
        label.text = themes[indexPath.item]
        label.font = UIFont.systemFont(ofSize: 17)
        
        let size = label.sizeThatFits(CGSize(width: 1000, height: 1500))
        return CGSize(width: size.width + spacing, height: size.height + spacing)
    }
    
}

// To communicate text changes to the message view.
class MessagesViewGrowingTextViewDelegate : GrowingTextView.Delegates {
    weak var controller: MessagesViewController?
    init(controller: MessagesViewController) {
        self.controller = controller
        
        super.init()
        
        self.textViewDidChange = localTextViewDidChange
    }
    
    func localTextViewDidChange(_ view: GrowingTextView) {
        if( controller != nil ) {
            let c = controller!
            if( c.curMessage != nil && c.curMessageOption != nil ) {
                c.curMessage!.text = view.text
                c.messagesView.reloadItems(at: [IndexPath(row: c.data!.messages.count-1, section: 0)])
            }
        }
    }
}

class MessagesViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var messagesView: UICollectionView!
    
    @IBOutlet weak var themesCollectionView: UICollectionView!
    @IBOutlet weak var decorationThemesView: UIView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var textView: GrowingTextView!
    @IBOutlet weak var inputContainerView: UIView!
    
    var data : MessagesData?
    var delegate : MessagesViewDelegate?
    var conversationThread : ConversationThread?
    var curMessage: Message?
    var curMessageOption: MessageOptions?
    var modelView : MessagesDataView?
    var themesCollectionData : DecoratedMessageThemesPickerSource?
    var textViewDelegate : MessagesViewGrowingTextViewDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Manage the collection view.
        model.getMessagesForThread(thread: conversationThread!, completion: { (messages) -> Void in
            self.data = MessagesData(thread: self.conversationThread!, messages: messages, ctrler: self)
            self.messagesView.dataSource = self.data
            self.delegate = MessagesViewDelegate(data: self.data!)
            self.messagesView.delegate = self.delegate
            
            DispatchQueue.main.async(execute: {
                self.messagesView.reloadData()
                self.messagesView.scrollToItem(
                    at: IndexPath(row: messages.count-1, section: 0), at: UICollectionViewScrollPosition.bottom, animated: true
                )
            })
        })
        
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
        
        modelView = MessagesDataView(ctrler: self)
        decorationThemesView.isHidden = true
        
        themesCollectionData = DecoratedMessageThemesPickerSource(controller: self)
        themesCollectionView.delegate = themesCollectionData
        themesCollectionView.dataSource = themesCollectionData
        
        textViewDelegate = MessagesViewGrowingTextViewDelegate(controller: self)
        textView.delegates = textViewDelegate!
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if( data != nil && data!.messages.count > 0 ) {
            
            // Count the number of new message unread and modify the application badge.
            let myActivity = model.getMyActivity(threadId: conversationThread!.id)
            var count = 0
            for m in data!.messages {
                let date = m.getCreationDate()
                if( date != nil && (myActivity == nil || myActivity!.last_read < date!) ) {
                    count += 1
                }
            }
            if( count < UIApplication.shared.applicationIconBadgeNumber ) {
                model.setAppBadgeNumber(number: UIApplication.shared.applicationIconBadgeNumber - count)
            } else {
                model.setAppBadgeNumber(number: 0)
            }
        }
        
        // Mark the fact that I just did read that thread
        model.updateMyActivity(thread: conversationThread!, date: Date(), withNewMessage: nil)
        
        // Add observer
        model.views.append(modelView!)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Remove observer
        model.removeViews(views: [modelView!])
    }
    
    @IBAction func handleSendButton(_ sender: Any) {
        
        // Create Message
        if( curMessage == nil ) {
            let m = Message(thread: conversationThread!, user: model.me())
            m.text = self.textView.text
            
            // Add it to DB
            model.saveMessage(message: m)
            model.updateMyActivity(
                thread: conversationThread!, date: m.last_modified, withNewMessage: m
            )
            
            // Add it to interface
            data?.messages.append(m)
            messagesView.insertItems(at: [IndexPath(row: data!.messages.count-1, section: 0)])
            
            
            // Update Interface (to transform an editable into a non editable for example)
            if( data!.messages.count > 2 ) {
                messagesView.reloadItems(at: [IndexPath(row: data!.messages.count-2, section: 0)])
            }

        } else {
            // Finish message
            curMessage!.text = self.textView.text
            curMessage!.last_modified = Date()
            
            // Update Interface
            messagesView.reloadItems(at: [IndexPath(row: data!.messages.count-1, section: 0)])
            
            // Add it to DB
            model.saveMessage(message: curMessage!)
            model.updateMyActivity(
                thread: conversationThread!, date: curMessage!.last_modified, withNewMessage: curMessage!
            )

            // Reset placeholder
            self.textView.placeholderAttributedText = NSAttributedString(
                string: "Type a message...",
                attributes: [NSForegroundColorAttributeName: UIColor.gray, NSFontAttributeName: self.textView.font!]
            )
        }
        
        self.textView.text = ""
        self.view.endEditing(true)
        self.curMessage = nil
        self.curMessageOption = nil
        
        decorationThemesView.isHidden = true
        self.view.layoutIfNeeded()
        messagesView.scrollToItem(
            at: IndexPath(row: data!.messages.count-1, section: 0), at: UICollectionViewScrollPosition.bottom, animated: true
        )
    }
    
    @IBAction func handleSendAndFork(_ sender: Any) {
        self.view.endEditing(true)
        
        let alertCtrler = UIAlertController(
            title: "Fork conversation",
            message: "Please provide a new conversation title",
            preferredStyle: .alert
        )
        alertCtrler.addTextField(configurationHandler:{ (textField) -> Void in
            textField.placeholder = "Conversation title"
        })
        
        alertCtrler.addAction(UIAlertAction(title: "OK", style: .default, handler:{ alertAction -> Void in
            let textField = alertCtrler.textFields![0]
            if( !textField.text!.isEmpty ) {
                let newThread = ConversationThread(id: RecordId(), group_id: self.conversationThread!.group_id)
                newThread.title = textField.text!
                model.saveConversationThread(conversationThread: newThread)
                
                let m = Message(thread: newThread, user: model.me())
                m.text = self.textView.text
                
                // Add it to DB
                model.saveMessage(message: m)
                model.updateMyActivity(thread: newThread, date: m.last_modified, withNewMessage: m)
                
                // Update UI
                self.textView.text = ""
                self.title = newThread.title
                // Manage the collection view.
                self.conversationThread = newThread
                self.data = MessagesData(thread: self.conversationThread!, messages: [m], ctrler: self)
                self.messagesView.dataSource = self.data
                self.delegate = MessagesViewDelegate(data: self.data!)
                self.messagesView.delegate = self.delegate

                self.messagesView.reloadData()
            }
        }))
        
        alertCtrler.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alertCtrler, animated: true, completion: nil)
        
    }
    
    @IBAction func handleSendThumbUp(_ sender: Any) {
        let m = Message(thread: conversationThread!, user: model.me())
        m.text = "%%Thumb-up%%"
        
        // Add it to DB
        model.saveMessage(message: m)
        model.updateMyActivity(
            thread: conversationThread!, date: m.last_modified, withNewMessage: m
        )
        
        // Add it to interface
        data?.messages.append(m)
        messagesView.insertItems(at: [IndexPath(row: data!.messages.count-1, section: 0)])
        messagesView.scrollToItem(at: IndexPath(row: data!.messages.count-1, section: 0), at: UICollectionViewScrollPosition.bottom, animated: true)
    }
    
    @IBAction func handleSendPicture(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }
    
    @IBAction func handleSendCameraPicture(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = .camera
        present(picker, animated: true, completion: nil)
    }
    
    // Image picker
    func imagePickerController(
        _ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]
    ) {
        var selectedImage = info[UIImagePickerControllerEditedImage] as? UIImage
        if( selectedImage == nil ) {
            selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage
        }
        if( selectedImage != nil ) {
            let size = selectedImage!.size
            let sx = 234/size.width
            let sy = 166/size.height
            let scale = min(sx, sy)
            let image = selectedImage!.resize(newSize: CGSize(width: size.width*scale, height: size.height*scale))
            
            // Create Message
            let m = Message(thread: conversationThread!, user: model.me())
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
    
    @IBAction func handleSendDecoratedMessage(_ sender: Any) {
        // Create Message
        let m = Message(thread: conversationThread!, user: model.me())
        m.text = self.textView.text
        
        curMessageOption = MessageOptions(type: "decoratedText")
        curMessageOption!.decorated = true
        m.options = curMessageOption!.getString() ?? ""
        
        // Add it to interface
        data?.messages.append(m)
        messagesView.insertItems(at: [IndexPath(row: data!.messages.count-1, section: 0)])
        
        decorationThemesView.isHidden = false
        self.view.layoutIfNeeded()
        messagesView.scrollToItem(
            at: IndexPath(row: data!.messages.count-1, section: 0), at: UICollectionViewScrollPosition.bottom, animated: true
        )
        
        curMessage = m
    }

    @IBAction func handleSpellCheck(_ sender: UIButton) {
        sender.playSendSound()
        let checker = SpellChecker(textView: textView)
        checker.check()
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
                    self.messagesView.scrollToItem(at: IndexPath(row: self.data!.messages.count-1, section: 0), at: UICollectionViewScrollPosition.bottom, animated: true)
                })
            }
        }
    }

}

