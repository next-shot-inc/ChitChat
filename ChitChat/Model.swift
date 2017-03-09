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

class RecordId {
    let id : String
    init() {
        id = UUID().uuidString
    }
    init(string: String) {
        self.id = string
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
    let user_id : RecordId
    let thread_id : RecordId
    var last_read : Date
    
    init(user_id: RecordId, thread_id: RecordId) {
        self.user_id = user_id
        self.thread_id = thread_id
        self.last_read = Date()
    }
}

class Group {
    var id : RecordId
    var user_ids = [RecordId]()
    var name = String()
    var icon: UIImage?
    
    init(id: RecordId, name: String) {
        self.id = id
        self.name = name
    }
}

class ConversationThread {
    let id : RecordId
    var group_id : RecordId
    var last_modified = Date()
    var title = String()
    
    init(id: RecordId, group_id: RecordId) {
        self.id = id
        self.group_id = group_id
    }
}

class Message {
    let id : RecordId
    let conversation_id : RecordId
    let user_id : RecordId
    var text = String()
    var last_modified = Date()
    
    init(threadId: RecordId, user_id: RecordId) {
        self.id = RecordId()
        self.user_id = user_id
        self.conversation_id = threadId
    }
}

class DBModel {
    var users = [User]()
    var groups = [Group]()
    var conversations = [ConversationThread]()
    var messages = [Message]()
    var activities = [UserActivity]()
    
    func getGroupForUser(userId: RecordId) -> [Group] {
        return groups.filter({ (group: Group) -> Bool in
            return group.user_ids.contains(where: { (id: RecordId) -> Bool in
                id.id == userId.id
            })
        })
    }
    
    func getThreadsForGroup(groupId: RecordId) -> [ConversationThread] {
        return conversations.filter({ (thread: ConversationThread) -> Bool in
            thread.group_id.id == groupId.id
        })
    }
    
    func getThread(threadId: RecordId) -> ConversationThread? {
        for c in conversations {
            if( c.id.id == threadId.id ) {
                return c
            }
        }
        return nil
    }
    
    func getMessagesForThread(threadId: RecordId) -> [Message] {
        return messages.filter({ (message: Message) -> Bool in
            message.conversation_id.id == threadId.id
        })
    }
    
    func getUser(userId: RecordId) -> User? {
        for u in users {
            if( u.id.id == userId.id ) {
                return u
            }
        }
        return nil
    }
    
    func getUser(phoneNumber: String) -> User? {
        for u in users {
            if( u.phoneNumber == phoneNumber ) {
                return u
            }
        }
        return nil
    }
    
    func me() -> User {
        return users.first!
    }
    
    func getActivity(userId: RecordId, threadId: RecordId) -> UserActivity? {
        for a in activities {
            if( a.user_id.id == userId.id && a.thread_id.id == threadId.id ) {
                return a
            }
        }
        return nil
    }
    
    func updateActivity(userId: RecordId, threadId: RecordId, date: Date)  {
        var activity = getActivity(userId: userId, threadId: threadId)
        if( activity == nil ) {
            activity = UserActivity(user_id: userId, thread_id: threadId)
            db_model.activities.append(activity!)
        }
        activity!.last_read = date
        
        let ct = getThread(threadId: threadId)
        ct?.last_modified = date
    }
    
    func groupMessageUnread(groupId: RecordId, userId: RecordId) -> Int {
        var count = 0
        let conv = getThreadsForGroup(groupId: groupId)
        for c in conv {
            let a = getActivity(userId: userId, threadId: c.id)
            if( a == nil || (a?.last_read)! < c.last_modified ) {
                count += 1
            }
        }
        return count
    }
}

var db_model = DBModel()

class DBModelTest {
     class func getUser0() {
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
            let user0 = User(
                id: RecordId(), label: userInfo!.name!, phoneNumber: userInfo!.telephoneNumber!
            )
            db_model.users.append(user0)
        }
    }
    
    class func setup() {
        getUser0()
        
        let user1 = User(id: RecordId(), label: "John Doe", phoneNumber: "2222" )
        user1.icon = UIImage(named: "user_male3-32")
        let user2 = User(id: RecordId(), label: "Elli Car", phoneNumber: "3333" )
        user2.icon = UIImage(named: "user_female3-32")
        db_model.users.append(user1)
        db_model.users.append(user2)
        
        let group1 = Group(id: RecordId(), name: "Group 1")
        group1.user_ids.append(db_model.me().id)
        group1.user_ids.append(user1.id)
        group1.user_ids.append(user2.id)
        let group2 = Group(id: RecordId(), name: "Group 2")
        group2.user_ids.append(db_model.me().id)
        group2.user_ids.append(user1.id)
        
        db_model.groups.append(group1)
        db_model.groups.append(group2)
        
        let myId = db_model.me().id
        let otherId = user1.id.id == myId.id ? user2.id : user1.id
        
        for i in 1...5 {
            let thread = ConversationThread(id: RecordId(), group_id: group1.id)
            thread.title = String("Thread " + String(i))
            db_model.conversations.append(thread)
            
            var my_activity = db_model.getActivity(userId: myId, threadId: thread.id)
            if( my_activity == nil ) {
                my_activity = UserActivity(user_id: myId, thread_id: thread.id)
                db_model.activities.append(my_activity!)
            }
            for j in 1...i*2 {
                let message = Message(threadId: thread.id, user_id: j%2 == 0 ? user1.id : user2.id)
                message.text = "Message " + String(j)
                for _ in 1...j {
                    message.text += " of some words "
                }
                db_model.messages.append(message)
                
                // Activity management
                thread.last_modified = message.last_modified
                if( message.user_id.id == myId.id ) {
                    my_activity!.last_read = message.last_modified
                }
            }
            
            // Test activity management
            if( i % 2 == 0 ) {
                let message = Message(threadId: thread.id, user_id: otherId)
                message.text = "Unread Message "
                
                thread.last_modified = message.last_modified
                
                db_model.messages.append(message)
            }
        }
    }
}
