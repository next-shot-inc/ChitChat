//
//  MessagesViewController.swift
//  ChitChat
//
//  Created by next-shot on 3/7/17.
//  Copyright © 2017 next-shot. All rights reserved.
//

import UIKit
import AVFoundation

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
        if( !message.registeredForSave() ) {
            return "Unsent"
        } else {
           return longDate
        }
    } else {
        return message.fromName + " " + longDate
    }
}

class MessageCell : UICollectionViewCell, MessageBaseCellDelegate {
    weak var controller: MessagesViewController?

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var labelView: UIView!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    
    var message: Message?
    
    func userIcon() -> UIImageView? {
        return icon
    }
    func containerView() -> UIView? {
        return labelView
    }
    
    func initialize(message: Message, controller : MessagesViewController?) {
        self.message = message
        self.controller = controller
        
        textView.text = message.text
    
        fromLabel.text = getFromName(message: message)
        
        let bg = ColorPalette.backgroundColor(message: message)
        labelView.backgroundColor = bg
        
        editButton.isHidden = !(message.user_id.id == model.me().id.id &&
            controller?.data?.messages.last === message)
    }

    @IBAction func editAction(_ sender: Any) {
        guard let ctrler = controller else { return }
        ctrler.curMessage = message
        ctrler.textView.text = message?.text
        
        ctrler.enableCreateMessageButtons(state: false)
    }
}

class PictureMessageCell : UICollectionViewCell, MessageBaseCellDelegate  {
    var message: Message?
    weak var controller : MessagesViewController?
    
    @IBOutlet weak var labelView: UIView!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var decoratedImageView: DecoratedImageView!
    @IBOutlet weak var caption: UILabel!
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    
    func userIcon() -> UIImageView? {
        return icon
    }
    func containerView() -> UIView? {
        return labelView
    }
    func initialize(message: Message, controller : MessagesViewController?) {
        decoratedImageView.image = message.image
        self.message = message
        self.controller = controller
        
        let mo = MessageOptions(options: message.options)
        if( mo.theme == "no frame" || mo.theme.isEmpty ) {
            decoratedImageView.frameSize = 0
            decoratedImageView.setNeedsDisplay()
        } else {
            let theme = model.getTheme(name: mo.theme)
            if( theme != nil ) {
                model.getDecorationStamp(theme: theme!, completion: { (stamps) -> Void in
                    if( stamps.count >= 1 ) {
                        self.decoratedImageView.backgroundImage = stamps[0].image
                        self.decoratedImageView.frameSize = 8
                    }
                    DispatchQueue.main.async(execute: {
                        self.decoratedImageView.setNeedsDisplay()
                    })
                })
            }
        }
        
        caption.text = message.text
        fromLabel.text = getFromName(message: message)
        
        let bg = ColorPalette.backgroundColor(message: message)
        labelView.backgroundColor = bg
        
        editButton.isHidden = !(message.user_id.id == model.me().id.id &&
            controller?.data?.messages.last === message)

    }
    
