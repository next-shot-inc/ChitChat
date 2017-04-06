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
    
    @IBOutlet weak var iconView: UIView!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var details: UILabel!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    var group: Group?
}

class GroupTableDelegate : NSObject, UITableViewDelegate {
    weak var controller : GroupViewController?
    init(ctrler: GroupViewController) {
        self.controller = ctrler
        super.init()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let edit = UITableViewRowAction(style: .normal, title: "Edit") { action, index in
            let cell = tableView.cellForRow(at: indexPath)
            self.controller?.performSegue(withIdentifier: "newGroupSegue", sender: cell)
        }
        return [edit]
    }
}

class GroupModelView : ModelView {
    weak var controller : GroupViewController?
    init(ctrler: GroupViewController) {
        self.controller = ctrler
        super.init()
        
        self.notify_edit_group_activity = edit_group_activity
        self.notify_new_group = new_group
    }
    
    func new_group(group: Group) {
        controller?.groupsModified()
    }
    
    func edit_group_activity(groupActivity: GroupActivity) {
        controller?.groupsModified()
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
        
        cell.group = group
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
        
        model.getActivityForGroup(groupId: group.id, completion: { (activity) -> Void in
            if( activity == nil ) {
                return
            }
            let longDateFormatter = DateFormatter()
            longDateFormatter.locale = Locale.current
            longDateFormatter.setLocalizedDateFormatFromTemplate("MMM d, HH:mm")
            longDateFormatter.timeZone = TimeZone.current
            
            let longDate = longDateFormatter.string(from: activity!.last_modified)
            cell.date.text = longDate
            
            if( activity!.last_message == "%%Thumb-up%%" ) {
                cell.last_message.text = "Thumb up"
            } else {
                cell.last_message.text = activity!.last_message
            }
            
            cell.last_user.text = " "
            if( activity!.last_userId != nil ) {
                if( activity!.last_userId! == model.me().id ) {
                    cell.last_user.text = "Me: "
                } else {
                    let user = model.getUser(userId: activity!.last_userId!)
                    if( user != nil && user!.label != nil ) {
                        cell.last_user.text = user!.label! + ":"
                    }
                }
            }
        })
        
        cell.iconView.layer.masksToBounds = true
        cell.iconView.layer.cornerRadius = 10
        cell.iconView.layer.borderColor = UIColor.darkGray.cgColor
        cell.iconView.layer.borderWidth = 1.0
    
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return model.db_model.isCreatedByUser(record: groups[indexPath.row].id)
    }
}

class GroupViewController: UITableViewController {
    var data : GroupData?
    var delegate : GroupTableDelegate?
    var activityView: UIActivityIndicatorView?
    var modelView: GroupModelView?
    var setupFailed = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.delegate = GroupTableDelegate(ctrler: self)
        tableView.delegate = self.delegate
        
