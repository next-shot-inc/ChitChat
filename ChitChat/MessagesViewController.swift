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
    @IBOutlet weak var messageBoxTopSpace: NSLayoutConstraint!
    @IBOutlet weak var messageBoxLeftSpace: NSLayoutConstraint!
    @IBOutlet weak var messageBoxBottomSpace: NSLayoutConstraint!
    @IBOutlet weak var messageBoxRightSpace: NSLayoutConstraint!
    
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
        
        editButton.isHidden = !(message.user_id.id == model.me().id.id &&
            controller?.data?.messages.last === message)
        
        if( settingsDB.settings.round_bubbles == false ) {
            messageBoxTopSpace.constant = 4
            messageBoxBottomSpace.constant = 4
            messageBoxLeftSpace.constant = 4
            messageBoxRightSpace.constant = 4
        }
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
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
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
            
            decoratedImageView!.layer.masksToBounds = true
            decoratedImageView!.layer.cornerRadius = 6
        } else {
            let theme = model.getTheme(name: mo.theme)
            if( theme != nil ) {
                model.getDecorationStamp(theme: theme!, completion: { (stamps) -> Void in
                    if( stamps.count >= 1 ) {
                        self.decoratedImageView.backgroundImage = stamps[0].image
                        let v = theme?.options?["framesize"] as? NSNumber
                        self.decoratedImageView.frameSize = CGFloat(v?.intValue ?? 8)
                    }
                    DispatchQueue.main.async(execute: {
                        self.decoratedImageView.setNeedsDisplay()
                    })
                })
            }
        }
        
        caption.text = message.text
        fromLabel.text = getFromName(message: message)
        
        editButton.isHidden = !(message.user_id.id == model.me().id.id &&
            controller?.data?.messages.last === message)

        if( message.registeredForSave() && message.unsaved() ) {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
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
    
    @IBOutlet weak var labelView: BubbleView!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var fromLabel: UILabel!
    
    func containerView() -> UIView? {
        return labelView
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
    @IBOutlet weak var messageBoxBottomSpace: NSLayoutConstraint!
    @IBOutlet weak var messageBoxRightSpace: NSLayoutConstraint!
    @IBOutlet weak var messageBoxTopSpace: NSLayoutConstraint!
    @IBOutlet weak var messageBoxLeftSpace: NSLayoutConstraint!
    
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
        
        editButton.isHidden = !(message.user_id.id == model.me().id.id &&
                               controller?.data?.messages.last === message)
        
        if( settingsDB.settings.round_bubbles == false ) {
            messageBoxTopSpace.constant = 4
            messageBoxBottomSpace.constant = 4
            messageBoxLeftSpace.constant = 4
            messageBoxRightSpace.constant = 4
        }
        
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
        
        let bubblevSpacing: CGFloat = settingsDB.settings.round_bubbles ? 40 : 0
        let bubblehSpacing: CGFloat = settingsDB.settings.round_bubbles ? 50 : 0
        let heightFromLabel : CGFloat = 16
        let hspacing : CGFloat = 10
        let vspacing : CGFloat = 4
        let width = collectionView.bounds.width - 2*hspacing
        let label = UITextView()
        //label.numberOfLines = 0
        //label.lineBreakMode = .byWordWrapping
        label.text = text
        label.font = UIFont.systemFont(ofSize: 17)
        //label.adjustsFontSizeToFitWidth = false
        
        let size = label.sizeThatFits(CGSize(width: width - bubblehSpacing, height: 1500))
        //let rect = nstext.boundingRect(with: CGSize(width: width, height: 1500), options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 17)], context: nil)
        return CGSize(
            width: width,
            height: max(24,size.height) + 3*vspacing + heightFromLabel + bubblevSpacing
        )
    }
}

class DecoratedTextMessageCellSizeDelegate : TextMessageCellSizeDelegate {
    override func size(message: Message, collectionView: UICollectionView) -> CGSize {
        let text = message.text
        //let nstext = NSString(string: text)
       
        let bubblevSpacing: CGFloat = settingsDB.settings.round_bubbles ? 60 : 0
        let bubblehSpacing: CGFloat = settingsDB.settings.round_bubbles ? 40 : 0
        let heightFromLabel : CGFloat = 16
        let hspacing : CGFloat = 10
        let vspacing : CGFloat = 4
        let width = collectionView.bounds.width - 2*hspacing
        let label = DrawingTextView()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.text = text
        label.font = UIFont.systemFont(ofSize: 17)
        
        let size = label.computeSize(CGSize(width: width - bubblehSpacing, height: 1500))
        
        return CGSize(width: width, height: size.height + 4*vspacing + heightFromLabel + bubblevSpacing)
    }
}

