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
    
    @IBOutlet weak var label: UILabel!
    
}

class ThreadMessageWithImageCell : ThreadMessageCell {
    
    @IBOutlet weak var imageView: UIImageView!
}

class ThreadRowDelegate: NSObject, UICollectionViewDelegate {
    weak var threadData: ThreadsDataSource?
    weak var controller : ThreadsViewController?
    let index: Int
    
    init(ctrler: ThreadsViewController, threadData: ThreadsDataSource, index: Int) {
        self.threadData = threadData
        self.index = index
        self.controller = ctrler
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        threadData?.selectedCollection = index
        controller?.performSegue(withIdentifier: "messageSegue", sender: self)
    }
}


class ThreadRowData : NSObject, UICollectionViewDataSource {
    var messages = [Message]()
    let cthread : ConversationThread
    var last_updated : Date?
    
    init(cthread: ConversationThread) {
        self.cthread = cthread
    }
    
    // Fetch the data for this thread and call completion once done.
    // The bool parameter tells if the thread data has changed.
    func update( completion: @escaping (Bool) -> Void ) {
        model.getMessagesForThread(threadId: cthread.id, completion: { (messages) -> Void in
            let old = self.messages.count
            self.messages = messages
            
            var newerMessage = false
            if( messages.count > 0 ) {
                var latestMessageDate = messages[0].last_modified
                for m in messages {
                    if( latestMessageDate < m.last_modified ) {
                        latestMessageDate = m.last_modified
                    }
                }
                if( self.last_updated != nil ) {
                    newerMessage = latestMessageDate > self.last_updated!
                }
                self.last_updated = latestMessageDate
            }
            
            completion(messages.count != old || newerMessage )
        })
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let m = messages[indexPath.row]
        var cell : ThreadMessageCell!
        if( m.image != nil ) {
            let icell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThreadMessageWithImage", for: indexPath) as! ThreadMessageWithImageCell
            
            icell.imageView.image = m.image
            cell = icell
        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThreadMessage", for: indexPath) as! ThreadMessageCell
        }
        
        cell.label.text = messages[indexPath.row].text
        
        cell.layer.masksToBounds = true
        cell.layer.cornerRadius = 6
        cell.layer.borderColor = UIColor.gray.cgColor
        cell.layer.borderWidth = 1.0
        
        return cell
    }
}


class ThreadCell : UITableViewCell {
    
    @IBOutlet weak var collectionView: UICollectionView!
}

class ThreadsTableViewDelegate : NSObject, UITableViewDelegate {
    // Return the height of the row.
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // To fit the 80x80 collection view cells.
        return 100
    }
}

class ThreadsDataSource : NSObject, UITableViewDataSource {
    var titles = [String]()
    var threadsSource = [ThreadRowData]()
    var delegates = [ThreadRowDelegate]()
    var selectedCollection = -1
    var group: RecordId
    weak var controller : ThreadsViewController?
    
    init(ctler: ThreadsViewController, group: RecordId) {
        self.group = group
        self.controller = ctler
        
        super.init()
        
        let threads = model.getThreadsForGroup(groupId: group)
        for (i,thread) in threads.enumerated() {
            var title = thread.title
            
            let activity = model.getMyActivity(threadId: thread.id)
            if( activity == nil || activity!.last_read < thread.last_modified ) {
                title.append("*")
            }
            titles.append(title)
            threadsSource.append(ThreadRowData(cthread: thread))
            delegates.append(ThreadRowDelegate(ctrler: controller!, threadData: self, index: i))
        }
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
    func update(tableView: UITableView) {
        let threads = model.getThreadsForGroup(groupId: group)
        for thread in threads {
            var title = thread.title
            let activity = model.getMyActivity(threadId: thread.id)
            if( activity == nil || activity!.last_read < thread.last_modified ) {
                title.append("*")
            }
            
            let index = findIndex(threadId: thread.id)
            if( index != nil ) {
                titles[index!] = title
                let rowData = threadsSource[index!]
                rowData.update( completion: { (refresh) -> Void in
                    if( refresh ) {
                        DispatchQueue.main.async(execute: { () -> Void in
                             let cell = tableView.cellForRow(at: IndexPath(row: 0, section: index!)) as? ThreadCell
                             if( cell != nil ) {
                                 cell?.collectionView.reloadData()
                                 cell?.collectionView.scrollToItem(at: IndexPath(row: rowData.messages.count - 1, section: 0), at: .right, animated: true)
                             }
                        })
                    }
                })
            } else {
                titles.append(title)
                let rowData = ThreadRowData(cthread: thread)
                threadsSource.append(rowData)
                let rowIndex = threadsSource.count-1
                rowData.update( completion: { (refresh) -> Void in
                    if( refresh ) {
                        DispatchQueue.main.async(execute: { () -> Void in
                            let cell = tableView.cellForRow(at: IndexPath(row: 0, section: rowIndex)) as? ThreadCell
                            if( cell != nil ) {
                                cell?.collectionView.reloadData()
                            }
                        })
                    }
                })

                delegates.append(ThreadRowDelegate(ctrler: controller!, threadData: self, index: delegates.count))
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return titles.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return titles[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ThreadCell") as! ThreadCell
        cell.collectionView.dataSource = threadsSource[indexPath.section]
        cell.collectionView.delegate = delegates[indexPath.section]
        return cell
    }
}

class ThreadsViewController: UITableViewController {
    var data : ThreadsDataSource?
    var dele = ThreadsTableViewDelegate()
    var group = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        data = ThreadsDataSource(ctler: self, group: RecordId(string: group))
        tableView.dataSource = data
        tableView.delegate = dele
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        data?.update(tableView: tableView)
        tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if( segue.identifier! == "messageSegue" ) {
            let cc = segue.destination as? MessagesViewController
            if( cc != nil ) {
               let si = data!.selectedCollection
               if( si != -1 ) {
                  cc!.title = data!.titles[si]
                  cc!.conversationThread = data!.threadsSource[si].cthread
               }
            }
        }
    }
}
