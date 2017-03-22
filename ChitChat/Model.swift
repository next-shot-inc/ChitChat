//
//  Model.swift
//  ChitChat
//
//  Created by next-shot on 3/7/17.
//  Copyright © 2017 next-shot. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class RecordId : Hashable {
    let id : String
    init() {
        id = UUID().uuidString
    }
    init(string: String) {
        self.id = string
    }
    
    var hashValue: Int {
        return id.hashValue
    }
    static func == (lhs: RecordId, rhs: RecordId) -> Bool {
        return lhs.id == rhs.id
    }
}

class User {
    var id : RecordId
    var icon: UIImage?
    var label : String?
    var phoneNumber : String
    
    init(id: RecordId, label: String, phoneNumber: String) {
        self.id = id
        self.label = label
        self.phoneNumber = phoneNumber
    }
}

class UserActivity {
    var id : RecordId
    let user_id : RecordId
    let thread_id : RecordId
    var last_read : Date
    
    init(id: RecordId, user_id: RecordId, thread_id: RecordId) {
        self.id = id
        self.user_id = user_id
        self.thread_id = thread_id
        self.last_read = Date()
    }
    
    init(user_id: RecordId, thread_id: RecordId) {
        self.id = RecordId()
        self.user_id = user_id
        self.thread_id = thread_id
        self.last_read = Date()
    }
}

class Group {
    var id : RecordId
    var name = String()
    var icon: UIImage?
    var details = String()
    var activity_id : RecordId!

    init(id: RecordId, name: String) {
        self.id = id
        self.name = name
    }
}

class GroupActivity {
    var id : RecordId
    let group_id : RecordId
    var last_modified = Date()
    var last_userId : RecordId?
    var last_message = String()
    
    init(id: RecordId, group_id: RecordId) {
        self.id = id
        self.group_id = group_id
        self.last_modified = Date()
    }
    
    init(group_id: RecordId) {
        self.id = RecordId()
        self.group_id = group_id
        self.last_modified = Date()
    }
}

class ConversationThread {
    var id : RecordId
    var group_id : RecordId
    var last_modified = Date()
    var title = String()
    
    init(id: RecordId, group_id: RecordId) {
        self.id = id
        self.group_id = group_id
    }
}

class GroupUserFolder {
    // key = group_id, value = user_id
    var entries = [(user_id: RecordId, group_id: RecordId)]()
    
    func getGroups(user_id: RecordId) -> [RecordId] {
        var groups = [RecordId]()
        for e in entries {
            if( e.user_id == user_id ) {
                groups.append(e.group_id)
            }
        }
        return groups
    }
    func getUsers(group_id: RecordId) -> [RecordId] {
        var users = [RecordId]()
        for e in entries {
            if( e.group_id == group_id ) {
                users.append(e.group_id)
            }
        }
        return users
    }
}

class Message {
    var id : RecordId
    var conversation_id : RecordId
    let user_id : RecordId
    var text = String()
    var image : UIImage?
    var options = String()
    var last_modified = Date()
    var fromName = String()   // Information to show inside the alert/summary
    var inThread = String()   // Information to show inside the alert
    
    init(thread: ConversationThread, user: User) {
        self.id = RecordId()
        self.user_id = user.id
        self.conversation_id = thread.id
        self.fromName = user.label!
        self.inThread = thread.title
    }
    
    init(id: RecordId, threadId: RecordId, user_id: RecordId) {
        self.id = id
        self.user_id = user_id
        self.conversation_id = threadId
    }
}

class DecorationTheme {
    var id: RecordId
    var name : String
    var special_date : Date?
    init(name: String) {
        self.id = RecordId()
        self.name = name
    }
    init(id: RecordId, name: String) {
        self.id = id
        self.name = name
    }
}

class DecorationStamp {
    var id: RecordId
    var image : UIImage
    var theme_id : RecordId
    init(id: RecordId, theme: RecordId, image: UIImage) {
        self.id = id
        self.theme_id = theme
        self.image = image
    }
    init(theme: RecordId, image: UIImage) {
        self.id = RecordId()
        self.theme_id = theme
        self.image = image
    }
}

