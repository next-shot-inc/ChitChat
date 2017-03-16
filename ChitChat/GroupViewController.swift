//
//  GroupViewController.swift
//  ChitChat
//
//  Created by next-shot on 3/6/17.
//  Copyright © 2017 next-shot. All rights reserved.
//

import Foundation
import UIKit

class GroupCell : UITableViewCell {
    @IBOutlet weak var last_user: UILabel!
    @IBOutlet weak var last_message: UILabel!
    
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var details: UILabel!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var label: UILabel!
}

class GroupTableDelegate : NSObject, UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}

class GroupData : NSObject, UITableViewDataSource {
    var groups = [Group]()
    override init() {
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupCell") as! GroupCell
        
        let group = groups[indexPath.row]
        cell.label.text = group.name
        
        model.getThreadsForGroup(group: group, completion: { (cthreads) -> Void in
            let count = model.groupMessageUnread(group: group, cthreads: cthreads)
            if( count != 0 ) {
                DispatchQueue.main.async(execute: { () -> Void in
                    cell.label.text = group.name + " (" + String(count) + ")"
                })
            }
        })
        
        cell.icon.image = group.icon
        if( cell.icon.image == nil ) {
            cell.icon.image = UIImage(named: "group-32")
        }
        cell.details.text = group.details
        
        model.getUsersForGroup(group: group, completion: { (users) -> Void in
            var details = String()
            for user in users {
                if( !details.isEmpty ) {
                    details += ", "
                }
                if( user.label != nil ) {
                    details += user.label!
                    details += " "
                }
            }
            DispatchQueue.main.async(execute: { () -> Void in
                  cell.details.text = details
            })
        })
        
        let longDateFormatter = DateFormatter()
        longDateFormatter.locale = Locale.current
        longDateFormatter.setLocalizedDateFormatFromTemplate("MMM d, HH:mm")
        longDateFormatter.timeZone = TimeZone.current
        
        let longDate = longDateFormatter.string(from: group.last_modified)
        cell.date.text = longDate
        
        if( group.last_message == "%%Thumb-up%%" ) {
            cell.last_message.text = "Thumb up"
        } else {
            cell.last_message.text = group.last_message
        }
        
        cell.last_user.text = " "
        if( group.last_userId != nil ) {
            if( group.last_userId! == model.me().id ) {
                cell.last_user.text = "Me: "
            } else {
                let user = model.getUser(userId: group.last_userId!)
                if( user != nil && user!.label != nil ) {
                    cell.last_user.text = user!.label! + ":"
                }
            }
        }
        
        return cell
    }
}

class GroupViewController: UITableViewController {
    var data : GroupData?
    var delegate : GroupTableDelegate?
    var activityView: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.delegate = GroupTableDelegate()
        tableView.delegate = self.delegate
        
        activityView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        
        let cloud = true
        if( cloud ) {
            let restart = false
            let cloudDB = CloudDBModel()
            if( restart ) {
                cloudDB.deleteAllRecords {
                    // Once all records have been deleted.
                    self.doSetup(db: cloudDB, restart: restart)
                }
            } else {
               let cloudDB = CloudDBModel()
               doSetup(db: cloudDB, restart: restart)
            }
        } else {
            let memoryDB = InMemoryDB()
            doSetup(db: memoryDB, restart: true)
        }
    }
    
    func doSetup(db: DBProtocol, restart: Bool) {
        
        model = DataModel(db_model: db)
        
        let modelView = ModelView()
        modelView.notify_new_group = self.groupAdded
        model.views.append(modelView)
        
        model.getUserInfo {
            // Once the initial user setup is done
            
            if( restart ) {
                // Populate the DB with test data
                DBModelTest.setup()
                model.setAppBadgeNumber(number: 0)
            }
            
            self.data = GroupData()
            self.tableView.dataSource = self.data
            
            // Fetch the groups and update
            model.getGroups(completion: ({ (groups) -> () in
                DispatchQueue.main.async(execute: { () -> Void in
                    self.data!.groups = groups
                    self.tableView.reloadData()
                    
                    if( self.activityView != nil ) {
                        self.activityView!.stopAnimating()
                        self.activityView!.removeFromSuperview()
                        self.activityView = nil
                    }
                })
            }))
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if( activityView != nil ) {
           activityView!.color = UIColor.blue
           activityView!.center = self.view.center
           activityView!.startAnimating()
           self.view.addSubview(activityView!)
        } else {
            // Fetch the groups and update
            model.getGroups(completion: { (groups) -> () in
                DispatchQueue.main.async(execute: { () -> Void in
                    self.data!.groups = groups
                    self.tableView.reloadData()
                })
            })
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if( segue.identifier! == "groupSegue" ) {
            let cc = segue.destination as? ThreadsViewController
            if( cc != nil ) {
                let si = tableView.indexPathForSelectedRow
                if( si != nil ) {
                    cc!.group = data!.groups[si!.row]
                    cc!.title = data!.groups[si!.row].name
                }
            }
        }
        if( segue.identifier! == "newGroupSegue" ) {
            
        }
    }
    
    // Called after a new group has been added.
    func groupAdded(_ group: Group) {
        model.getGroups(completion: ({ (groups) -> () in
            DispatchQueue.main.async(execute: { () -> Void in
                if( self.data == nil ) {
                    return
                }
                self.data!.groups = groups
                self.tableView.reloadData()
            })
        }))
    }

}
