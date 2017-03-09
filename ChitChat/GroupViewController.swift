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
    var groups : [Group]
    override init() {
        groups = db_model.getGroupForUser(userId: db_model.me().id)
    }
    
    func update() {
        groups = db_model.getGroupForUser(userId: db_model.me().id)
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
        
        let count = db_model.groupMessageUnread(groupId: group.id, userId: db_model.me().id)
        if( count != 0 ) {
            cell.label.text = group.name + " (" + String(count) + ")"
        }
        
        cell.icon.image = group.icon
        if( cell.icon.image == nil ) {
            cell.icon.image = UIImage(named: "group-32")
        }
        
        var details = String()
        for userId in group.user_ids {
            let user = db_model.getUser(userId: userId)
            if( user != nil ) {
                if( !details.isEmpty ) {
                    details += ", "
                }
                if( user!.label != nil ) {
                    details += user!.label!
                    details += " "
                }
            }
        }
        cell.details.text = details
        return cell
    }
}

class GroupViewController: UITableViewController {
    var data : GroupData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        DBModelTest.setup()
        
        data = GroupData()
        
        tableView.dataSource = data
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        data?.update()
        tableView.reloadData()
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

}