/************************************************************************************/

class ModelView {
    var notify_new_group : ((_ group: Group) -> Void)?
    var notify_new_message : ((_ message: Message) -> Void)?
    var notify_edit_message : ((_ message: Message) -> Void)?
    var notify_new_conversation : ((_ cthread: ConversationThread) -> Void)?
    var notify_edit_group_activity : ((_ activity: GroupActivity) -> Void)?
}

class MemoryModel {
    var users = [User]()
    var groups : [Group]?
    var conversations : [ConversationThread]?
    var messages : [Message]?
    var user_activities = [UserActivity]()
    var group_activities: [GroupActivity]?
    var groupUserFolder = [(group: Group, user: User)]()
    var decorationThemes = [DecorationTheme]()
    var decorationStamps = [DecorationStamp]()
    
    func update(groups: [Group]) {
        let initialGroup = self.groups
        self.groups = groups
        if( initialGroup != nil ) {
            // See if some groups are not yet in the DB
            for igr in initialGroup! {
                let contained = groups.contains(where: ({ (cgr) -> Bool in
                    igr.id == cgr.id
                }))
                if( !contained ) {
                    self.groups!.append(igr)
                }
            }
        }
    }
    
    func update(group: Group, users: [User]) -> [User] {
        // See if some not yet in DB elements exist
        var included = users
        for item in self.groupUserFolder {
            if( item.group === group ) {
                let contained = users.contains(where: { (cur) -> Bool in
                    cur.id == item.user.id
                })
                if( !contained ) {
                    included.append(item.user)
                }
            }
        }
        
        // Update memory table
        for user in users {
            let contained = self.groupUserFolder.contains(where: { (grp, usr) -> Bool in
                grp === group && usr === user
            })
            if( !contained ) {
                self.groupUserFolder.append((group: group, user: user))
            }
        }
        for user in users {
            let contained = self.users.contains(where: { (usr) -> Bool in
                user.id == usr.id
            })
            if( !contained ) {
                self.users.append(user)
            }
        }
        return included
    }
    
    func update(user: User?) {
        // Update memory model
        if( user != nil ) {
            let contained = self.users.contains(where: { (usr) -> Bool in
                user!.id == usr.id
            })
            if( !contained ) {
                self.users.append(user!)
            }
        }
    }
    
    func update(group: Group, cthreads: [ConversationThread]) -> [ConversationThread] {
        // See if there are some only-in-memory conversations
        var included = cthreads
        if( self.conversations == nil ) {
            self.conversations = cthreads
            return included
        }
        for igr in self.conversations! {
            if( igr.group_id == group.id ) {
                let contained = cthreads.contains(where: { (cgr) -> Bool in
                    igr.id == cgr.id
                })
                if( !contained ) {
                    included.append(igr)
                }
            }
        }
        
        // Update memory model
        for cthread in cthreads {
            let contained = self.conversations!.contains(where: { (conv)-> Bool in
                return conv.id == cthread.id
            })
            if( !contained ) {
                self.conversations!.append(cthread)
            }
        }
        return included
    }
    
    func update(threadId: RecordId, messages: [Message]) -> [Message] {
        // See if there are some only-in-memory conversations
        var included = messages
        if( self.messages == nil ) {
            self.messages = messages
            return messages
        }
        
        for igr in self.messages! {
            if( igr.conversation_id == threadId ) {
                let contained = messages.contains(where: { (cgr) -> Bool in
                    igr.id == cgr.id
                })
                if( !contained ) {
                    included.append(igr)
                }
            }
        }
        
        // Update memory model
        for message in messages {
            let index = self.messages!.index(where: { (mess)-> Bool in
                return mess.id == message.id
            })
            if( index != nil ) {
                self.messages!.remove(at: index!)
                self.messages!.insert(message, at: index!)
            } else {
                self.messages!.append(message)
            }
        }
        
        return included
    }
    
