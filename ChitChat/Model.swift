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
    
    init(threadId: RecordId, user_id: RecordId) {
        self.id = RecordId()
        self.user_id = user_id
        self.conversation_id = threadId
    }
    
    init(id: RecordId, threadId: RecordId, user_id: RecordId) {
        self.id = id
        self.user_id = user_id
        self.conversation_id = threadId
    }
}

/************************************************************************************/

class ModelView {
    var notify_new_group : (() -> Void)?
    var notify_new_message : (() -> Void)?
    var notify_new_conversation : (() -> Void)?
}

class DataModel {
    internal var users = [User]()
    internal var groups = [Group]()
    internal var conversations = [ConversationThread]()
    internal var messages = [Message]()
    internal var activities = [UserActivity]()
    internal var groupUserFolder = [(group: Group, user: User)]()
    
    let db_model : DBProtocol!
    var views = [ModelView]()
    
    init(db_model: DBProtocol) {
        
        self.db_model = db_model
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
                    self.users.append(user0)
                    me = user0
                } else {
                    me = user!
                    self.users.append(user!)
                }
                
                self.db_model.getActivities(userId: me.id, completion: { (activities) -> Void in
                    self.activities = activities
                    completion()
                })
            })
        }
    }
    
    // Get groups
    func getGroups(completion: @escaping ([Group]) -> ()) {
        db_model.getGroupsForUser(userId: me().id, completion: ({ (groups) -> () in
            let initialGroup = self.groups
            self.groups = groups
            for igr in initialGroup {
                let contained = groups.contains(where: ({ (cgr) -> Bool in
                    igr.id == cgr.id
                }))
                if( !contained ) {
                    self.groups.append(igr)
                }
            }
            completion(self.groups)
        }))
    }
    
    // Get Users for Group
    func getUsersForGroup(group: Group, completion: @escaping ([User]) -> ()) {
        db_model.getUsersForGroup(groupId: group.id, completion:{ (users) -> () in
            var included = users
            // See if some not yet in DB elements exist
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
            completion(included)
        })
    }
    
    func getThreadsForGroup(group: Group, completion: @escaping ([ConversationThread]) -> Void) {
        db_model.getThreadsForGroup(groupId: group.id, completion: { (cthreads) -> Void in
            // See if there are some only-in-memory conversations
            var included = cthreads
            for igr in self.conversations {
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
                let contained = self.conversations.contains(where: { (conv)-> Bool in
                    return conv.id == cthread.id
                })
                if( !contained ) {
                    self.conversations.append(cthread)
                }
            }
            
            completion(included)
        })
    }
    
    func getMessagesForThread(threadId: RecordId, completion : @escaping ([Message]) -> Void) {
        db_model.getMessagesForThread(threadId: threadId, completion: { (messages) -> Void in
            // See if there are some only-in-memory conversations
            var included = messages
            for igr in self.messages {
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
                let contained = self.messages.contains(where: { (mess)-> Bool in
                    return mess.id == message.id
                })
                if( !contained ) {
                    self.messages.append(message)
                }
            }
            
            completion(included)
        })
    }
    
    // In memory stuff
    
    func getMessagesForThread(thread: ConversationThread) -> [Message] {
        return self.messages.filter( { (mess) -> Bool in
            return mess.conversation_id == thread.id
        })
    }
    
    func getConversationThread(threadId: RecordId) -> ConversationThread? {
        for conv in conversations {
            if( conv.id == threadId ) {
                return conv
            }
        }
        return nil
    }
    
    func getUser(userId: RecordId) -> User? {
        for user in users {
            if( user.id == userId ) {
                return user
            }
        }
        return nil
    }
    
    func getUsers(group: Group) -> [User] {
        var users = [User]()
        for f in groupUserFolder {
            if( f.group === group ) {
                users.append(f.user)
            }
        }
        return users
    }
    
    func getThreadsForGroup(groupId: RecordId) -> [ConversationThread] {
        var cthreads = [ConversationThread]()
        for cthread in conversations  {
            if( cthread.group_id == groupId ) {
                cthreads.append(cthread)
            }
        }
        return cthreads
    }
    
    func getMyActivity(threadId: RecordId) -> UserActivity? {
        let userId = me().id
        
        for a in activities {
            if( a.user_id == userId && a.thread_id == threadId ) {
                return a
            }
        }
        return nil
    }
    
    func updateMyActivity(thread: ConversationThread, date: Date)  {
        let userId = me().id
        
        // Get Activity in buffer
        let activity = getMyActivity(threadId: thread.id)
        if( activity == nil ) {
            let new_activity = UserActivity(user_id: userId, thread_id: thread.id)
            new_activity.last_read = date
            self.activities.append(new_activity)
            
            // Get activity in DB and perform update in completion.
            db_model.getActivity(userId: userId, threadId: thread.id, completion :({ (db_activity) -> () in
                if( db_activity == nil ) {
                    self.db_model.saveActivity(activity: new_activity)
                } else {
                    // transfer identity
                    new_activity.id = db_activity!.id
                    new_activity.last_read = date
                }
            }))
        } else {
            activity!.last_read = date
        }
        
        thread.last_modified = date
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
        return users.first!
    }
    
    func saveUser(user: User) {
        db_model.saveUser(user: user)
        users.append(user)
        
    }
    
    func saveGroup(group: Group) {
        db_model.saveGroup(group: group)
        groups.append(group)
        
        // TODO - Once notification services have been implemented see if we can only give the new group(s).
        for mv in views {
            if( mv.notify_new_group != nil ) {
                mv.notify_new_group!()
            }
        }
    }
    
    func saveMessage(message: Message) {
        db_model.saveMessage(message: message)
        messages.append(message)
        
        // TODO - Once notification services have been implemented see if we can only give the new message(s)
        for mv in views {
            if( mv.notify_new_message != nil ) {
                mv.notify_new_message!()
            }
        }
    }
    
    func addUserToGroup(group: Group, user: User) {
        db_model.addUserToGroup(group: group, user: user)
        groupUserFolder.append((group: group, user: user))
    }
    
    func saveConversationThread(conversationThread: ConversationThread) {
        db_model.saveConversationThread(conversationThread: conversationThread)
        conversations.append(conversationThread)
        
        // TODO - Once notification services have been implemented see if we can only give the new conversations(s)
        for mv in views {
            if( mv.notify_new_conversation != nil ) {
                mv.notify_new_conversation!()
            }
        }
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
        
        let myId = model.me().id
        let otherId = user1.id.id == myId.id ? user2.id : user1.id
        
        for i in 1...3 {
            let thread = ConversationThread(id: RecordId(), group_id: group1.id)
            thread.title = String("Thread " + String(i))
            model.saveConversationThread(conversationThread: thread)
            
            for j in 1...i*2 {
                let message = Message(threadId: thread.id, user_id: j%2 == 0 ? user1.id : user2.id)
                message.text = "Message " + String(j)
                for _ in 1...j {
                    message.text += " of some words "
                }
                model.saveMessage(message: message)
                
                // Simulate the fact that I read this message.
                model.updateMyActivity(thread: thread, date: message.last_modified)
            }
            
            // Test activity management
            if( i % 2 == 0 ) {
                let message = Message(threadId: thread.id, user_id: otherId)
                message.text = "Unread Message "
                
                thread.last_modified = message.last_modified
                
                model.saveMessage(message: message)
            }
        }
    }
}
