//
//  ThreadsViewController.swift
//  ChitChat
//
//  Created by next-shot on 3/6/17.
//  Copyright © 2017 next-shot. All rights reserved.
//

import Foundation
import UIKit

class ThreadMessageCell : UICollectionViewCell {
    
    @IBOutlet weak var fromName: UILabel!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var labelView: BubbleView!
    @IBOutlet weak var decoratedIndicator: UIImageView!
}

class ThreadMessageWithImageCell : UICollectionViewCell {
    
    @IBOutlet weak var labelView: BubbleView!
    @IBOutlet weak var fromName: UILabel!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var imageView: UIImageView!
}

class ThreadThumbUpCell : UICollectionViewCell {
    
    @IBOutlet weak var labelView: BubbleView!
    @IBOutlet weak var fromName: UILabel!
}

class ThreadRowDelegate: NSObject, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    let threadRowData: ThreadRowData
    weak var controller : ThreadsViewController?
    var dataRequested = false
    
    init(ctrler: ThreadsViewController, threadRowData: ThreadRowData) {
        self.threadRowData = threadRowData
        self.controller = ctrler
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        controller?.selectedConversationThread = threadRowData.cthread
        controller?.performSegue(withIdentifier: "messageSegue", sender: self)
    }
    
    // Compute the size of a message
    func collectionView(
        _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let m = threadRowData.messages[indexPath.item]
        let mo = MessageOptions(options: m.options)
        if( mo.type == "thumb-up" || m.text == "%%Thumb-up%%" ) {
            return CGSize(width: 60, height: 121)
        } else if( m.image != nil ) {
            return CGSize(width: 110, height: 121)
        } else {
            return CGSize(width: 110, height: 121)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if( scrollView.contentOffset.x <= 0 ) {
            threadRowData.requestMore(collectionView: scrollView as! UICollectionView)
        }
    }
}

class MessageCollectionViewHelper : NSObject {
    var messages = [Message]()
    var dateLimit = MessageDateRange(min: 0, max: 5)
    var dataRequested = false
    let cthread : ConversationThread
    var scrollingPosition : UICollectionViewScrollPosition = .right
    
    init(cthread: ConversationThread) {
        self.cthread = cthread
    }

    // Request more messages in older intervals.
    // The request loops stops when there is enough messages 
    // and/or the limits of days to fetch is reached.
    func requestMore(collectionView: UICollectionView, scroll: Bool = true) {
        if( dataRequested == true ) {
            return
        }
        
        var dateLimit = self.dateLimit
        if( dateLimit.max == settingsDB.settings.nb_of_days_to_fetch ) {
            dataRequested = false
            return
        }
        dateLimit.min += 5
        dateLimit.min = min(dateLimit.min, settingsDB.settings.nb_of_days_to_fetch)
        dateLimit.max += 5
        dateLimit.max = min(dateLimit.max, settingsDB.settings.nb_of_days_to_fetch)
        if( dateLimit.max == dateLimit.min ) {
            dataRequested = false
            return
        }
        
        dataRequested = true
        model.getMessagesForThread(thread: cthread, dateLimit: dateLimit, completion: { (messages, cachedDateLimit) in
            DispatchQueue.main.async(execute: {
                self.dateLimit = cachedDateLimit
                self.dataRequested = false
                
                var indexPaths = [IndexPath]()
                var count = 0
                for nm in messages {
                    let contained = self.messages.contains(where: { (m) -> Bool in
                        nm.id == m.id
                    })
                    if( !contained ) {
                        indexPaths.append(IndexPath(item: count, section: 0))
                        self.messages.insert(nm, at: count)
                        count += 1
                    }
                }
                
                collectionView.insertItems(at: indexPaths)
                if( scroll ) {
                    if( count > 0 ) {
                        collectionView.scrollToItem(at: IndexPath(row: count-1, section: 0), at: self.scrollingPosition, animated: true)
                    }
                } else {
                    if( self.messages.count > 0 ) {
                        collectionView.scrollToItem(at: IndexPath(row: self.messages.count - 1, section: 0), at: self.scrollingPosition, animated: false)
                    }
                }
                
                // If there is still not enough messages (to enable scrolling), request some more.
                if( self.messages.count <= 5 && dateLimit.max+5 < settingsDB.settings.nb_of_days_to_fetch) {
                    self.requestMore(collectionView: collectionView, scroll: scroll)
                    return
                }
            })
        })
    }
}

class ThreadRowData : MessageCollectionViewHelper, UICollectionViewDataSource {
    