        activityView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        
        let cloud = true
        if( cloud ) {
            let restart = false
            let cleanSubscriptions = true
            let cloudDB = CloudDBModel()
            if( restart ) {
                cloudDB.deleteAllRecords(subscriptionsOnly: false) {
                    // Once all records have been deleted.
                    self.doSetup(db: cloudDB, restart: restart)
                }
            } else if( cleanSubscriptions ) {
                cloudDB.deleteAllRecords(subscriptionsOnly: true) {
                    // Once all records have been deleted.
                    self.doSetup(db: cloudDB, restart: restart)
                }
            } else {
               doSetup(db: cloudDB, restart: restart)
            }
            let loadResourcesToDB = false
            if( loadResourcesToDB ) {
                let rdb = ResourceDB()
                rdb.save(catalog: rdb.currentCatalog)
            }
        } else {
            let memoryDB = InMemoryDB()
            doSetup(db: memoryDB, restart: true)
        }
    }
    
    func doSetup(db: DBProtocol, restart: Bool) {
        
        model = DataModel(db_model: db)
        
        modelView = GroupModelView(ctrler: self)
        
        setup(restart: restart)
    }
    
    func setup(restart: Bool) {
        model.getUserInfo(completion: { (status, newUser) -> Void in
            
            if( status == false ) {
                self.data = GroupData()
                self.tableView.dataSource = self.data
                
                DispatchQueue.main.async(execute: {
                    if( self.activityView != nil ) {
                        self.activityView!.stopAnimating()
                        self.activityView!.removeFromSuperview()
                        self.activityView = nil
                    }
                })
                
                // As the setup is done in the ViewLoad it may be done before the login screen
                // In this case, we have to wait for the login step to be done 
                // and this controller to appear to finish the setup.
                self.setupFailed = true
                return
            }
            
            self.setupFailed = false
            
            // Once the initial user setup is done
            model.setupNotifications(userId: model.me().id, view: self.modelView!)
            
            if( restart ) {
                // Populate the DB with test data
                DBModelTest.setup()
                model.setAppBadgeNumber(number: 0)
            }
            
            self.data = GroupData()
            self.tableView.dataSource = self.data
            
            // Get settings information to initialize UI stuff.
            settingsDB.get()
            model.setMessageFetchTimeLimit(numberOfDays: TimeInterval(settingsDB.settings.nb_of_days_to_fetch))
            ColorPalette.cur = settingsDB.settings.palette
            
            // Right now group invitations arrive only when user does not initially exist.
            // But if the invitation process is generalized (in ContactsController) then 
            // the logic here will have to change.
            if( newUser ) {
                model.getGroupInvitations(completion: { (invitations, groups) -> () in
                    // implicitely accept all invitations (could modify table view for explicit acceptance)
                    for g in groups {
                        model.addUserToGroup(group: g, user: model.me())
                    }
                    // Mark the invitation has accepted.
                    for invitation in invitations {
                        invitation.accepted = true
                        model.saveUserInvitation(userInvitation: invitation)
                    }
                    
                    // Show groups in table View
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.manageModelView(newGroups: groups, oldGroups: self.data!.groups)
                        self.data!.groups = groups
                        self.tableView.reloadData()
                        
                        if( self.activityView != nil ) {
                            self.activityView!.stopAnimating()
                            self.activityView!.removeFromSuperview()
                            self.activityView = nil
                        }
                    })
                })
                
            } else {
            
                // Fetch the groups and update
                model.getGroups(completion: ({ (groups) -> () in
                    DispatchQueue.main.async(execute: { () -> Void in
                        
                        self.manageModelView(newGroups: groups, oldGroups: self.data!.groups)
                        self.data!.groups = groups
                        self.tableView.reloadData()
                        
                        if( self.activityView != nil ) {
                            self.activityView!.stopAnimating()
                            self.activityView!.removeFromSuperview()
                            self.activityView = nil
                            
                            model.deleteOldStuff(numberOfDays: settingsDB.settings.nb_of_days_to_keep)
                        }
                    })
                }))
            }
        })

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if( setupFailed ) {
            // If the setup failed during the load, 
            // try again after the login screen finished.
            setup(restart: false)
            return
        }
        
        if( activityView != nil ) {
           activityView!.color = UIColor.blue
           activityView!.center = self.view.center
           activityView!.startAnimating()
           self.view.addSubview(activityView!)
        } else {
            // Fetch the groups and update
            model.getGroups(completion: { (groups) -> () in
                DispatchQueue.main.async(execute: { () -> Void in
                    self.manageModelView(newGroups: groups, oldGroups: self.data!.groups)
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
            // Either an edit or a new group segue
            let tableCell = sender as? GroupCell
            if( tableCell != nil ) {
                let gc = segue.destination as? NewGroupController
                if( gc != nil ) {
                    gc!.existingGroup = tableCell!.group
                }
            }
        }
    }
    
    func manageModelView(newGroups: [Group], oldGroups: [Group]) {
        for ng in newGroups {
            let contained = oldGroups.contains(where: { (og) -> Bool in return og === ng })
            if( !contained ) {
                model.setupNotifications(groupId: ng.id, view: modelView!)
            }
        }
    }
    
    // Called after a new group has been added or a group activity modified
    func groupsModified() {
        model.getGroups(completion: ({ (groups) -> () in
            DispatchQueue.main.async(execute: { () -> Void in
                if( self.data == nil ) {
                    return
                }
                self.manageModelView(newGroups: groups, oldGroups: self.data!.groups)
                self.data!.groups = groups
                self.tableView.reloadData()
            })
        }))
    }

}