class ImageMessageCellSizeDelegate : MessageBaseCellSizeDelegate {
    func size(message: Message, collectionView: UICollectionView) -> CGSize {
        let text = message.text
        
        var frameSize : CGFloat = 0
        let mo = MessageOptions(options: message.options)
        if( mo.theme == "no frame" || mo.theme.isEmpty ) {
            frameSize = 0
        } else {
            let theme = model.getTheme(name: mo.theme)
            let v = theme?.options?["framesize"] as? NSNumber
            frameSize = CGFloat(v?.intValue ?? 8)
        }
        //let nstext = NSString(string: text)
        
        let bubblevSpacing : CGFloat = 0 // 45
        let bubblehSpacing: CGFloat = 0 // 20
        let imageSize : CGFloat = 180 + 2*frameSize
        let heightFromLabel : CGFloat = 16
        let hspacing : CGFloat = 10
        let vspacing : CGFloat = 4
        let width = collectionView.bounds.width - 2*hspacing
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.text = text
        label.font = UIFont.systemFont(ofSize: 15)

        let size = label.sizeThatFits(CGSize(width: width - bubblehSpacing, height: 1500))
    
        return CGSize(width: width, height: imageSize + heightFromLabel + 5*vspacing + size.height + bubblevSpacing)
    }
}

class ThumbUpMessageCellSizeDelegate : MessageBaseCellSizeDelegate {
    func size(message: Message, collectionView: UICollectionView) -> CGSize {
        let hspacing : CGFloat = 10
        let width = min(300, collectionView.bounds.width - 2*hspacing)
        return CGSize(width: width, height: 65)
    }
}

class MessageCellFactory {
    enum messageType { case text, image, thumbUp, textDecorated, polling, expenseTab }
    
    class func getType(message: Message, collectionView: UICollectionView, indexPath: IndexPath) -> messageType {
        if( message.image != nil ) {
            return .image
        }
        if( message.text == "%%Thumb-up%%" ) {
            return .thumbUp
        }
        if( !message.options.isEmpty ) {
            let options = MessageOptions(options: message.options)
            if( options.type == "decoratedText" ) {
                return .textDecorated
            } else if( options.type == "poll" ) {
                return .polling
            } else if( options.type == "thumb-up" ) {
                return .thumbUp
            } else if( options.type == "expense-tab" ) {
                return .expenseTab
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
        case .expenseTab:
            return collectionView.dequeueReusableCell(
                withReuseIdentifier:  "ExpenseMessageCell", for: indexPath
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
        case .expenseTab:
            return ExpenseMessageCellSizeDelegate()
        }
    }
}

class MessagesData : MessageCollectionViewHelper, UICollectionViewDataSource {
    //var sections = [[Message]](repeating: [Message](), count: 4)
    //enum sectionType : Int { case today = 3, yesterday = 2, this_week = 1, prev_weeks = 0 }
    weak var controller : MessagesViewController?
    
    init(thread: ConversationThread, messages: [Message], dateLimit: MessageDateRange, ctrler: MessagesViewController) {
        super.init(cthread: thread)
        self.scrollingPosition = .bottom
        self.messages = messages
        self.dateLimit = dateLimit
        controller = ctrler
        
        //set(messages:  messages)
    }
    
    /*
    func set(messages: [Message]) {
        let calendar = Calendar(identifier: .gregorian)
        let dtoday = Date()
        let day_of_today = calendar.component(.day, from: dtoday)
        let week_of_today = calendar.component(.weekOfMonth, from: dtoday)
        
        for m in messages {
            let date = m.last_modified
            let m_day = calendar.component(.day, from: date)
            let m_week = calendar.component(.weekOfMonth, from: date)
            if( m_day == day_of_today ) {
                sections[sectionType.today.rawValue].append(m)
            } else if( m_day == day_of_today-1 ) {
                sections[sectionType.yesterday.rawValue].append(m)
            } else if( m_week == week_of_today ) {
                sections[sectionType.this_week.rawValue].append(m)
            } else {
                sections[sectionType.prev_weeks.rawValue].append(m)
            }
        }
    }
    */
    
    subscript(indexPath: IndexPath) -> Message {
        return messages[indexPath.row]
    }
    
