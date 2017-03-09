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
    let thread_id : RecordId
    
    init(thread_id: RecordId) {
        messages = db_model.getMessagesForThread(threadId: thread_id)
        self.thread_id = thread_id
    }
    
    func update() -> Bool {
        let old = messages.count
        messages = db_model.getMessagesForThread(threadId: thread_id)
        return messages.count != old
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThreadMessage", for: indexPath) as! ThreadMessageCell
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
        
        let threads = db_model.getThreadsForGroup(groupId: group)
        for (i,thread) in threads.enumerated() {
            var title = thread.title
            
            let activity = db_model.getActivity(userId: db_model.me().id, threadId: thread.id)
            if( activity == nil || activity!.last_read < thread.last_modified ) {
                title.append("*")
            }
            titles.append(title)
            threadsSource.append(ThreadRowData(thread_id: thread.id))
            delegates.append(ThreadRowDelegate(ctrler: controller!, threadData: self, index: i))
        }
    }
    
    func findIndex(threadId: RecordId) -> Int? {
        for (i,thr) in threadsSource.enumerated() {
            if( thr.thread_id.id == threadId.id ) {
                return i
            }
        }
        return nil
    }
    
    func update(tableView: UITableView) {
        let threads = db_model.getThreadsForGroup(groupId: group)
        for thread in threads {
            var title = thread.title
            let activity = db_model.getActivity(userId: db_model.me().id, threadId: thread.id)
            if( activity == nil || activity!.last_read < thread.last_modified ) {
                title.append("*")
            }
            
            let index = findIndex(threadId: thread.id)
            if( index != nil ) {
                titles[index!] = title
                if( threadsSource[index!].update() ) {
                    let cell = tableView.cellForRow(at: IndexPath(row: 0, section: index!)) as? ThreadCell
                    if( cell != nil ) {
                        cell?.collectionView.reloadData()
                    }
                }
            } else {
                titles.append(title)
                threadsSource.append(ThreadRowData(thread_id: thread.id))
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
                  cc!.threadId = data!.threadsSource[si].thread_id
               }
            }
        }
    }
}
