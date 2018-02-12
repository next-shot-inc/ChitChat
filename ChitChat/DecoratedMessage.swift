//
//  DecoratedMessage.swift
//  ChitChat
//
//  Created by next-shot on 1/25/18.
//  Copyright © 2018 next-shot. All rights reserved.
//

import Foundation
import UIKit

/***********************************************************************/
// Theme collection classes - To handle selection of current decoration theme
// At the bottom of the MessagesViewController.

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

/***********************************************************************************************************/

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


/***********************************************************************************************************/

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