    func update(groupActivity: GroupActivity) {
        if( group_activities == nil ) {
            group_activities = [GroupActivity]()
            group_activities!.append(groupActivity)
        } else {
            let index = self.group_activities!.index(where: { (gra)-> Bool in
                return gra.id == groupActivity.id
            })
            if( index != nil ) {
                self.group_activities!.remove(at: index!)
                self.group_activities!.insert(groupActivity, at: index!)
            } else {
                self.group_activities!.append(groupActivity)
            }
        }
    }
    func update(activities: [GroupActivity]) {
        let initialGroupActivities = self.group_activities
        self.group_activities = activities
        if( initialGroupActivities != nil ) {
            // See if some groups are not yet in the DB
            for igra in initialGroupActivities! {
                let contained = activities.contains(where: ({ (cgra) -> Bool in
                    igra.id == cgra.id
                }))
                if( !contained ) {
                    self.group_activities!.append(igra)
                }
            }
        }
    }

    func getGroupActivity(groupId: RecordId) -> GroupActivity? {
        if( group_activities != nil ) {
            for gra in group_activities! {
                if( gra.group_id == groupId ) {
                    return gra
                }
            }
        }
        return nil
    }
    func getActivitiesForGroups(groups: [Group]) -> [GroupActivity] {
        var acts = [GroupActivity]()
        if( group_activities != nil ) {
            for g in groups {
                for a in group_activities! {
                    if( a.group_id == g.id ) {
                        acts.append(a)
                        break
                    }
                }
            }
        }
        return acts
    }

    func updateDecorationThemes(themes: [DecorationTheme]) {
        self.decorationThemes = themes
    }
    func updateDecorationStamps(stamps: [DecorationStamp]) {
        self.decorationStamps.append(contentsOf: stamps)
    }
    
}

class MemoryModelView : ModelView {
    let memory_model: MemoryModel
    
    init(memory_model: MemoryModel) {
        self.memory_model = memory_model
        super.init()
        
        self.notify_new_message = new_message
        self.notify_edit_message = edited_message
        self.notify_new_conversation = new_cthread
        self.notify_new_group = new_group
        self.notify_edit_group_activity = edited_group_activity
    }
    
    func new_message(message: Message) {
        if( memory_model.messages != nil ) {
            let index = memory_model.messages!.index(where: { (mess)-> Bool in
                return mess.id == message.id
            })
            if( index == nil ) {
                memory_model.messages!.append(message)
            }
        }
    }
    
    func edited_message(message: Message) {
        if( memory_model.messages != nil ) {
            let index = memory_model.messages!.index(where: { (mess)-> Bool in
                return mess.id == message.id
            })
            if( index != nil ) {
                memory_model.messages!.remove(at: index!)
                memory_model.messages!.insert(message, at: index!)
            }
        }
    }
    
    func new_cthread(cthread: ConversationThread) {
        if( memory_model.conversations != nil ) {
            let contained = memory_model.conversations!.contains(where: { (conv)-> Bool in
               return conv.id == cthread.id
            })
            if( !contained ) {
                memory_model.conversations!.append(cthread)
            }
        }
    }
    
    func new_group(group: Group) {
        if( memory_model.groups != nil ) {
            let index = memory_model.groups!.index(where: { (gr)-> Bool in
            return gr.id == group.id
           })
           if( index == nil ) {
               memory_model.groups!.append(group)
           } else {
               memory_model.groups!.remove(at: index!)
               memory_model.groups!.insert(group, at: index!)
           }
        }
    }
    
    func edited_group_activity(groupActivity: GroupActivity) {
        memory_model.update(groupActivity: groupActivity)
    }
}

class DataModel {
    internal let memory_model = MemoryModel()
    let db_model : DBProtocol!
    var views = [ModelView]()
    var start_date = Date()
    var pendingStampRequests = [RecordId:[([DecorationStamp]) -> Void]]()
    
    init(db_model: DBProtocol) {
        self.db_model = db_model
        
        let model_view = MemoryModelView(memory_model: memory_model)
        views.append(model_view)
    }
    