    override init(cthread: ConversationThread) {
        super.init(cthread: cthread)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func getFromName(message: Message) -> String {
        if( message.user_id != model.me().id ) {
            return message.fromName
        } else {
            return "     "
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let m = messages[indexPath.row]
        let mo = MessageOptions(options: m.options)
        var cell : UICollectionViewCell!
        var labelView : BubbleView!
        
        if( m.text == "%%Thumb-up%%" || mo.type == "thumb-up" ) {
            let thup_cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThreadThumbUp", for: indexPath) as! ThreadThumbUpCell
            thup_cell.fromName.text = getFromName(message: m)
            labelView = thup_cell.labelView
            cell = thup_cell
        } else if( m.image != nil ) {
            let icell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThreadMessageWithImage", for: indexPath) as! ThreadMessageWithImageCell
            
            icell.imageView.image = m.image
            icell.imageView.layer.masksToBounds = true
            icell.imageView.layer.cornerRadius = 20
            
            icell.label.text = m.text
            icell.fromName.text = getFromName(message: m)
            labelView = icell.labelView
            cell = icell
        } else {
            let mcell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThreadMessage", for: indexPath) as! ThreadMessageCell
            
            mcell.label.text = m.text
            mcell.fromName.text = getFromName(message: m)
            labelView = mcell.labelView
            cell = mcell
            
            if( mo.type == "decoratedText" ) {
                mcell.decoratedIndicator.image = UIImage(named: "cool32")
                mcell.decoratedIndicator.isHidden = false
            } else if( mo.type == "poll" ) {
                mcell.decoratedIndicator.image = UIImage(named: "polling")
                mcell.decoratedIndicator.isHidden = false
            } else if( mo.type == "expense-tab" ) {
                mcell.decoratedIndicator.image = UIImage(named: "money-32")
                mcell.decoratedIndicator.isHidden = false
            } else {
                mcell.decoratedIndicator.isHidden = true
            }
        }
        
        let bg = ColorPalette.backgroundColor(message: m)
        
        /*
        labelView.layer.backgroundColor = bg.cgColor
        
        labelView.layer.masksToBounds = true
        labelView.layer.cornerRadius = 6
        labelView.layer.borderColor = ColorPalette.colors[ColorPalette.States.borderColor]?.cgColor
        labelView.layer.borderWidth = 1.0
        */
        labelView.fillColor = bg
        labelView.strokeColor = ColorPalette.colors[ColorPalette.States.borderColor]
        labelView.strokeWidth = ColorPalette.lineWidth(message: m)*2
        labelView.setNeedsDisplay()
        
        return cell
    }
}

class ThreadRowDataView  : ModelView {
    weak var controller : ThreadsViewController?
    let threadData : ThreadsDataSource
    let index : Int
    
    init(threadData: ThreadsDataSource, index: Int, ctrler: ThreadsViewController) {
        self.threadData = threadData
        self.index = index
        self.controller = ctrler
        
        super.init()
        
        self.notify_new_message = newMessage
        self.notify_edit_message = editMessage
    }
    
    func newMessage(message: Message) {
        if( controller == nil ) {
            return
        }
        // Update the entire tableView (because of thread reordering)
        controller!.data!.update(tableView: controller!.tableView, completion: {
            DispatchQueue.main.async(execute: {
                self.controller!.tableView.reloadData()
            })
        })
    }
    
    func editMessage(message: Message) {
        if( controller == nil ) {
            return
        }

        // Update the entire tableView (because of thread reordering)
        controller!.data!.update(tableView: controller!.tableView, completion: {
            DispatchQueue.main.async(execute: {
                self.controller!.tableView.reloadData()
            })
        })
    }
}

class ThreadCell : UITableViewCell {
    
    @IBOutlet weak var collectionView: UICollectionView!
}

class EmptyGroupCell : UITableViewCell {
    
    @IBOutlet weak var label: UILabel!
}

class ConversationHeaderView : UITableViewHeaderFooterView  {
    @IBOutlet weak var title: UILabel!
    
    @IBOutlet weak var date: UILabel!
}

class ThreadsTableViewDelegate : NSObject, UITableViewDelegate {
    let dataSource : ThreadsDataSource
    init(source: ThreadsDataSource) {
        self.dataSource = source
    }
    
    // Return the height of the row.
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if( dataSource.threadsSource.count == 0 ) {
            return 100
        }
        // To fit the 110x110 collection view cells.
        return 140
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if( dataSource.threadsSource.count == 0 ) {
            let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: "ConversationHeaderView") as? ConversationHeaderView
            
            cell?.title.text = "Last group conversation on "

            let longDateFormatter = DateFormatter()
            longDateFormatter.locale = Locale.current
            longDateFormatter.setLocalizedDateFormatFromTemplate("MMM d, HH:mm")
            longDateFormatter.timeZone = TimeZone.current
            
            model.getActivityForGroup(groupId: dataSource.group.id, completion: { (ga) in
                if( ga != nil ) {
                    DispatchQueue.main.async(execute: {
                        let longDate = longDateFormatter.string(from: ga!.last_modified)
                        cell!.date.text = longDate
                    })
                 }
            })
            return cell
        }
        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: "ConversationHeaderView") as? ConversationHeaderView
        if( cell != nil ) {
            let cthread = dataSource.threadsSource[section].cthread
            cell!.title.text = cthread.title
            
            let activity = model.getMyActivity(threadId: cthread.id)
            if( activity == nil || activity!.last_read < cthread.last_modified ) {
                cell!.title.text!.append("*")
            }
            
            
            let longDateFormatter = DateFormatter()
            longDateFormatter.locale = Locale.current
            longDateFormatter.setLocalizedDateFormatFromTemplate("MMM d, HH:mm")
            longDateFormatter.timeZone = TimeZone.current
            
            let longDate = longDateFormatter.string(from: cthread.last_modified)
            cell!.date.text = longDate

            cell?.contentView.backgroundColor = UIColor(red: 230/256, green: 230/256, blue: 230/256, alpha: 1.0)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 32
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if( self.dataSource.threadsSource.count == 0 ) {
            return nil
        }
        let edit = UITableViewRowAction(style: .destructive, title: "Delete") { action, index in
            let cthread = self.dataSource.threadsSource[indexPath.section].cthread
            
            self.dataSource.threadsSource.remove(at: indexPath.section)
            self.dataSource.delegates.remove(at: indexPath.section)
            
            //tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
            tableView.deleteSections([indexPath.section], with: UITableViewRowAnimation.automatic)
            
            model.deleteConversationThread(conversationThread: cthread)
        }
        return [edit]
    }
}