    func lastMessageIndex() -> IndexPath {
        return IndexPath(row: messages.count-1, section: 0)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1 //sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count // sections[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let m = self[indexPath]
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
            let bg = ColorPalette.backgroundColor(message: message)
            let bubbleView = uiView as? BubbleView
            if( bubbleView != nil && settingsDB.settings.round_bubbles ) {
                bubbleView!.fillColor = bg
                bubbleView!.strokeColor = ColorPalette.colors[.borderColor]
                bubbleView!.strokeWidth = ColorPalette.lineWidth(message: message)*2
                bubbleView!.setNeedsDisplay()
            } else {
                if( bubbleView != nil ) {
                    bubbleView!.strokeColor = UIColor.clear
                }
                // Shadow and rounded corners.
                uiView!.layer.cornerRadius = 6
                uiView!.layer.masksToBounds = true
                uiView!.backgroundColor = UIColor.clear
                uiView!.layer.backgroundColor = bg.cgColor
                
                uiView!.layer.borderColor = ColorPalette.colors[.borderColor]?.cgColor
                uiView!.layer.borderWidth = ColorPalette.lineWidth(message: message)
                
                uiView!.layer.masksToBounds = false
                uiView!.layer.shadowOpacity = 0.5
                uiView!.layer.shadowOffset = CGSize(width: 1.0, height: 1.0)
                uiView!.layer.shadowRadius = 2
            }
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
                self.controller!.messagesView.scrollToItem(at: self.controller!.data!.lastMessageIndex(), at: UICollectionViewScrollPosition.bottom, animated: true)
                
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

class MessagesViewDelegate : NSObject, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    let messageData : MessagesData
    weak var controller : MessagesViewController?
    
    init(data: MessagesData, ctrler: MessagesViewController) {
        messageData = data
        controller = ctrler
    }
    
    // Compute the size of a message
    func collectionView(
        _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let m = messageData.messages[indexPath.row]
        let sizer = MessageCellFactory.sizer(message: m, collectionView: collectionView, indexPath: indexPath)
        return sizer.size(message: m, collectionView: collectionView)
    }
    
    // Let the user select a image based message to display the image in a separate window.
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let m = messageData.messages[indexPath.row]
        if( m.image != nil ) {
            return true
        } else {
            return false
        }
    }
    
    // Perform the segue to the show picture controller.
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let m = messageData.messages[indexPath.row]
        controller?.selectedMessage = m
        if( m.image != nil ) {
            controller?.performSegue(withIdentifier: "showPicture", sender: self)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if( scrollView.contentOffset.y <= 0 ) {
            messageData.requestMore(collectionView: scrollView as! UICollectionView)
        }
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
    
    // Initialize message option from selected theme.
    // Highlight selected cell
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
    
    // Unhighlight unselected cell.
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        // Update selected theme cell
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.layer.backgroundColor = nil
    }
    
    // Return item size
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
            c.sendButton.isEnabled = !view.text.isEmpty && (c.curMessageOption == nil || c.curMessageOption!.valid())
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
    @IBOutlet weak var sendPollButton: UIButton!
    @IBOutlet weak var spellCheckButton: UIButton!
    @IBOutlet weak var sendThumbUpButton: UIButton!
    @IBOutlet weak var cancelCurButton: UIButton!
    @IBOutlet weak var showMoreButton: UIButton!
    @IBOutlet weak var moreOptionsView: UIView!
    
    
    var data : MessagesData?
    var dateLimit = MessageDateRange(min: 0, max: 5)
    var delegate : MessagesViewDelegate?
    var conversationThread : ConversationThread?
    var curMessage: Message?
    var selectedMessage : Message?
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
            model.addDecoration(
                theme: "wood pine frame", category: "DecoratedImage", stamps: ["purty_wood"],
                options: ["framesize": 12]
            )
            model.addDecoration(theme: "dark wood frame", category: "DecoratedImage", stamps: ["dark_wood"],
                options: ["framesize" : 12]
            )
            model.addDecoration(theme: "aluminium frame", category: "DecoratedImage", stamps: ["aluminium"])
            model.addDecoration(theme: "gold frame", category: "DecoratedImage", stamps: ["gold_frame"])
            model.addDecoration(
                theme: "flower frame", category: "DecoratedImage", stamps: ["flower frame"],
                options: ["framesize" : 14]
            )
            model.addDecoration(
                theme: "birds frame", category: "DecoratedImage", stamps: ["birds frame"],
                options: ["framesize" : 14]
            )
            model.addDecoration(
                theme: "butterflies frame", category: "DecoratedImage", stamps: ["butterflies frame"],
                options: ["framesize" : 18]
            )

