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
    @IBOutlet weak var labelView: UIView!
}

class ThreadMessageWithImageCell : UICollectionViewCell {
    
    @IBOutlet weak var labelView: UIView!
    @IBOutlet weak var fromName: UILabel!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var imageView: UIImageView!
}

class ThreadThumbUpCell : UICollectionViewCell {
    
    @IBOutlet weak var fromName: UILabel!
}

class ThreadRowDelegate: NSObject, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    let threadRowData: ThreadRowData
    weak var controller : ThreadsViewController?
    
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
        if( m.text == "%%Thumb-up%%" ) {
            return CGSize(width: 50, height: 83)
        } else if( m.image != nil ) {
            return CGSize(width: 80, height: 83)
        } else {
            return CGSize(width: 80, height: 83)
        }
    }

}

class ThreadRowData : NSObject, UICollectionViewDataSource {
    var messages = [Message]()
    let cthread : ConversationThread
    
    init(cthread: ConversationThread) {
        self.cthread = cthread
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
        var cell : UICollectionViewCell!
        var labelView : UIView!
        
        if( m.text == "%%Thumb-up%%" ) {
            let thup_cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThreadThumbUp", for: indexPath) as! ThreadThumbUpCell
            thup_cell.fromName.text = getFromName(message: m)
            return thup_cell
        }
        if( m.image != nil ) {
            let icell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThreadMessageWithImage", for: indexPath) as! ThreadMessageWithImageCell
            
            icell.imageView.image = m.image
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
        }
        
        let bg = ColorPalette.backgroundColor(message: m)
        labelView.layer.backgroundColor = bg.cgColor
        
        labelView.layer.masksToBounds = true
        labelView.layer.cornerRadius = 6
        labelView.layer.borderColor = ColorPalette.colors[ColorPalette.States.borderColor]?.cgColor
        labelView.layer.borderWidth = 1.0
        
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
        // To fit the 80x80 collection view cells.
        return 100
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
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
}

class ThreadsDataSource : NSObject, UITableViewDataSource {
    var threadsSource = [ThreadRowData]()
    var delegates = [ThreadRowDelegate]()
    var group: Group
    var modelViews = [ModelView]()
    weak var controller : ThreadsViewController?
    
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
        model.removeViews(views: modelViews)
        threadsSource.removeAll()
        delegates.removeAll()
        
        model.getThreadsForGroup(group: group, completion: { (threads) -> Void in
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
         return threadsSource.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    //func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        //return titles[section]
    //}
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ThreadCell") as! ThreadCell
        
        let rowData = threadsSource[indexPath.section]
        
        model.getMessagesForThread(thread: rowData.cthread, completion: { (messages) -> Void in
            self.threadsSource[indexPath.section].messages = messages
            DispatchQueue.main.async(execute: { 
                cell.collectionView.reloadData()
                if( messages.count > 0 ) {
                    cell.collectionView.scrollToItem(at: IndexPath(row: messages.count - 1, section: 0), at: .right, animated: true)
                }
            })
        })
        
        cell.collectionView.dataSource = rowData
        cell.collectionView.delegate = delegates[indexPath.section]
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if( data != nil ) {
            model.removeViews(views: data!.modelViews)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if( segue.identifier! == "messageSegue" ) {
            let cc = segue.destination as? MessagesViewController
            if( cc != nil ) {
                cc!.conversationThread = selectedConversationThread
                cc!.title = cc?.conversationThread?.title
            }
        }
    }
}