class ThreadsDataView : ModelView {
    weak var controller : ThreadsViewController?
    
    init(ctrler: ThreadsViewController) {
        controller = ctrler
        super.init()
        notify_new_conversation = newConversation
        notify_delete_conversation = deleteConversation
    }
    
    func newConversation(cthread: ConversationThread) {
        if( controller != nil  ) {
            self.controller!.data!.update(tableView: self.controller!.tableView, completion: {
                 DispatchQueue.main.async(execute: {
                     self.controller!.tableView.reloadData()
                })
            })
        }
    }
    
    func deleteConversation(id: RecordId) {
        if( controller != nil  ) {
            self.controller!.data!.update(tableView: self.controller!.tableView, completion: {
                DispatchQueue.main.async(execute: {
                    self.controller!.tableView.reloadData()
                })
            })
        }
    }
}

class ThreadsDataSource : NSObject, UITableViewDataSource {
    var threadsSource = [ThreadRowData]()
    var delegates = [ThreadRowDelegate]()
    var group: Group
    var modelViews = [ModelView]()
    weak var controller : ThreadsViewController?
    var fetchComplete = false
    
    init(ctler: ThreadsViewController, group: Group) {
        self.group = group
        self.controller = ctler
        
        super.init()
        
        let groupView = ThreadsDataView(ctrler: controller!)
        model.setupNotifications(groupId: group.id, view: groupView)
    }
    
    deinit {
        model.removeViews(views: modelViews)
    }
    
    func findIndex(threadId: RecordId) -> Int? {
        for (i,thr) in threadsSource.enumerated() {
            if( thr.cthread.id == threadId ) {
                return i
            }
        }
        return nil
    }
    
    // Update each threads collection view
    func update(tableView: UITableView, completion: @escaping () -> Void) {
        model.getThreadsForGroup(group: group, completion: { (threads) -> Void in
            self.fetchComplete = true
            model.removeViews(views: self.modelViews)
            self.threadsSource.removeAll()
            self.delegates.removeAll()
            
            for (i,thread) in threads.enumerated() {
                let threadRowData = ThreadRowData(cthread: thread)
                self.threadsSource.append(threadRowData)
                
                self.delegates.append(
                    ThreadRowDelegate(ctrler: self.controller!, threadRowData: threadRowData)
                )
                
                let view = ThreadRowDataView(threadData: self, index: i, ctrler: self.controller!)
                model.setupNotifications(cthread: thread, view: view)
                self.modelViews.append(view)
            }
            completion()
        })
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return max(threadsSource.count,1)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    //func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        //return titles[section]
    //}
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if( threadsSource.count == 0 ) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "EmptyGroupCell") as! EmptyGroupCell
            