    func getUserInfo(completion: @escaping (Bool) -> Void) {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        var userInfo : UserInfo?
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "UserInfo")
        do {
            let entities = try managedContext.fetch(fetchRequest)
            if( entities.count >= 1 ) {
                userInfo = entities[0] as? UserInfo
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        if( userInfo != nil ) {
            db_model.getUser(phoneNumber: userInfo!.telephoneNumber!, completion: {(user) -> () in
                var me : User!
                if( user == nil ) {
                    let user0 = User(
                        id: RecordId(), label: userInfo!.name!, phoneNumber: userInfo!.telephoneNumber!
                    )
                    self.db_model.saveUser(user: user0)
                    self.memory_model.users.append(user0)
                    me = user0
                } else {
                    me = user!
                    self.memory_model.users.append(user!)
                }
                
                self.db_model.setAsUser(user: me!)
                
                self.db_model.getActivities(userId: me.id, completion: { (activities) -> Void in
                    self.memory_model.user_activities = activities
                    completion(true)
                })
            })
        } else {
            print("Could not get User Info")
            completion(false)
        }
    }
    
    func createGroupActivityTable(groups: [Group], activities: [GroupActivity]) -> [RecordId:GroupActivity] {
        var table = [RecordId:GroupActivity]()
        for g in groups {
            for a in activities {
                if( a.group_id == g.id ) {
                    table[g.id] = a
                    break
                }
            }
        }
        return table
    }
    
    // Get groups sorted by activities
    func getGroups(completion: @escaping ([Group]) -> ()) {
        if( memory_model.groups != nil ) {
            let groups = memory_model.groups!
            // Before return get the activies
            getActivitiesForGroups(
                groups: groups,
                completion: { (activities) -> Void in
                    let table = self.createGroupActivityTable(groups: groups, activities: activities)
                    let sorted_groups = groups.sorted(by: { (g1, g2) -> Bool in table[g1.id]!.last_modified > table[g2.id]!.last_modified })
                    return completion(sorted_groups)
                }
            )
        }
        db_model.getGroupsForUser(userId: me().id, completion: ({ (groups) -> () in
            self.memory_model.update(groups: groups)
            
            // Before return get the activies
            self.getActivitiesForGroups(
                groups: self.memory_model.groups!,
                completion: { (activities) -> Void in
                    let table = self.createGroupActivityTable(groups: self.memory_model.groups!, activities: activities)
                    let sorted_groups = self.memory_model.groups!.sorted(by: { (g1, g2) -> Bool in table[g1.id]!.last_modified > table[g2.id]!.last_modified })
                    return completion(sorted_groups)
                }
            )
        }))
    }
    
    // Get Users for Group
    func getUsersForGroup(group: Group, completion: @escaping ([User]) -> ()) {
        db_model.getUsersForGroup(groupId: group.id, completion:{ (users) -> () in
            let included = self.memory_model.update(group: group, users: users)
            completion(included)
        })
    }
    
    func getActivitiesForGroups(groups: [Group], completion: @escaping (([GroupActivity]) -> Void )) {
        let gas = memory_model.getActivitiesForGroups(groups: groups)
        if( gas.count != 0 ) {
            return completion(gas)
        }
        db_model.getActivitiesForGroups(groups: groups, completion: { (activities) -> () in
            self.memory_model.update(activities: activities)
            completion(activities)
        })
    }
    
    func getActivityForGroup(groupId: RecordId, completion: @escaping (GroupActivity?) -> Void) {
        let activity = memory_model.getGroupActivity(groupId: groupId)
        if( activity != nil ) {
            return completion(activity)
        }
        db_model.getActivityForGroup(groupId: groupId, completion: { (activity) -> () in
            if( activity != nil ) {
                self.memory_model.update(groupActivity: activity!)
            }
            completion(activity)
        })
    }
    
    func getThreadsForGroup(group: Group, completion: @escaping ([ConversationThread]) -> Void) {
        // use cached threads if any
        let cthreads = getThreadsForGroup(groupId: group.id)
        if( cthreads.count != 0 ) {
            return completion(cthreads)
        }
        db_model.getThreadsForGroup(groupId: group.id, completion: { (cthreads) -> Void in
            let included = self.memory_model.update(group: group, cthreads: cthreads)
            completion(included)
        })
    }
    
    func getMessagesForThread(thread: ConversationThread, completion : @escaping ([Message]) -> Void) {
        // use cached messages if any
        let messages = getMessagesForThread(thread: thread)
        if( messages.count > 0 ) {
            return completion(messages)
        }
        db_model.getMessagesForThread(threadId: thread.id, completion: { (messages) -> Void in
            let included = self.memory_model.update(threadId: thread.id, messages: messages)
            completion(included)
        })
    }
    
    func enterBackgroundMode() {
        // Empty cache that is relied upon as the application will not be notified of any new changes.
        memory_model.messages = nil
        memory_model.conversations = nil
        memory_model.groups = nil
        memory_model.group_activities = nil
    }
    
    // In memory query
    
    // Return messages in conversation, sorted from oldest to youngest
    private func getMessagesForThread(thread: ConversationThread) -> [Message] {
        if( memory_model.messages != nil ) {
            return memory_model.messages!.filter( { (mess) -> Bool in
                return mess.conversation_id == thread.id
            }).sorted(by: { (m1, m2) -> Bool in
                m1.last_modified < m2.last_modified
            })
        } else {
            return [Message]()
        }
    }
    
    func getConversationThread(threadId: RecordId) -> ConversationThread? {
        if( memory_model.conversations != nil ) {
            for conv in memory_model.conversations! {
                if( conv.id == threadId ) {
                    return conv
                }
            }
        }
        return nil
    }
    
    func getUser(phoneNumber: String, completion: @escaping (User?) -> Void) {
        db_model.getUser(phoneNumber: phoneNumber, completion: {(user) -> () in
            self.memory_model.update(user: user)
            completion(user)
        })
    }

    func getUser(userId: RecordId) -> User? {
        for user in memory_model.users {
            if( user.id == userId ) {
                return user
            }
        }
        return nil
    }
    
    func getGroup(id: RecordId) -> Group? {
        if( memory_model.groups != nil ) {
            for gr in memory_model.groups! {
                if( gr.id == id ) {
                    return gr
                }
            }
        }
        return nil
    }
    
    func getUsers(group: Group) -> [User] {
        var users = [User]()
        for f in memory_model.groupUserFolder {
            if( f.group === group ) {
                users.append(f.user)
            }
        }
        return users
    }
    
    // Return conversations in group, sorted from youngest to oldest
    private func getThreadsForGroup(groupId: RecordId) -> [ConversationThread] {
        var cthreads = [ConversationThread]()
        if( memory_model.conversations != nil ) {
            for cthread in memory_model.conversations!  {
                if( cthread.group_id == groupId ) {
                    cthreads.append(cthread)
                }
            }
            return cthreads.sorted(by: { (ct1, ct2) -> Bool in
                ct1.last_modified > ct2.last_modified
            })
        } else {
            return cthreads
        }
    }
    
    func getMyActivity(threadId: RecordId) -> UserActivity? {
        let userId = me().id
        
        for a in memory_model.user_activities {
            if( a.user_id == userId && a.thread_id == threadId ) {
                return a
            }
        }
        return nil
    }
    
    func updateMyActivity(thread: ConversationThread, date: Date, withNewMessage: Message?)  {
        let userId = me().id
        
        // Get Activity in buffer
        let activity = getMyActivity(threadId: thread.id)
        if( activity == nil ) {
            let new_activity = UserActivity(user_id: userId, thread_id: thread.id)
            new_activity.last_read = date
            self.memory_model.user_activities.append(new_activity)
            
            // Get activity in DB and perform update in completion.
            db_model.getActivity(userId: userId, threadId: thread.id, completion :{ (db_activity) -> () in
                if( db_activity == nil ) {
                    self.db_model.saveActivity(activity: new_activity)
                } else {
                    // transfer identity
                    new_activity.id = db_activity!.id
                    new_activity.last_read = date
                    self.db_model.saveActivity(activity: new_activity)
                }
            })
        } else {
            activity!.last_read = date
            self.db_model.saveActivity(activity: activity!)
        }
        
        if( withNewMessage != nil ) {
            thread.last_modified = date
            saveConversationThread(conversationThread: thread)
            
            getActivityForGroup(groupId: thread.group_id, completion: { ( db_activity) -> () in
                var activity : GroupActivity!
                if( db_activity != nil ) {
                    activity = db_activity
                } else {
                    activity = GroupActivity(group_id: thread.group_id)
                }
                activity!.last_modified = date
                activity!.last_userId = userId
                activity!.last_message = withNewMessage!.text
                self.db_model.saveActivity(activity: activity!)
            })
        }
    }
    
    func saveContext() {
    }
    
    func groupMessageUnread(group: Group, cthreads: [ConversationThread]) -> Int {
        var count = 0
        
        for c in cthreads {
            let a = getMyActivity( threadId: c.id)
            if( a == nil || (a?.last_read)! < c.last_modified ) {
                count += 1
            }
        }
        return count
    }
    
    func me() -> User {
        return memory_model.users.first!
    }
    
    func saveUser(user: User) {
        db_model.saveUser(user: user)
        memory_model.update(user: user)
    }
    
    func saveGroup(group: Group) {
        db_model.saveGroup(group: group)
        
        for mv in views {
            if( mv.notify_new_group != nil ) {
                mv.notify_new_group!(group)
            }
        }
    }
    
    func saveMessage(message: Message) {
        db_model.saveMessage(message: message)
        for mv in views {
            if( mv.notify_new_message != nil ) {
                mv.notify_new_message!(message)
            }
        }
    }
    
    func addUserToGroup(group: Group, user: User) {
        db_model.addUserToGroup(group: group, user: user)
        memory_model.groupUserFolder.append((group: group, user: user))
    }
    
    func saveConversationThread(conversationThread: ConversationThread) {
        db_model.saveConversationThread(conversationThread: conversationThread)
        
        for mv in views {
            if( mv.notify_new_conversation != nil ) {
                mv.notify_new_conversation!(conversationThread)
            }
        }
    }
    
    func saveActivity(groupActivity: GroupActivity) {
        db_model.saveActivity(activity: groupActivity)
        memory_model.update(groupActivity: groupActivity)
    }
    
    /*************************************************/
    
    // Setup notifications to receive notification on new/edited messages in the group
    func setupNotifications(cthread: ConversationThread, view: ModelView) {
        if( view.notify_new_message != nil || view.notify_edit_message != nil ) {
            uniquely_append(view)
            db_model.setupNotifications(cthread: cthread)
        }
    }
    
    // Setup notifications to receive notification on new conversations in the group
    func setupNotifications(groupId: RecordId, view: ModelView) {
        if( view.notify_new_conversation != nil || view.notify_edit_group_activity != nil ) {
            uniquely_append(view)
            db_model.setupNotifications(groupId: groupId)
        }
    }
    
    // Setup notifications to receive notification on new groups for the user
    func setupNotifications(userId: RecordId, view: ModelView) {
        if( view.notify_new_group != nil ) {
            uniquely_append(view)
            db_model.setupNotifications(userId: userId)
        }
    }

    func receiveRemoteNotification(userInfo: [AnyHashable : Any]) {
        db_model.didReceiveNotification(userInfo: userInfo, views: views)
    }
    
    func uniquely_append(_ view: ModelView) {
        let contained = views.contains(where: { (v) -> Bool in return view === v })
        if( !contained ) {
            views.append(view)
        }
    }
    func removeViews(views: [ModelView]) {
        for v in views {
            let index = self.views.index(where: {(view) -> Bool in return view === v })
            if( index != nil ) {
                self.views.remove(at: index!)
            }
        }
    }
    
    func setAppBadgeNumber(number: Int) {
        db_model.setAppBadgeNumber(number: number)
    }
    
    /*************************************************/
    
    func getDecorationThemes(completion: @escaping ([DecorationTheme]) -> Void ) {
        if( memory_model.decorationThemes.count != 0 ) {
            return completion(memory_model.decorationThemes)
        }
        db_model.getDecorationThemes(completion: { themes in
            self.memory_model.updateDecorationThemes(themes: themes)
            completion(themes)
        })
    }
    
    func getDecorationStamp(theme: DecorationTheme, completion: @escaping ([DecorationStamp]) -> Void ) {
        let stamps = memory_model.decorationStamps.filter( { (stamp) -> Bool in
            return stamp.theme_id == theme.id
        })
        if( stamps.count != 0 ) {
            return completion(stamps)
        } else {
            // Buffer existing request, so only one request is send to the server
            var existing_requests = pendingStampRequests[theme.id]
            if( existing_requests != nil ) {
                existing_requests!.append(completion)
            } else {
                existing_requests = [completion]
                
                db_model.getDecorationStamps(theme: theme, completion: { (stamps) -> Void in
                    self.memory_model.updateDecorationStamps(stamps: stamps)
                    
                    let requests = self.pendingStampRequests[theme.id]
                    if( requests != nil ) {
                        for r in requests! {
                            r(stamps)
                        }
                    }
                    self.pendingStampRequests[theme.id] = nil
                })
            }
            pendingStampRequests[theme.id] = existing_requests
        }
    }
    
    func getTheme(name: String) -> DecorationTheme? {
        for t in memory_model.decorationThemes {
            if( t.name == name ) {
                return t
            }
        }
        return nil
    }
    
    /******************************************************************/
    
    func deleteConversationThread(conversationThread: ConversationThread) {
        if( memory_model.conversations != nil ) {
            let index = memory_model.conversations!.index(where: { (cthread) -> Bool in
                cthread.id == conversationThread.id
            })
            if( index != nil ) {
                memory_model.conversations!.remove(at: index!)
            }
        }
        db_model.deleteRecord(record: conversationThread.id, completion: { })
    }
}

var model : DataModel!


class DBModelTest {
    class func getUser0() {
        
    }
    