            // Once the theme collection is there we can load the messages.
            // Manage the collection view.
            model.getMessagesForThread(thread: self.conversationThread!, dateLimit: self.dateLimit, completion: { (messages, dateLimit) in
                self.data = MessagesData(
                    thread: self.conversationThread!, messages: messages, dateLimit: dateLimit, ctrler: self
                )
                
                
                DispatchQueue.main.async(execute: {
                    self.messagesView.dataSource = self.data
                    self.delegate = MessagesViewDelegate(data: self.data!, ctrler: self)
                    self.messagesView.delegate = self.delegate
                    
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
            attributes: [NSAttributedStringKey.foregroundColor: UIColor.gray, NSAttributedStringKey.font: self.textView.font!]
        )
        
        modelView = MessagesDataView(ctrler: self)
        decorationThemesView.isHidden = true
        
        textViewDelegate = MessagesViewGrowingTextViewDelegate(controller: self)
        textView.delegates = textViewDelegate!
        
        sendButton.isEnabled = false
        cancelCurButton.isHidden = true
        moreOptionsView.isHidden = true
        
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
                attributes: [NSAttributedStringKey.foregroundColor: UIColor.gray, NSAttributedStringKey.font: self.textView.font!]
            )
            
            if( data!.messages.count > 2 ) {
               messagesView.reloadItems(at: [IndexPath(row: data!.messages.count-2, section: 0)])
            }
            messagesView.reloadItems(at: [IndexPath(row: data!.messages.count-1, section: 0)])
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
        let lastCellIndex = IndexPath(row: data!.messages.count-1, section: 0)
        messagesView.scrollToItem(
            at: lastCellIndex, at: UICollectionViewScrollPosition.bottom, animated: true
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
                self.data = MessagesData(thread: self.conversationThread!, messages: messages,
                                         dateLimit: MessageDateRange(min: 0, max: 1), ctrler: self)
                self.messagesView.dataSource = self.data
                self.delegate = MessagesViewDelegate(data: self.data!, ctrler: self)
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
        showMoreButton.isEnabled = state
        sendThumbUpButton.isEnabled = state
        cancelCurButton.isHidden = state
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
        if( UIImagePickerController.isSourceTypeAvailable(.photoLibrary)) {
            let picker = UIImagePickerController()
            picker.delegate = self
            //picker.allowsEditing = true (broken on IPad)
            picker.sourceType = .photoLibrary
        
            present(picker, animated: true, completion: nil)
        }
    }
    
    @IBAction func handleSendCameraPicture(_ sender: Any) {
        if( UIImagePickerController.isSourceTypeAvailable(.camera) ) {
            let picker = UIImagePickerController()
            picker.delegate = self
            //picker.allowsEditing = true (broken on IPad)
            picker.sourceType = .camera
            present(picker, animated: true, completion: nil)
        }
    }
    
    @IBAction func handleCancelButton(_ sender: Any) {
        if( curMessage != nil ) {
            let lastCellIndex = IndexPath(row: data!.messages.count-1, section: 0)
            data?.messages.removeLast()
            messagesView.deleteItems(at: [lastCellIndex])
        }
        self.textView.text = ""
        self.view.endEditing(true)
        self.sendButton.isEnabled = false
        self.curMessage = nil
        self.curMessageOption = nil
        
        enableCreateMessageButtons(state: true)
        
        decorationThemesView.isHidden = true
        self.view.layoutIfNeeded()
        let lastCellIndex = IndexPath(row: data!.messages.count-1, section: 0)
        messagesView.scrollToItem(
            at: lastCellIndex, at: UICollectionViewScrollPosition.bottom, animated: true
        )
        
        self.textView.placeholderAttributedText = NSAttributedString(
            string: "Type a message...",
            attributes: [NSAttributedStringKey.foregroundColor: UIColor.gray, NSAttributedStringKey.font: self.textView.font!]
        )
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
            
            let defaultPictureSize = CGSize(width: 1024, height: 1024)
            let storageSize = defaultPictureSize
            let sx = storageSize.width/size.width
            let sy = storageSize.height/size.height
            let scale = min(sx, sy)
            let image = selectedImage!.resize(newSize: CGSize(width: size.width*scale, height: size.height*scale))
            
            let thumbImageSize = CGSize(width: 234, height: 166)
            let tsx = thumbImageSize.width/size.width
            let tsy = thumbImageSize.height/size.height
            let tscale = min(tsx, tsy)
            let timage = selectedImage!.resize(newSize: CGSize(width: size.width*tscale, height: size.height*tscale))
            
            // Create Message
            let m = Message(thread: conversationThread!, user: model.me())
            m.text = self.textView.text
            m.largeImage = image
            m.image = timage
            
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
                attributes: [NSAttributedStringKey.foregroundColor: UIColor.gray, NSAttributedStringKey.font: self.textView.font!]
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
        
        // Handle decoration management
        decorationThemesView.isHidden = false
        themesCollectionData!.themes = model.getDecorationThemes(category: "DecoratedText")
        themesCollectionView.reloadData()
        themesCollectionView.selectItem(at: nil, animated: false, scrollPosition: .top)
        
        // Re-layout stuff
        self.view.layoutIfNeeded()
        
        handleCreatedMessage(message: m, placeHolder: "message's text")
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
        curMessageOption!.pollRecord = PollRecord(message: m, user: model.me(), checked_option: -1)
        
        handleCreatedMessage(message: m, placeHolder: "Enter the poll reason...")
    }
    
    @IBAction func handleSendExpenseTab(_ sender: Any) {
        // Create Message
        let m = Message(thread: conversationThread!, user: model.me())
        m.text = self.textView.text
        
        curMessageOption = MessageOptions(type: "expense-tab")
        m.options = curMessageOption!.getString() ?? ""
        
        handleCreatedMessage(message: m, placeHolder: "Enter the expense tab name...")
    }
    
    @IBAction func handleSendRSVP(_ sender: Any) {
        // Create Message
        let m = Message(thread: conversationThread!, user: model.me())
        m.text = self.textView.text
        
        curMessageOption = MessageOptions(type: "poll")
        curMessageOption!.pollOptions = ["Yes", "No", "Maybe"]
        curMessageOption!.pollRecord = PollRecord(message: m, user: model.me(), checked_option: 0)
        curMessageOption!.decorated = true
        
        handleCreatedMessage(message: m, placeHolder: "Enter the RSVP message...")
    }
    
    @IBAction func showMoreOptionsAction(_ sender: Any) {
         self.moreOptionsView.isHidden = !self.moreOptionsView.isHidden
    }
    
    func handleCreatedMessage(message: Message, placeHolder: String) {
        message.options = curMessageOption!.getString() ?? ""
        
        // Add it to interface
        data?.messages.append(message)
        messagesView.insertItems(at: [IndexPath(row: data!.messages.count-1, section: 0)])
        
        messagesView.scrollToItem(
            at: IndexPath(row: data!.messages.count-1, section: 0), at: UICollectionViewScrollPosition.bottom, animated: true
        )
        if( data!.messages.count > 2 ) {
            messagesView.reloadItems(at: [IndexPath(row: data!.messages.count-2, section: 0)])
        }
        
        curMessage = message
        
        // Disable creation of other message until this one is done
        enableCreateMessageButtons(state: false)
        self.sendButton.isEnabled = false
        
        self.textView.placeholderAttributedText = NSAttributedString(
            string: placeHolder,
            attributes: [NSAttributedStringKey.foregroundColor: UIColor.gray, NSAttributedStringKey.font: self.textView.font!]
        )

        self.moreOptionsView.isHidden = true
    }
    
    // Keyboard handling
    @objc func keyboardWillHide(_ sender: Notification) {
        if let userInfo = (sender as NSNotification).userInfo {
            if let _ = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height {
                //key point 0,
                self.bottomConstraint.constant = 0
            
                //textViewBottomConstraint.constant = keyboardHeight
                UIView.animate(withDuration: 0.25, animations: { () -> Void in self.view.layoutIfNeeded() })
            }
        }
    }
    @objc func keyboardWillShow(_ sender: Notification) {
        if let userInfo = (sender as NSNotification).userInfo {
            if let keyboardHeight = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height {
                self.bottomConstraint.constant = keyboardHeight
                UIView.animate(withDuration: 0.25, animations: { () -> Void in
                    self.view.layoutIfNeeded()
                    if( self.data!.messages.count > 1 ) {
                        self.messagesView.scrollToItem(at: self.data!.lastMessageIndex(), at: UICollectionViewScrollPosition.bottom, animated: true)
                    }
                })
            }
        }
    }

    @objc func endEditingWithTouch() {
        _ = textView.resignFirstResponder()
        moreOptionsView.isHidden = true
    }
    
    // Segue to show Picture
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if( segue.identifier == "showPicture" ) {
            let pc = segue.destination as? PictureViewController
            if( pc != nil ) {
                pc!.message = selectedMessage
            }
        }
        if( segue.identifier == "showExpenseDetails" ) {
            let edc = segue.destination as? ExpenseDetailsTableViewController
            if( edc != nil ) {
                if( selectedMessage != nil ) {
                    edc!.title = "Details of " + selectedMessage!.text
                }
                edc!.message = selectedMessage
            }
        }
    }
}

