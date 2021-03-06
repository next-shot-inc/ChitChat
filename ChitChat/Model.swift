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
import KeychainSwift

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
    var passKey : String?
    var recoveryQuestion: String?
    var recoveryKey : String?
    
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

class UserInvitation {
    var id: RecordId
    var from_user_id: RecordId
    var to_user: String
    var to_user_label : String?
    var to_group_id: RecordId
    var accepted = false
    var date_created = Date()
    
    init(id: RecordId, from_user_id: RecordId, to_group_id: RecordId, to_user: String) {
        self.id = id
        self.from_user_id = from_user_id
        self.to_group_id = to_group_id
        self.to_user = to_user
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
    var user_id : RecordId?
    var last_modified = Date()
    var title = String()
    var createdFromMessage_id: RecordId?
    
    init(id: RecordId, group_id: RecordId, user_id: RecordId?) {
        self.id = id
        self.group_id = group_id
        self.user_id = user_id
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
    var group_id : RecordId?
    var text = String()
    var image : UIImage?
    var largeImage: UIImage?
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
        self.group_id = thread.group_id
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
    var category = "DecoratedText"
    var options : NSDictionary?
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

protocol MessageRecordDelegate {
    func fetch(dict: NSDictionary)
    func put(dict: NSMutableDictionary)
}

class MessageRecord {
    var id: RecordId
    let message_id: RecordId
    var group_id : RecordId?
    let user_id : RecordId
    var type : String
    var date_created = Date()
    var version : String = "1.0"
    var delegate : MessageRecordDelegate?
    var payLoad = String()
    
    init(message: Message, user: User, type: String) {
        self.id = RecordId()
        self.message_id = message.id
        self.group_id = message.group_id
        self.type = type
        self.user_id = user.id
    }
    
    init(id: RecordId, message_id: RecordId, user_id: RecordId, type: String) {
        self.id = id
        self.message_id = message_id
        self.user_id = user_id
        self.type = type
    }
    
    init(record: MessageRecord, type: String) {
        self.id = record.id
        self.message_id = record.message_id
        self.user_id = record.user_id
        self.group_id = record.group_id
        self.type = type
        self.date_created = record.date_created
        self.version = record.version
        self.payLoad = record.payLoad
    }
    
    func getPayLoad() -> String {
        let dict = NSMutableDictionary()
        dict.setValue(NSString(string: type),  forKey: "type")
        dict.setValue(NSString(string: version), forKey:  "version")
        delegate?.put(dict: dict)
        
        do {
            let data = try JSONSerialization.data(withJSONObject: dict, options: [])
            return String(data: data, encoding: String.Encoding.utf8)!
        } catch {
            return String()
        }
    }
    
    func initFromPayload(string: String) {
        var jsonResult : Any?
        do {
            try jsonResult = JSONSerialization.jsonObject(
                with: string.data(using: String.Encoding.utf8)!,
                options: JSONSerialization.ReadingOptions.mutableContainers
            )
        } catch {
            jsonResult = nil
            print("JSON Error")
        }
        
        if( jsonResult != nil && jsonResult is NSDictionary ) {
            let jsonMessage = jsonResult! as! NSDictionary
            version = (jsonMessage["version"] as! NSString) as String
            type = (jsonMessage["type"] as! NSString) as String
            
            delegate?.fetch(dict: jsonMessage)
        }
    }

}

/************************************************************************************/

class ModelView {
    var notify_new_group : ((_ group: Group) -> Void)?
    var notify_edit_group : ((_ group: Group, _ user: User) -> Void)?
    var notify_new_message : ((_ message: Message) -> Void)?
    var notify_edit_message : ((_ message: Message) -> Void)?
    var notify_new_conversation : ((_ cthread: ConversationThread) -> Void)?
    var notify_edit_group_activity : ((_ activity: GroupActivity) -> Void)?
    var notify_delete_conversation : ((_ id: RecordId) -> Void)?
    var notify_new_message_record : ((_ messageRecord: MessageRecord) -> Void)?
    var notify_edit_message_record: ((_ messageRecord: MessageRecord) -> Void)?
}

struct MessageDateRange {
    var min: Int
    var max: Int
    
    func getDates() -> DateInterval {
        let secondsInADay : TimeInterval = 24*60*60
        let min_date = Date(timeInterval: -TimeInterval(max)*secondsInADay, since: Date())
        let max_date = Date(timeInterval: -TimeInterval(min)*secondsInADay, since: Date())
        return DateInterval(start: min_date, end: max_date)
    }
    
    func insideRange(date: Date, interval: DateInterval) -> Bool {
        return date <= interval.end && date > interval.start
    }
    
    func contains(range: MessageDateRange) -> Bool {
        return range.min >= min && range.max <= max
    }
}

class MemoryModel {
    var users = [User]()
    var groups : [Group]?
    var conversations : [ConversationThread]?
    var messages : [Message]?
    var messageDateRanges = [RecordId: MessageDateRange]()
    var user_activities = [UserActivity]()
    var group_activities: [GroupActivity]?
    var groupUserFolder = [(group: Group, user: User)]()
    var decorationThemes = [DecorationTheme]()
    var decorationStamps = [DecorationStamp]()
    var messageRecords: [MessageRecord]?
    
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
            if( item.group.id == group.id ) {
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
                grp.id == group.id && usr.id == user.id
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
    
    // Update called when a user is added to a group by another user
    func update(group: Group, user: User) {
        // Update memory table
        let contained = self.groupUserFolder.contains(where: { (grp, usr) -> Bool in
            grp.id == group.id && usr.id == user.id
        })
        if( !contained ) {
            self.groupUserFolder.append((group: group, user: user))
        }
        if( self.groups != nil ) {
            let gr_contained = self.groups!.contains(where: { (gr) -> Bool in
                gr.id == group.id
            })
            if( !gr_contained ) {
                self.groups!.append(group)
            }
        }
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
    
    func update(users: [User]) {
        for user in users {
            let contained = self.users.contains(where: { (usr) -> Bool in
                user.id == usr.id
            })
            if( !contained ) {
                self.users.append(user)
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
        
        var need_sort = false
        for igr in self.messages! {
            if( igr.conversation_id == threadId ) {
                let contained = messages.contains(where: { (cgr) -> Bool in
                    igr.id == cgr.id
                })
                if( !contained ) {
                    included.append(igr)
                    need_sort = true
                }
            }
        }
        if( need_sort ) {
            included = included.sorted(by: { (m1, m2) -> Bool in
                m1.last_modified < m2.last_modified
            })
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
    
    func update(threadId: RecordId, messages: [Message], range: MessageDateRange) -> [Message] {
        let existing_range = messageDateRanges[threadId]
        if( existing_range != nil ) {
            let merge_range = MessageDateRange(
                min: min(existing_range!.min, range.min), max: max(existing_range!.max, range.max)
            )
            messageDateRanges[threadId] = merge_range
        } else {
            messageDateRanges[threadId] = range
        }
        return update(threadId: threadId, messages: messages)
    }
    
    func updateThread(message: Message) {
        if( self.conversations == nil ) {
            return
        }
        
        let index = conversations!.index( where: { (conv) -> Bool in
            return conv.id == message.conversation_id
        })
        if( index != nil ) {
            let cthread = conversations![index!]
            cthread.last_modified = message.last_modified
        }
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
    
    func updateMessageRecords(messageRecords: [MessageRecord]) {
        if( self.messageRecords == nil ) {
            self.messageRecords = [MessageRecord]()
            self.messageRecords!.append(contentsOf: messageRecords)
        } else {
            for r in messageRecords {
                let index = self.messageRecords!.index(where: { (record)-> Bool in
                    return r.id == record.id
                })
                if( index != nil ) {
                    self.messageRecords!.remove(at: index!)
                    self.messageRecords!.insert(r, at: index!)
                } else {
                    self.messageRecords!.append(r)
                }
            }
        }
    }
    
    func getConversationThreadCreatedFrom(message: Message) -> ConversationThread? {
        if( conversations == nil ) {
            return nil
        }
        let index = conversations!.index( where: { (conv) -> Bool in
            return conv.createdFromMessage_id == message.id
        })
        if( index != nil ) {
            let cthread = conversations![index!]
            return cthread
        } else {
            return nil
        }
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
        self.notify_delete_conversation = delete_cthread
        self.notify_new_message_record = new_message_record
        self.notify_edit_message_record = edited_message_record
    }
    
    func new_message(message: Message) {
        if( memory_model.messages != nil ) {
            let index = memory_model.messages!.index(where: { (mess)-> Bool in
                return mess.id == message.id
            })
            if( index == nil ) {
                memory_model.messages!.append(message)
            }
            // Update conversation thread date (as no events is sent)
            memory_model.updateThread(message: message)
        } else {
            memory_model.messages = [Message]()
            memory_model.messages!.append(message)
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
                
                // Update conversation thread date (as no events is sent)
                memory_model.updateThread(message: message)
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
    
    func delete_cthread(id: RecordId) {
        if( memory_model.conversations != nil ) {
            let index = memory_model.conversations!.index(where: { (conv) -> Bool in
                return conv.id == id
            })
            if( index != nil ) {
                memory_model.conversations!.remove(at: index!)
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
    
    func new_message_record(pr: MessageRecord) {
        memory_model.updateMessageRecords(messageRecords: [pr])
    }
    
    func edited_message_record(pr: MessageRecord) {
        if( memory_model.messageRecords != nil ) {
            let index = memory_model.messageRecords!.index(where: { (r)-> Bool in
                return r.id == pr.id
            })
            if( index != nil ) {
                memory_model.messageRecords!.remove(at: index!)
                memory_model.messageRecords!.insert(pr, at: index!)
            }
        }
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
    
    func getUserInfo(completion: @escaping (_ status: Bool, _ new_user: Bool) -> Void) {
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
        
        let keychain = KeychainSwift()
        keychain.synchronizable = true
        let password = keychain.get("password")
        if( password == nil ) {
            print("Could not get User Password")
            completion(false, false)
            return
        }
        
        func hash(string: String) -> Int {
            var h = 5381
            for v in string.unicodeScalars {
                let v = v.value
                h = ((h << 5) &+ h) &+ Int(v)
            }
            return h
        }
        func hexKey(value: Int) -> String {
            var number = value
            let data = NSData(bytes: &number, length: MemoryLayout<Int>.size)
            return data.base64EncodedString(options: [])
        }
        
        if( userInfo != nil ) {
            db_model.getUser(phoneNumber: userInfo!.telephoneNumber!, completion: {(user) -> () in
                var me : User!
                if( user == nil ) {
                    // Create user. Store passkey into DB
                    let user0 = User(
                        id: RecordId(), label: userInfo!.name!, phoneNumber: userInfo!.telephoneNumber!
                    )
                    let augmented_password = user0.id.id + password!
                    user0.passKey = hexKey(value: hash(string: augmented_password))
                    
                    self.db_model.saveUser(user: user0, completion: {_ in })
                    self.memory_model.users.append(user0)
                    
                    me = user0
                } else {
                    // Existing user - test passkey 
                    let augmented_password = user!.id.id + password!
                    let passKey = hexKey(value: hash(string: augmented_password))
                    if( user!.passKey == nil || user!.passKey!.isEmpty ) {
                        // For users created before password was necessary.
                        user!.passKey = passKey
                        self.db_model.saveUser(user: user!, completion: {_ in })
                    }
                    if( passKey != user!.passKey ) {
                        print("Password invalid")
                        completion(false, false)
                        return
                    }
                    
                    me = user!
                    self.memory_model.users.append(user!)
                }
                
                self.db_model.setAsUser(user: me!)
                
                self.db_model.getActivities(userId: me.id, completion: { (activities) -> Void in
                    self.memory_model.user_activities = activities
                    completion(true, user==nil)
                })
            })
        } else {
            print("Could not get User Info")
            completion(false, false)
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
    
    private func sortGroup(groups: [Group], completion : @escaping([Group]) -> ()) {
        getActivitiesForGroups(
            groups: groups,
            completion: { (activities) -> Void in
                let table = self.createGroupActivityTable(groups: groups, activities: activities)
                let sorted_groups = groups.sorted(
                    by: { (g1, g2) -> Bool in table[g1.id]!.last_modified > table[g2.id]!.last_modified }
                )
                completion(sorted_groups)
        })
    }
    
    func getGroupInvitations(to_user: String, completion: @escaping ([UserInvitation], [Group]) -> ()) {
        db_model.getUserInvitations(to_user: to_user, completion: { (invitations, groups) -> () in
            self.memory_model.update(groups: groups)
            
            self.sortGroup(groups: groups, completion: { (sorted_groups) -> () in
                completion(invitations, sorted_groups)
            })
        })
    }
    
    // Get groups sorted by activities
    func getGroups(completion: @escaping ([Group]) -> ()) {
        if( memory_model.groups != nil ) {
            let groups = memory_model.groups!.filter({ (gr) -> Bool in
                let users = model.getUsers(group: gr)
                return users.contains(where: { (user) -> Bool in
                    user.id == me().id
                })
            })
            
            return sortGroup( groups: groups, completion: { (sorted_groups) -> Void in
                completion(sorted_groups)
            })
        }
        db_model.getGroupsForUser(userId: me().id, completion: { (groups) -> () in
            self.memory_model.update(groups: groups)
            
            self.sortGroup(groups: self.memory_model.groups!, completion: { (sorted_groups) -> () in
                return completion(sorted_groups)
            })
        })
    }
    
    // Get Users for Group
    func getUsersForGroup(group: Group, completion: @escaping ([User]) -> ()) {
        let users = getUsers(group: group)
        if( users.count != 0 ) {
            return completion(users)
        }
        db_model.getUsersForGroup(groupId: group.id, completion:{ (users) -> () in
            let included = self.memory_model.update(group: group, users: users)
            completion(included)
        })
    }
    
    func getUsersAndInvitedForGroup(group: Group, completion: @escaping ([User], [UserInvitation]) -> ()) {
        db_model.getUsersForGroup(groupId: group.id, completion:{ (users) -> () in
            let included = self.memory_model.update(group: group, users: users)
            
            self.db_model.getUserInvitations(to_group: group, completion: { (invitations) in
                completion(included, invitations)
            })
        })
    }
    
    func getActivitiesForGroups(groups: [Group], completion: @escaping (([GroupActivity]) -> Void )) {
        let gas = memory_model.getActivitiesForGroups(groups: groups)
        if( gas.count == groups.count ) {
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
    
    func getMessagesForThread(
        thread: ConversationThread, dateLimit: MessageDateRange, completion: @escaping (_ messages: [Message], _ dateLimit: MessageDateRange) -> ()
    ) {
        let messages = getMessagesForThread(thread: thread)
        let cached_range = memory_model.messageDateRanges[thread.id]
        if( cached_range != nil && messages.count > 0 && cached_range!.contains(range: dateLimit) ) {
            return completion(messages, cached_range!)
        }
        db_model.getMessagesForThread(threadId: thread.id, dateLimit: (min: dateLimit.min, max: dateLimit.max), completion: { (messages) -> Void in
            let included = self.memory_model.update(threadId: thread.id, messages: messages, range: dateLimit)
            completion(included, dateLimit)
        })
    }
    
    func getMessageStartingThread(conversationThread: ConversationThread, completion: @escaping (Message) -> ()) {
        if( conversationThread.createdFromMessage_id == nil ) {
            return
        }
        if( memory_model.messages != nil ) {
            let index = memory_model.messages!.index(where: { (m) -> Bool in m.id == conversationThread.createdFromMessage_id! })
            if( index != nil ) {
                completion( memory_model.messages![index!] )
                return
            }
        }
        db_model.getMessageStartingThread(conversationThread: conversationThread, completion: completion)
    }
    
    func getMessageLargeImage(message: Message, completion: @escaping () -> ()) {
        db_model.getMessageLargeImage(message: message, completion: completion)
    }
    
    func enterBackgroundMode() {
        // Empty cache that is relied upon as the application will not be notified of any new changes.
        memory_model.messages = nil
        memory_model.messageDateRanges.removeAll()
        memory_model.conversations = nil
        memory_model.groups = nil
        memory_model.group_activities = nil
        memory_model.messageRecords = nil
    }
    
    func setMessageFetchTimeLimit(numberOfDays: TimeInterval) {
        db_model.setMessageFetchTimeLimit(numberOfDays: numberOfDays)
        memory_model.messages = nil
        memory_model.conversations = nil
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
            if( f.group.id == group.id ) {
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
    
    func saveUser(user: User, completion: @escaping (_ status: Bool)-> ()) {
        db_model.saveUser(user: user, completion: completion)
        memory_model.update(user: user)
    }
    
    func saveUserInvitation(userInvitation: UserInvitation) {
        db_model.saveUserInvitation(userInvitation: userInvitation)
    }
    
    func saveGroup(group: Group) {
        db_model.saveGroup(group: group)
        
        for mv in views {
            if( mv.notify_new_group != nil ) {
                mv.notify_new_group!(group)
            }
        }
    }
    
    func saveMessage(message: Message, completion: @escaping () -> ()) {
        db_model.saveMessage(message: message, completion: completion)
        
        for mv in views {
            if( mv.notify_new_message != nil ) {
                mv.notify_new_message!(message)
            }
        }
    }
    
    // Function called when another user added me to a new group.
    func addMeToGroup(group: Group) {
        memory_model.update(group: group, user: model.me())
        
        for view in views {
            if( view.notify_new_group != nil ) {
                view.notify_new_group!(group)
            }
        }
    }
    
    func addUserToGroup(group: Group, user: User) {
        db_model.addUserToGroup(group: group, user: user, by: me())
        memory_model.groupUserFolder.append((group: group, user: user))
        
        for mv in views {
            if( mv.notify_edit_group != nil ) {
                mv.notify_edit_group!(group, user)
            }
        }
    }
    
    func addUserToFriend(user: User) {
        db_model.addUserToFriends(user: me(), friend: user)
    }
    
    func saveConversationThread(conversationThread: ConversationThread) {
        let oldConv = conversationThread.id is CloudRecordId
        
        db_model.saveConversationThread(conversationThread: conversationThread)
        
        if( oldConv == false ) {
           for mv in views {
               if( mv.notify_new_conversation != nil ) {
                   mv.notify_new_conversation!(conversationThread)
               }
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
            db_model.setupNotifications(cthread: cthread, groupId: cthread.group_id)
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
    
    func setupNotificationsForMessageRecord(messageId: RecordId, view: ModelView) {
        if( view.notify_new_message_record != nil || view.notify_edit_message_record != nil ) {
            uniquely_append(view)
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
    
    func getDecorationThemes(category: String) -> [DecorationTheme] {
        return memory_model.decorationThemes.filter({ (dt) -> Bool in
            return dt.category == category
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
    
    func addDecoration(theme: String, category: String, stamps: [String], options: NSDictionary? = nil) {
        if( memory_model.decorationThemes.contains(where: { (dt) -> Bool in
            return dt.name == theme
        }) ) {
            return
        }
        
        let theme = DecorationTheme(name: theme)
        theme.category = category
        theme.options = options
        memory_model.decorationThemes.append(theme)
        for s in stamps {
           let image = UIImage(named: s)
           if( image != nil ) {
               let stamp = DecorationStamp(theme: theme.id, image: image!)
               memory_model.decorationStamps.append(stamp)
            }
        }
    }
    
    /******************************************************************/
    func deleteGroup(group: Group) {
        if( memory_model.groups != nil ) {
            let index = memory_model.groups!.index(where: { (gr) -> Bool in
                gr.id == group.id
            })
            if( index != nil ) {
                memory_model.groups!.remove(at: index!)
            }
        }
        db_model.deleteGroup(group: group, completion: {})
    }
    
    func deleteConversationThread(conversationThread: ConversationThread) {
        if( memory_model.conversations != nil ) {
            let index = memory_model.conversations!.index(where: { (cthread) -> Bool in
                cthread.id == conversationThread.id
            })
            if( index != nil ) {
                memory_model.conversations!.remove(at: index!)
            }
        }
        db_model.deleteConversation(cthread: conversationThread, messages: getMessagesForThread(thread: conversationThread), user: me(), completion: {})
    }
    
    func deleteOldStuff(numberOfDays: Int) {
        let numberOfDaysMax : TimeInterval = TimeInterval(numberOfDays)
        let secondsInADay : TimeInterval = 24*60*60
        let date = Date(timeInterval: -numberOfDaysMax*secondsInADay, since: Date())

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 10, execute: {
            self.db_model.deleteOldMessages(olderThan: date, user: self.me(), completion: {
                self.db_model.deleteOldConversationThread(olderThan: date, user: self.me(), completion: {
                    self.db_model.deleteIrrelevantInvitations(olderThan: date, user: self.me(), completion: {
                        self.db_model.deleteOldMessageRecords(olderThan: date, user: self.me(), completion: {})
                    })
                })
            })
        })

    }
    
    /*******************************************************************/
    
    private func getMessageRecordsForMessage(message: Message) -> [MessageRecord] {
        if( memory_model.messageRecords != nil ) {
            return memory_model.messageRecords!.filter( { (r) -> Bool in
                return r.message_id == message.id
            })
        } else {
            return [MessageRecord]()
        }
    }
    
    func saveReadMessageRecord(messageRecord: MessageRecord) {
        self.memory_model.updateMessageRecords(messageRecords: [messageRecord])
        
        db_model.saveMessageRecord(messageRecord: messageRecord)
    }
    
    func getPollVotes(poll: Message, completion: @escaping ([PollRecord]) -> Void ) {
        // Convert generic MessageRecords into PollRecords.
        func convert(messageRecords: [MessageRecord]) -> [PollRecord] {
            var pollRecords = [PollRecord]()
            for mr in messageRecords {
                if( mr.type == "PollRecord" ) {
                    let pollRecord = PollRecord(record: mr)
                    pollRecords.append(pollRecord)
                }
            }
            return pollRecords
        }
        db_model.getMessageRecords(message: poll, type: "PollRecord", completion: { (messageRecords) -> Void in
            self.memory_model.updateMessageRecords(messageRecords: messageRecords)
            completion(convert(messageRecords: messageRecords))
        })
    }
    
    func savePollVote(pollRecord: PollRecord) {
        pollRecord.payLoad = pollRecord.getPayLoad()
        self.memory_model.updateMessageRecords(messageRecords: [pollRecord])
        
        db_model.saveMessageRecord(messageRecord: pollRecord)
    }
    
    func getExpenseItems(expense_tab: Message, completion: @escaping ([ExpenseRecord]) -> Void) {
        // Convert generic MessageRecords into ExpenseRecords.
        func convert(messageRecords: [MessageRecord]) -> [ExpenseRecord] {
            var expRecords = [ExpenseRecord]()
            for mr in messageRecords {
                if( mr.type == "ExpenseRecord" ) {
                    let expRecord = ExpenseRecord(record: mr)
                    expRecords.append(expRecord)
                }
            }
            return expRecords
        }

        db_model.getMessageRecords(message: expense_tab, type : "ExpenseRecord", completion: { (messageRecords) -> Void in
            self.memory_model.updateMessageRecords(messageRecords: messageRecords)
            completion(convert(messageRecords: messageRecords))
        })
    }
    
    func saveExpenseItem(expenseRecord: ExpenseRecord) {
        expenseRecord.payLoad = expenseRecord.getPayLoad()
        self.memory_model.updateMessageRecords(messageRecords: [expenseRecord])
        
        db_model.saveMessageRecord(messageRecord: expenseRecord)
    }
    
    func getLocationItems(
        share_location_message: Message, completion: @escaping ([LocationRecord]) -> Void
    ) {
        // Convert generic MessageRecords into ExpenseRecords.
        func convert(messageRecords: [MessageRecord]) -> [LocationRecord] {
            var expRecords = [LocationRecord]()
            for mr in messageRecords {
                if( mr.type == "LocationRecord" ) {
                    let expRecord = LocationRecord(record: mr)
                    expRecords.append(expRecord)
                }
            }
            return expRecords
        }
        
        db_model.getMessageRecords(message: share_location_message, type: "LocationRecord", completion: { (messageRecords) -> Void in
            self.memory_model.updateMessageRecords(messageRecords: messageRecords)
            var locRecords = convert(messageRecords: messageRecords)
            completion(locRecords)
            locRecords.removeAll()
        })
    }
    
    func saveLocationItem(locationRecord: LocationRecord) {
        locationRecord.payLoad = locationRecord.getPayLoad()
        self.memory_model.updateMessageRecords(messageRecords: [locationRecord])
        
        db_model.saveMessageRecord(messageRecord: locationRecord)
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
        model.saveUser(user: user1, completion: {_ in })
        model.saveUser(user: user2, completion: {_ in })
        
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
            let thread = ConversationThread(id: RecordId(), group_id: group1.id, user_id: user1.id)
            thread.title = String("Thread " + String(i))
            model.saveConversationThread(conversationThread: thread)
            
            for j in 1...i*2 {
                let message = Message(thread: thread, user: j%2 == 0 ? user1 : user2)
                message.text = "Message " + String(j)
                for _ in 1...j {
                    message.text += " of some words "
                }
                model.saveMessage(message: message, completion: {})
                
                // Simulate the fact that I read this message.
                model.updateMyActivity(thread: thread, date: message.last_modified, withNewMessage: message)
                
                Thread.sleep(forTimeInterval: 30)
            }
            
            // Test activity management
            if( i % 2 == 0 ) {
                let message = Message(thread: thread, user: user1)
                message.text = "Unread Message "
                
                thread.last_modified = message.last_modified
                
                model.saveMessage(message: message, completion: {})
            }
        }
        
        Thread.sleep(forTimeInterval: 30)
        
        let thread = ConversationThread(id: RecordId(), group_id: group2.id, user_id: model.me().id)
        thread.title = String("Main")
        model.saveConversationThread(conversationThread: thread)
        let message = Message(thread: thread, user: user1)
        message.text = "Welcome to the Main conversation thread."
        model.saveMessage(message: message, completion: {})
    }
}