    class func setup() {
        getUser0()
        
        let user1 = User(id: RecordId(), label: "John Doe", phoneNumber: "2222" )
        user1.icon = UIImage(named: "user_male3-32")
        let user2 = User(id: RecordId(), label: "Elli Car", phoneNumber: "3333" )
        user2.icon = UIImage(named: "user_female3-32")
        model.saveUser(user: user1)
        model.saveUser(user: user2)
        
        Thread.sleep(forTimeInterval: 30)
        
        let group1 = Group(id: RecordId(), name: "Group 1")
        let group1Activity = GroupActivity(group_id: group1.id)
        model.saveActivity(groupActivity: group1Activity)
        group1.activity_id = group1Activity.id
        model.saveGroup(group: group1)
        model.addUserToGroup(group: group1, user: model.me())
        model.addUserToGroup(group: group1, user: user1)
        model.addUserToGroup(group: group1, user: user2)

        let group2 = Group(id: RecordId(), name: "Group 2")
        let group2Activity = GroupActivity(group_id: group2.id)
        model.saveActivity(groupActivity: group2Activity)
        group2.activity_id = group2Activity.id
        model.saveGroup(group: group2)
        model.addUserToGroup(group: group2, user: model.me())
        model.addUserToGroup(group: group2, user: user1)
        
