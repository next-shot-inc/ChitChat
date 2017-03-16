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
    var last_modified = Date()
    var details = String()
    var last_userId : RecordId?
    var last_message = String()
    
    init(id: RecordId, name: String) {
        self.id = id
        self.name = name
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
    let conversation_id : RecordId
    let user_id : RecordId
    var text = String()
    var image : UIImage?
    var last_modified = Date()
    var fromName = String()
    var inThread = String()
    
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

/************************************************************************************/

class ModelView {
    var notify_new_group : ((_ group: Group) -> Void)?
    var notify_new_message : ((_ message: Message) -> Void)?
    var notify_edit_message : ((_ message: Message) -> Void)?
    var notify_new_conversation : ((_ cthread: ConversationThread) -> Void)?
}

class MemoryModel {
    var users = [User]()
    var groups : [Group]?
    var conversations : [ConversationThread]?
    var messages : [Message]?
    var activities = [UserActivity]()
    var groupUserFolder = [(group: Group, user: User)]()
    
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
}

class DataModel {
    internal let memory_model = MemoryModel()
    let db_model : DBProtocol!
    var views = [ModelView]()
    var start_date = Date()
    
    init(db_model: DBProtocol) {
        self.db_model = db_model
        
        let model_view = MemoryModelView(memory_model: memory_model)
        views.append(model_view)
    }
    
    func getUserInfo(completion: @escaping () -> Void) {
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
                
                self.db_model.getActivities(userId: me.id, completion: { (activities) -> Void in
                    self.memory_model.activities = activities
                    completion()
                })
            })
        }
    }
    
    // Get groups
    func getGroups(completion: @escaping ([Group]) -> ()) {
        if( memory_model.groups != nil ) {
            completion(memory_model.groups!)
        }
        db_model.getGroupsForUser(userId: me().id, completion: ({ (groups) -> () in
            self.memory_model.update(groups: groups)
            completion(self.memory_model.groups!)
        }))
    }
    
    // Get Users for Group
    func getUsersForGroup(group: Group, completion: @escaping ([User]) -> ()) {
        db_model.getUsersForGroup(groupId: group.id, completion:{ (users) -> () in
            let included = self.memory_model.update(group: group, users: users)
            completion(included)
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
        
        for a in memory_model.activities {
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
            self.memory_model.activities.append(new_activity)
            
            // Get activity in DB and perform update in completion.
            db_model.getActivity(userId: userId, threadId: thread.id, completion :({ (db_activity) -> () in
                if( db_activity == nil ) {
                    self.db_model.saveActivity(activity: new_activity)
                } else {
                    // transfer identity
                    new_activity.id = db_activity!.id
                    new_activity.last_read = date
                    self.db_model.saveActivity(activity: new_activity)
                }
            }))
        } else {
            activity!.last_read = date
            self.db_model.saveActivity(activity: activity!)
        }
        
        if( withNewMessage != nil ) {
            thread.last_modified = date
            saveConversationThread(conversationThread: thread)
            
            let group = getGroup(id: thread.group_id)
            if( group != nil ) {
                group!.last_modified = date
                group!.last_userId = userId
                group!.last_message = withNewMessage!.text
                saveGroup(group: group!)
            }
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
    
    /*************************************************/
    
    func setupNotifications(cthread: ConversationThread, view: ModelView) {
        if( view.notify_new_message != nil ) {
            views.append(view)
            db_model.setupNotifications(cthread: cthread)
        }
    }
    
    func setupNotifications(groupId: RecordId, view: ModelView) {
        if( view.notify_new_conversation != nil ) {
            views.append(view)
            db_model.setupNotifications(groupId: groupId)
        }
    }

    func receiveRemoteNotification(userInfo: [AnyHashable : Any]) {
        db_model.didReceiveNotification(userInfo: userInfo, views: views)
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
        
        let group1 = Group(id: RecordId(), name: "Group 1")
        model.saveGroup(group: group1)
        model.addUserToGroup(group: group1, user: model.me())
        model.addUserToGroup(group: group1, user: user1)
        model.addUserToGroup(group: group1, user: user2)

        let group2 = Group(id: RecordId(), name: "Group 2")
        model.saveGroup(group: group2)
        model.addUserToGroup(group: group2, user: model.me())
        model.addUserToGroup(group: group2, user: user1)
        
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
            }
            
            // Test activity management
            if( i % 2 == 0 ) {
                let message = Message(thread: thread, user: user1)
                message.text = "Unread Message "
                
                thread.last_modified = message.last_modified
                
                model.saveMessage(message: message)
            }
        }
    }
}