    @IBAction func editAction(_ sender: Any) {
        guard let ctrler = controller else { return }
        ctrler.curMessage = message
        ctrler.textView.text = message?.text
        
        ctrler.enableCreateMessageButtons(state: false)
        
        // Allow editing of theme?
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
    @IBOutlet weak var editButton: UIButton!
    
    var waitingForImages = false
    weak var controller : MessagesViewController?
    var message: Message?
    var messageOption: MessageOptions?
    
    func containerView() -> UIView? {
        return labelView
    }
    
    func userIcon() -> UIImageView? {
        return icon
    }
    
    func initialize(message: Message, controller : MessagesViewController?) {
        self.controller = controller
        self.message = message
        
        textView.text = message.text
        
        func setTheme(string: String) {
            let theme = model.getTheme(name: string)
            if( theme != nil && waitingForImages == false ) {
                waitingForImages = true
                
                model.getDecorationStamp(theme: theme!, completion: { (stamps) -> Void in
                    var images = [UIImage]()
                    for s in stamps {
                        images.append(s.image)
                    }
                    self.textView.images = images
                    self.waitingForImages = false
                    DispatchQueue.main.async(execute: {
                         self.textView.setNeedsDisplay()
                    })
                })
            } else {
                self.textView.images = [UIImage]()
                self.textView.setNeedsDisplay()
            }
        }
        messageOption = MessageOptions(options: message.options)
        setTheme(string: messageOption!.theme)

        fromLabel.text = getFromName(message: message)
        
        let bg = ColorPalette.backgroundColor(message: message)
        labelView.backgroundColor = bg
        
        editButton.isHidden = !(message.user_id.id == model.me().id.id &&
                               controller?.data?.messages.last === message)
        
    }
    
    @IBAction func editAction(_ sender: Any) {
        guard let ctrler = controller else { return }
        guard let message = self.message else { return }
        ctrler.curMessage = message
        ctrler.textView.text = message.text
        
        // Allow editing of theme
        ctrler.decorationThemesView.isHidden = false
        ctrler.themesCollectionData!.themes = model.getDecorationThemes(category: "DecoratedText")
        ctrler.themesCollectionView.reloadData()
        ctrler.curMessageOption = messageOption
        
        let theme = messageOption!.theme
        let index = ctrler.themesCollectionData!.themes.index { (decorationTheme) -> Bool in
            return decorationTheme.name == theme
        }
        if( index != nil ) {
            // Select the current theme
            let indexPath = IndexPath(item: index!, section: 0)
            ctrler.themesCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .top)
        }
        
        // Re-layout stuff.
        ctrler.view.layoutIfNeeded()
        ctrler.messagesView.scrollToItem(
            at: IndexPath(row: ctrler.data!.messages.count-1, section: 0), at: UICollectionViewScrollPosition.bottom, animated: true
        )

        ctrler.enableCreateMessageButtons(state: false)
    }
}

/*****************************************************/

protocol MessageBaseCellSizeDelegate {
    func size(message: Message, collectionView: UICollectionView) -> CGSize
}

class TextMessageCellSizeDelegate : MessageBaseCellSizeDelegate {
    func size(message: Message, collectionView: UICollectionView) -> CGSize {
        let text = message.text
        //let nstext = NSString(string: text)
        
        let heightFromLabel : CGFloat = 16
        let spacing : CGFloat = 4
        let width = collectionView.bounds.width - 3*spacing
        let label = UITextView()
        //label.numberOfLines = 0
        //label.lineBreakMode = .byWordWrapping
        label.text = text
        label.font = UIFont.systemFont(ofSize: 17)
        //label.adjustsFontSizeToFitWidth = false
        
        let size = label.sizeThatFits(CGSize(width: width, height: 1500))
        //let rect = nstext.boundingRect(with: CGSize(width: width, height: 1500), options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 17)], context: nil)
        return CGSize(width: width, height: max(24,size.height) + 5*spacing + heightFromLabel)
    }
}

class DecoratedTextMessageCellSizeDelegate : TextMessageCellSizeDelegate {
    override func size(message: Message, collectionView: UICollectionView) -> CGSize {
        let text = message.text
        //let nstext = NSString(string: text)
       
        let heightFromLabel : CGFloat = 16
        let spacing : CGFloat = 5
        let width = collectionView.bounds.width - 3*spacing
        let label = DrawingTextView()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.text = text
        label.font = UIFont.systemFont(ofSize: 17)
        
        let size = label.computeSize(CGSize(width: width, height: 1500))
        
        return CGSize(width: width, height: size.height + 4*spacing + heightFromLabel)
    }
}

class ImageMessageCellSizeDelegate : MessageBaseCellSizeDelegate {
    func size(message: Message, collectionView: UICollectionView) -> CGSize {
        let spacing : CGFloat = 10
        let width = collectionView.bounds.width - 3*spacing
        return CGSize(width: width, height: 234)
    }
}

class ThumbUpMessageCellSizeDelegate : MessageBaseCellSizeDelegate {
    func size(message: Message, collectionView: UICollectionView) -> CGSize {
        let spacing : CGFloat = 10
        let width = collectionView.bounds.width - 3*spacing
        return CGSize(width: width, height: 60)
    }
}

