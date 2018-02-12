//
//  NewConversationsCell.swift
//  ChitChat
//
//  Created by next-shot on 1/26/18.
//  Copyright © 2018 next-shot. All rights reserved.
//

import Foundation
import UIKit

class BaseNewConversationButtonCell : UICollectionViewCell {
    weak var ctrler: ThreadsViewController?
    
    func activate(ctrler: ThreadsViewController) {
        let newThread = ConversationThread(
            id: RecordId(), group_id: ctrler.group!.id, user_id: model.me().id
        )
        model.saveConversationThread(conversationThread: newThread)
        
        ctrler.selectedConversationThread = newThread
        
        // Create first message
        let message = Message(thread: newThread, user: model.me())
        let messageOptions = getOptions(message: message)
        ctrler.selectedCurMessage = message
        ctrler.selectedCurMessageOptions = messageOptions
        ctrler.selectedCurMessagePlaceHolder = getPlaceHolder()
        
        ctrler.performSegue(withIdentifier: "messageSegue", sender: self)
    }
    
    func getOptions(message: Message) -> MessageOptions? {
        return nil
    }
    
    func getPlaceHolder() -> String? {
        return nil
    }
}

class NewConversationButtonCell : BaseNewConversationButtonCell  {
    
    @IBAction func activate(_ sender: Any) {
        activate(ctrler: ctrler!)
    }
}

class NewShareExpenseButtonCell : BaseNewConversationButtonCell {
    
    @IBAction func activate(_ sender: Any) {
        activate(ctrler: ctrler!)
    }
    
    override func getOptions(message: Message) -> MessageOptions? {
        return MessageOptions(type: "expense-tab")
    }
    
    override func getPlaceHolder() -> String? {
        return "Enter the expense tab name..."
    }
}

class NewPollButtonCell : BaseNewConversationButtonCell {
    
    @IBAction func activate(_ sender: Any) {
        activate(ctrler: ctrler!)
    }
    
    override func getOptions(message: Message) -> MessageOptions? {
        let curMessageOption = MessageOptions(type: "poll")
        curMessageOption.pollOptions = ["choice #1", "choice #2"]
        curMessageOption.pollRecord = PollRecord(message: message, user: model.me(), checked_option: -1)
        return curMessageOption
    }
    
    override func getPlaceHolder() -> String? {
        return "Enter the poll reason..."
    }
}

class NewRSVPButtonCell : BaseNewConversationButtonCell {
    
    @IBAction func activate(_ sender: Any) {
        activate(ctrler: ctrler!)
    }
    
    override func getOptions(message: Message) -> MessageOptions? {
        let curMessageOption = MessageOptions(type: "poll")
        curMessageOption.pollOptions = ["Yes", "No", "Maybe"]
        curMessageOption.pollRecord = PollRecord(message: message, user: model.me(), checked_option: 0)
        curMessageOption.decorated = true
        return curMessageOption
    }
    
    override func getPlaceHolder() -> String? {
        return "Enter the RSVP message ..."
    }
}

class NewLocationButtonCell : BaseNewConversationButtonCell {
    
    @IBAction func activate(_ sender: Any) {
        activate(ctrler: ctrler!)
    }
    
    override func getOptions(message: Message) -> MessageOptions? {
        return MessageOptions(type: "location-sharing")
    }
    
    override func getPlaceHolder() -> String? {
        return "Enter the reason for sharing location..."
    }
}

class HideAndSeekButtonCell : BaseNewConversationButtonCell {
    @IBAction func activate(_ sender: Any) {
        activate(ctrler: ctrler!)
    }
    
    override func getOptions(message: Message) -> MessageOptions? {
        let mo = MessageOptions(type: "location-sharing")
        mo.decorated = true
        return mo
    }
    
    override func getPlaceHolder() -> String? {
        return "Enter the game name..."
    }
}

class NewConversationsDataSource : NSObject, UICollectionViewDataSource {
    weak var ctrler: ThreadsViewController?
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 6
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.row {
        case 0:
            let cell =  collectionView.dequeueReusableCell(withReuseIdentifier: "NewConversationButtonCell", for: indexPath) as! NewConversationButtonCell
            cell.ctrler = ctrler
            return cell
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewShareExpenseButtonCell", for: indexPath) as! NewShareExpenseButtonCell
            cell.ctrler = ctrler
            return cell
        case 2:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewPollButtonCell", for: indexPath) as! NewPollButtonCell
            cell.ctrler = ctrler
            return cell
        case 3:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewRSVPButtonCell", for: indexPath) as! NewRSVPButtonCell
            cell.ctrler = ctrler
            return cell
        case 4:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewLocationButtonCell", for: indexPath) as! NewLocationButtonCell
            cell.ctrler = ctrler
            return cell
        case 5:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HideAndSeekButtonCell", for: indexPath) as! HideAndSeekButtonCell
            cell.ctrler = ctrler
            return cell
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewConversationButtonCell", for: indexPath) as! NewConversationButtonCell
            cell.ctrler = ctrler
            return cell
        }
    }
}

class NewConversationsCell : UITableViewCell {
    
    @IBOutlet weak var collection: UICollectionView!
    
    var dataSource = NewConversationsDataSource()
    
    func initialize(ctrler: ThreadsViewController?) {
        dataSource.ctrler = ctrler
        
        collection.dataSource = dataSource
        collection.reloadData()
    }
}
