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
    
    @IBOutlet weak var details: UILabel!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var label: UILabel!
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
        
        return cell
    }
}

class GroupViewController: UITableViewController {
    var data : GroupData?
    var activityView: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
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
        self.tableView.reloadData()
        
        if( activityView != nil ) {
           activityView!.color = UIColor.blue
           activityView!.center = self.view.center
           activityView!.startAnimating()
           self.view.addSubview(activityView!)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if( segue.identifier! == "groupSegue" ) {
            let cc = segue.destination as? ThreadsViewController
            if( cc != nil ) {
                let si = tableView.indexPathForSelectedRow
                if( si != nil ) {
                    cc!.group = data!.groups[si!.row].id.id
                    cc!.title = data!.groups[si!.row].name
                }
            }
        }
        if( segue.identifier! == "newGroupSegue" ) {
            
        }
    }
    
    // Called after a new group has been added.
    func groupAdded() {
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