class MessageCellFactory {
    enum messageType { case text, image, thumbUp, textDecorated, polling }
    
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
            } else if( options.type == "poll" ) {
                return .polling
            } else if( options.type == "thumb-up" ) {
                return .thumbUp
            }
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
        case .image:
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: "PictureMessageCell", for: indexPath
            )
        case .thumbUp:
            return collectionView.dequeueReusableCell(
                    withReuseIdentifier: "ThumbUpMessageCell", for: indexPath
            )
        case .polling:
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: "PollMessageCell", for: indexPath
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
        case .image:
            return ImageMessageCellSizeDelegate()
        case .thumbUp:
            return ThumbUpMessageCellSizeDelegate()
        case .polling:
            return PollMessageCellSizeDelegate()
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
                
                self.controller!.continueEditing()
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
    var themes = [DecorationTheme]()
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
        cell.label.text = themes[indexPath.item].name
        
        cell.layer.masksToBounds = true
        cell.layer.cornerRadius = 6
        cell.layer.borderColor = ColorPalette.colors[.borderColor]?.cgColor
        cell.layer.borderWidth = 1.0
        
        cell.layer.backgroundColor = nil
        let selectItems = collectionView.indexPathsForSelectedItems
        if( selectItems != nil && selectItems!.count > 0 ) {
            if( selectItems![0] == indexPath ) {
                cell.layer.backgroundColor = ColorPalette.colors[ColorPalette.States.unread]?.cgColor
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if( controller != nil && controller!.curMessage != nil ) {
            let m = controller!.curMessage!
            let mo = controller!.curMessageOption!
        
            mo.theme = themes[indexPath.item].name
            
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
        label.text = themes[indexPath.item].name
        label.font = UIFont.systemFont(ofSize: 17)
        
        let size = label.sizeThatFits(CGSize(width: 1000, height: 1500))
        return CGSize(width: size.width + spacing, height: size.height + spacing)
    }
    
}

/******************************************************************************/

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
            if( c.curMessage != nil ) {
                c.curMessage!.text = view.text
                c.curMessage!.last_modified = Date()
                
                let indexPath = IndexPath(row: c.data!.messages.count-1, section: 0)
                c.messagesView.reloadItems(at: [indexPath])
                c.messagesView.scrollToItem(at: indexPath, at: .bottom, animated: true)
            }
            c.sendButton.isEnabled = !view.text.isEmpty
            c.spellCheckButton.setImage(UIImage(named:"spellchecked32x32"), for: .normal)
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
    @IBOutlet weak var forkAndSendButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var selectPictureButton: UIButton!
    @IBOutlet weak var takePictureButton: UIButton!
    @IBOutlet weak var sendDecoratedMessage: UIButton!
    @IBOutlet weak var spellCheckButton: UIButton!
    
    var data : MessagesData?
    var delegate : MessagesViewDelegate?
    var conversationThread : ConversationThread?
    var curMessage: Message?
    var curMessageOption: MessageOptions?
    var modelView : MessagesDataView?
    var themesCollectionData : DecoratedMessageThemesPickerSource?
    var textViewDelegate : MessagesViewGrowingTextViewDelegate?
    var audioPlayer = AVAudioPlayer()
    var tapper : UITapGestureRecognizer?
    var spellCheckerInputTextViewAccessory: InputTextViewAccessoryViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.themesCollectionData = DecoratedMessageThemesPickerSource(controller: self)
        self.themesCollectionView.delegate = self.themesCollectionData
        self.themesCollectionView.dataSource = themesCollectionData
        
        model.getDecorationThemes(completion: { (themes) -> Void in
            // Add in Memory decorations
            model.addDecoration(theme: "no frame", category: "DecoratedImage", stamps: [])
            model.addDecoration(theme: "wood pine frame", category: "DecoratedImage", stamps: ["purty_wood"])
            model.addDecoration(theme: "dark wood frame", category: "DecoratedImage", stamps: ["dark_wood"])
            model.addDecoration(theme: "aluminium frame", category: "DecoratedImage", stamps: ["aluminium"])
            model.addDecoration(theme: "gold frame", category: "DecoratedImage", stamps: ["gold_frame"])

            // Once the theme collection is there we can load the messages.
            // Manage the collection view.
            model.getMessagesForThread(thread: self.conversationThread!, completion: { (messages) -> Void in
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
        
        textViewDelegate = MessagesViewGrowingTextViewDelegate(controller: self)
        textView.delegates = textViewDelegate!
        
        sendButton.isEnabled = false
        
        let url = Bundle.main.url(forResource: "sounds/Button_Press", withExtension: "wav")
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url!)
            audioPlayer.prepareToPlay()
        } catch {
            print("Problem in getting Audio File")
        }
        
        tapper = UITapGestureRecognizer(target: self, action:#selector(endEditingWithTouch))
        tapper!.cancelsTouchesInView = false
        messagesView.addGestureRecognizer(tapper!)

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
    
    func completeAfterSave(message: Message) {
        DispatchQueue.main.async(execute: {
            let index = self.data!.messages.index(where: { (im) -> Bool in
                return im.id == message.id
            })
            if( index != nil ) {
                self.messagesView.reloadItems(at: [IndexPath(row: index!, section: 0)])
            }
        })
    }
    
    @IBAction func handleSendButton(_ sender: Any) {
        
        // Create Message
        if( curMessage == nil ) {
            let m = Message(thread: conversationThread!, user: model.me())
            m.text = self.textView.text
            
            // Add it to DB
            model.saveMessage(message: m, completion: {
                self.completeAfterSave(message: m)
            })
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
            
            // Add it to DB
            if( curMessageOption?.pollRecord != nil ) {
                model.savePollVote(pollRecord: curMessageOption!.pollRecord!)
            }
            
            let m = curMessage!
            model.saveMessage(message: m, completion: {
                self.completeAfterSave(message: m)
            })
            model.updateMyActivity(
                thread: conversationThread!, date: curMessage!.last_modified, withNewMessage: curMessage!
            )
            
            // Reset placeholder
            self.textView.placeholderAttributedText = NSAttributedString(
                string: "Type a message...",
                attributes: [NSForegroundColorAttributeName: UIColor.gray, NSFontAttributeName: self.textView.font!]
            )
        }
        
        audioPlayer.play()
        
        self.textView.text = ""
        self.view.endEditing(true)
        self.sendButton.isEnabled = false
        self.curMessage = nil
        self.curMessageOption = nil
        
        enableCreateMessageButtons(state: true)
        
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
                let newThread = ConversationThread(id: RecordId(), group_id: self.conversationThread!.group_id, user_id: model.me().id)
                newThread.title = textField.text!
                model.saveConversationThread(conversationThread: newThread)
                
                var messages = [Message]()
                if( self.curMessage != nil ) {
                    self.curMessage!.conversation_id = newThread.id
                    messages.append(self.curMessage!)
                }
                
                // Update UI
                self.title = newThread.title
                // Manage the collection view.
                self.conversationThread = newThread
                self.data = MessagesData(thread: self.conversationThread!, messages: messages, ctrler: self)
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
        m.text = "Thumb-up"
        m.options = MessageOptions(type: "thumb-up").getString()!
        
        // Add it to DB
        model.saveMessage(message: m, completion: {
            self.completeAfterSave(message: m)
        })
        model.updateMyActivity(
            thread: conversationThread!, date: m.last_modified, withNewMessage: m
        )
        
        // Add it to interface
        data?.messages.append(m)
        let index = IndexPath(row: self.data!.messages.count-1, section: 0)
        self.messagesView.insertItems(at: [index])
        self.messagesView.scrollToItem(at: index, at: UICollectionViewScrollPosition.bottom, animated: true)
        
        audioPlayer.play()
    }
    
    func enableCreateMessageButtons(state: Bool) {
        selectPictureButton.isEnabled = state
        takePictureButton.isEnabled = state
        sendDecoratedMessage.isEnabled = state
    }
    
    func continueEditing() {
        // Received a text while editing another message, 
        // Reset correctly the UI.
        if( curMessage != nil && !(curMessage!.registeredForSave()) ) {
            // Add it to interface
            data?.messages.append(curMessage!)
            messagesView.insertItems(at: [IndexPath(row: data!.messages.count-1, section: 0)])
            
            messagesView.scrollToItem(at: IndexPath(row: data!.messages.count-1, section: 0), at: UICollectionViewScrollPosition.bottom, animated: true)
        }
    }
    
    @IBAction func handleSendPicture(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        //picker.allowsEditing = true (broken on IPad)
        picker.sourceType = .photoLibrary
        
        present(picker, animated: true, completion: nil)
    }
    
    @IBAction func handleSendCameraPicture(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        //picker.allowsEditing = true (broken on IPad)
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
            
            curMessageOption = MessageOptions(type: "decoratedImage")
            curMessageOption!.decorated = true
            m.options = curMessageOption!.getString() ?? ""
            
            // Add it to interface
            data?.messages.append(m)
            messagesView.insertItems(at: [IndexPath(row: data!.messages.count-1, section: 0)])
            
            // Handle decoration management
            decorationThemesView.isHidden = false
            themesCollectionData!.themes = model.getDecorationThemes(category: "DecoratedImage")
            themesCollectionView.reloadData()
            themesCollectionView.selectItem(at: nil, animated: false, scrollPosition: .top)
            
            // Re-layout stuff
            self.view.layoutIfNeeded()

            messagesView.scrollToItem(at: IndexPath(row: data!.messages.count-1, section: 0), at: UICollectionViewScrollPosition.bottom, animated: true)
            
            if( data!.messages.count > 2 ) {
                messagesView.reloadItems(at: [IndexPath(row: data!.messages.count-2, section: 0)])
            }
            
            curMessage = m
            
            // Disable creation of other message until this one is done
            enableCreateMessageButtons(state: false)
            self.sendButton.isEnabled = true
            
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
        themesCollectionData!.themes = model.getDecorationThemes(category: "DecoratedText")
        themesCollectionView.reloadData()
        themesCollectionView.selectItem(at: nil, animated: false, scrollPosition: .top)

        self.view.layoutIfNeeded()
        messagesView.scrollToItem(
            at: IndexPath(row: data!.messages.count-1, section: 0), at: UICollectionViewScrollPosition.bottom, animated: true
        )
        if( data!.messages.count > 2 ) {
            messagesView.reloadItems(at: [IndexPath(row: data!.messages.count-2, section: 0)])
        }
        
        curMessage = m
        
        // Disable creation of other message until this one is done
        enableCreateMessageButtons(state: false)
    }

    @IBAction func handleSpellCheck(_ sender: UIButton) {
        let activityView = UIActivityIndicatorView(activityIndicatorStyle: .white)
        activityView.color = UIColor.blue
        activityView.center = sender.center
        activityView.startAnimating()
        sender.addSubview(activityView)
        
        let checker = SpellChecker(textView: textView)
        checker.check(completion: { (issues) -> () in
            DispatchQueue.main.async(execute: {
                if( issues.count > 0 ) {
                    sender.setImage(UIImage(named: "spellchecked_bad"), for: .normal)
                    
                    // Not sufficiently helpfull
                    //self.spellCheckerInputTextViewAccessory = InputTextViewAccessoryViewController(textView: self.textView, issues: issues)
                    //self.spellCheckerInputTextViewAccessory?.createToolbar(controller: self)
                } else {
                    sender.setImage(UIImage(named: "spellchecked_ok"), for: .normal)
                }
            
                activityView.stopAnimating()
                activityView.removeFromSuperview()
            })
        })
    }
    
    @IBAction func handleSendPoll(_ sender: Any) {
        // Create Message
        let m = Message(thread: conversationThread!, user: model.me())
        m.text = self.textView.text
        
        curMessageOption = MessageOptions(type: "poll")
        curMessageOption!.pollOptions = ["choice #1", "choice #2"]
        curMessageOption!.pollRecord = PollRecord(id: RecordId(), user_id: model.me().id, poll_id: m.id, checked_option: -1)
        
        m.options = curMessageOption!.getString() ?? ""
        
        // Add it to interface
        data?.messages.append(m)
        messagesView.insertItems(at: [IndexPath(row: data!.messages.count-1, section: 0)])
    
        messagesView.scrollToItem(
            at: IndexPath(row: data!.messages.count-1, section: 0), at: UICollectionViewScrollPosition.bottom, animated: true
        )
        if( data!.messages.count > 2 ) {
            messagesView.reloadItems(at: [IndexPath(row: data!.messages.count-2, section: 0)])
        }
        
        curMessage = m
        
        // Disable creation of other message until this one is done
        enableCreateMessageButtons(state: false)
        self.sendButton.isEnabled = false
        
        self.textView.placeholderAttributedText = NSAttributedString(
            string: "Enter the poll reason...",
            attributes: [NSForegroundColorAttributeName: UIColor.gray, NSFontAttributeName: self.textView.font!]
        )
    }
    
    // Keyboard handling
    func keyboardWillHide(_ sender: Notification) {
        if let userInfo = (sender as NSNotification).userInfo {
            if let _ = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height {
                //key point 0,
                self.bottomConstraint.constant = 0
            
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
                    if( self.data!.messages.count > 1 ) {
                        self.messagesView.scrollToItem(at: IndexPath(row: self.data!.messages.count-1, section: 0), at: UICollectionViewScrollPosition.bottom, animated: true)
                    }
                })
            }
        }
    }

    func endEditingWithTouch() {
        _ = textView.resignFirstResponder()
    }
}