            model.getActivityForGroup(groupId: group.id, completion: { (ga) in
                if( ga != nil ) {
                    let longDateFormatter = DateFormatter()
                    longDateFormatter.locale = Locale.current
                    longDateFormatter.setLocalizedDateFormatFromTemplate("MMM d")
                    longDateFormatter.timeZone = TimeZone.current
                    
                    let lastDate = ga!.last_modified
                    let secondsInADay : TimeInterval = 24*60*60
                    let last_day_to_fetch = Date(timeInterval: TimeInterval(settingsDB.settings.nb_of_days_to_fetch)*secondsInADay*(-1), since: Date())
                    let last_day_to_keep = Date(timeInterval: TimeInterval(settingsDB.settings.nb_of_days_to_keep)*secondsInADay*(-1), since: Date())
                    
                    DispatchQueue.main.async(execute: {
                        if( lastDate < last_day_to_keep ) {
                            let longDate = longDateFormatter.string(from: last_day_to_keep)
                            cell.label.text = String(
                                "Messages older than \(longDate) have expired. Please start a new conversation. To keep your messages longer, please go to user settings."
                            )
                        } else if( lastDate < last_day_to_fetch ) {
                            let longDate = longDateFormatter.string(from: last_day_to_fetch)
                            cell.label.text = String(
                                "Only messages younger than \(longDate) are shown. Please change user settings to see your messages or start a new conversation."
                            )
                        } else if( self.fetchComplete ) {
                            cell.label.text = String(
                                "All messages have expired. Please start a new conversation. To keep your messages longer, please go to user settings."
                            )
                        }
                    })
                }
            })
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ThreadCell") as! ThreadCell
        
        let rowData = threadsSource[indexPath.section]
        
        model.getMessagesForThread(thread: rowData.cthread, dateLimit: rowData.dateLimit, completion: { (messages, dateLimit) -> Void in
            rowData.messages = messages
            rowData.dateLimit = dateLimit
            if( messages.count == 0 ) {
                 rowData.requestMore(collectionView: cell.collectionView)
            } else {
                DispatchQueue.main.async(execute: {
                    cell.collectionView.reloadData()
                    if( messages.count > 0 ) {
                        cell.collectionView.scrollToItem(at: IndexPath(row: messages.count - 1, section: 0), at: .right, animated: true)
                    }
                    if( messages.count <= 5 ) {
                        // Otherwise scrolling is not enabled.
                        rowData.requestMore(collectionView: cell.collectionView, scroll: false)
                    }
                })
            }
        })
        
        cell.collectionView.dataSource = rowData
        cell.collectionView.delegate = delegates[indexPath.section]
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if( threadsSource.count == 0 ) {
            return false
        }
        let rowData = threadsSource[indexPath.section]

        return model.db_model.isCreatedByUser(record: rowData.cthread.id)
    }
}

class ThreadsViewController: UITableViewController {
    var data : ThreadsDataSource?
    var dele : ThreadsTableViewDelegate?
    var group : Group?
    var selectedConversationThread : ConversationThread?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tableView.register(
            UINib(nibName: "ConversationThreadHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: "ConversationHeaderView"
        )
        data = ThreadsDataSource(ctler: self, group: group!)
        tableView.dataSource = data
        dele = ThreadsTableViewDelegate(source: data!)
        tableView.delegate = dele
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        data?.update(tableView: tableView, completion: {
            DispatchQueue.main.async(execute: { () -> Void in
                self.tableView.reloadData()
            })
        })
        
        self.navigationController?.isToolbarHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if( data != nil ) {
            model.removeViews(views: data!.modelViews)
        }
         self.navigationController?.isToolbarHidden = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if( segue.identifier! == "messageSegue" ) {
            let cc = segue.destination as? MessagesViewController
            if( cc != nil ) {
                cc!.conversationThread = selectedConversationThread
                cc!.title = cc?.conversationThread?.title
                if( data != nil ) {
                    for cts in data!.threadsSource {
                        if( cts.cthread === selectedConversationThread ) {
                            cc?.dateLimit = cts.dateLimit
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func createNewThread(_ sender: Any) {
        let alertCtrler = UIAlertController(
            title: "Create new conversation thread",
            message: "Please provide a new conversation title",
            preferredStyle: .alert
        )
        alertCtrler.addTextField(configurationHandler:{ (textField) -> Void in
            textField.placeholder = "Conversation title"
        })
        
        alertCtrler.addAction(UIAlertAction(title: "OK", style: .default, handler:{ alertAction -> Void in
            let textField = alertCtrler.textFields![0]
            if( !textField.text!.isEmpty ) {
                let newThread = ConversationThread(id: RecordId(), group_id: self.group!.id, user_id: model.me().id)
                newThread.title = textField.text!
                model.saveConversationThread(conversationThread: newThread)
                
                // Create first message
                let message = Message(thread: newThread, user: model.me())
                message.text = "Welcome to " + newThread.title
                model.saveMessage(message: message, completion:  {
                    self.data?.update(tableView: self.tableView, completion: {
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.tableView.reloadData()
                        })
                    })
                })
            }
        }))
        
        alertCtrler.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alertCtrler, animated: true, completion: nil)

    }
}