        Thread.sleep(forTimeInterval: 30)
        
        for i in 1...3 {
            let thread = ConversationThread(id: RecordId(), group_id: group1.id)
            thread.title = String("Thread " + String(i))
            model.saveConversationThread(conversationThread: thread)
            
            for j in 1...i*2 {
                let message = Message(thread: thread, user: j%2 == 0 ? user1 : user2)
                message.text = "Message " + String(j)
                for _ in 1...j {
                    message.text += " of some words "
                }
                model.saveMessage(message: message)
                
                // Simulate the fact that I read this message.
                model.updateMyActivity(thread: thread, date: message.last_modified, withNewMessage: message)
                
                Thread.sleep(forTimeInterval: 30)
            }
            
            // Test activity management
            if( i % 2 == 0 ) {
                let message = Message(thread: thread, user: user1)
                message.text = "Unread Message "
                
                thread.last_modified = message.last_modified
                
                model.saveMessage(message: message)
            }
        }
        
        Thread.sleep(forTimeInterval: 30)
        
        let thread = ConversationThread(id: RecordId(), group_id: group2.id)
        thread.title = String("Main")
        model.saveConversationThread(conversationThread: thread)
        let message = Message(thread: thread, user: user1)
        message.text = "Welcome to the Main conversation thread."
        model.saveMessage(message: message)
    }
}
