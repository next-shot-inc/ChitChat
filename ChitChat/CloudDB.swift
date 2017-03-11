//
//  CloudDB.swift
//  ChitChat
//
//  Created by next-shot on 3/9/17.
//  Copyright © 2017 next-shot. All rights reserved.
//

import Foundation
import CloudKit
import UIKit

class CloudRecordId : RecordId {
    let record: CKRecord
    
    init(record: CKRecord) {
        self.record = record
        super.init(string: String(record["id"] as! NSString))
    }
    init(record: CKRecord, id: String) {
        self.record = record
        super.init(string: id)
    }
}

extension RecordId {
    convenience init(record: CKRecord, forKey: String) {
        self.init(string: String(record.object(forKey: forKey) as! NSString))
    }
}

extension User {
    convenience init(record: CKRecord) {
        self.init(
            id: CloudRecordId(record: record),
            label : String(record["label"] as! NSString),
            phoneNumber : String(record["phoneNumber"] as! NSString)
        )
        
        let imageData = record["iconBytes"] as! NSData
        if( imageData.length != 0 ) {
            self.icon = UIImage(data: imageData as Data)!
        }
    }
    
    func fillRecord(record: CKRecord) {
        record.setObject(NSString(string: self.id.id), forKey: "id")
        record.setObject(NSString(string: self.label!), forKey: "label")
        record.setObject(NSString(string: self.phoneNumber), forKey: "phoneNumber")
        if( self.icon != nil ) {
            record.setObject(NSData(data: UIImageJPEGRepresentation(self.icon!, 1.0)!), forKey: "iconBytes")
        } else {
            record.setObject(NSData(), forKey: "iconBytes")
        }
    }
}

class UserQueryResults {
    var users = [User]()
    
    func done() { }
    
    func queryCompletionHandler(records: [CKRecord]?, error: Error?) {
        if( error != nil ) {
            print(error!)
        } else {
            for r in records! {
                let user = User(record: r)
                users.append(user)
            }
        }
        done()
    }
}

extension Group {
    convenience init(record: CKRecord) {
        self.init(
            id: CloudRecordId(record: record),
            name : String(record["name"] as! NSString)
        )
        let imageData = record["iconBytes"] as! NSData
        if( imageData.length != 0 ) {
            self.icon = UIImage(data: imageData as Data)!
        }
    }
    
    func fillRecord(record: CKRecord) {
        record.setObject(NSString(string: self.id.id), forKey: "id")
        record.setObject(NSString(string: self.name), forKey: "name")
        if( self.icon != nil ) {
            record.setObject(NSData(data: UIImageJPEGRepresentation(self.icon!, 1.0)!), forKey: "iconBytes")
        } else {
            record.setObject(NSData(), forKey: "iconBytes")
        }
    }
}

extension ConversationThread {
    convenience init(record: CKRecord) {
        self.init(
            id: CloudRecordId(record: record),
            group_id: RecordId(record: record, forKey: "group_id")
        )
        self.title = String(record["title"] as! NSString)
        self.last_modified = Date(timeIntervalSince1970: (record["last_modified"] as! NSDate).timeIntervalSince1970)
    }
    
    func fillRecord(record: CKRecord) {
        record["id"] = NSString(string: self.id.id)
        record["group_id"] = NSString(string: self.group_id.id)
        if( self.group_id is CloudRecordId ) {
            record["group_reference"] = CKReference(record: (self.group_id as! CloudRecordId).record, action: .none)
        }
        record["title"] = NSString(string: self.title)
        record["last_modified"] = NSDate(timeIntervalSince1970: self.last_modified.timeIntervalSince1970)
    }
}

extension Message {
    convenience init(record: CKRecord) {
        self.init(
            id: CloudRecordId(record: record),
            threadId: RecordId(record: record, forKey: "thread_id"),
            user_id: RecordId(record: record, forKey: "user_id")
        )
        self.text = String(record["text"] as! NSString)
        self.last_modified = Date(timeIntervalSince1970: (record["last_modified"] as! NSDate).timeIntervalSince1970)
        
        let asset = record["image"] as? CKAsset
        if( asset != nil ) {
            let imageData: Data
            do {
                imageData = try Data(contentsOf: asset!.fileURL)
                self.image = UIImage(data: imageData)
            } catch {
                
            }
        }
    }
    
    func fillRecord(record: CKRecord, assets: CloudAssets) {
        record["id"] = NSString(string: self.id.id)
        record["user_id"] = NSString(string: self.user_id.id)
        if( self.user_id is CloudRecordId ) {
            record["user_reference"] = CKReference(record: (self.user_id as! CloudRecordId).record, action: .none)
        }
        
        record["thread_id"] = NSString(string: self.conversation_id.id)
        if( self.conversation_id is CloudRecordId ) {
            record["thread_reference"] = CKReference(record: (self.conversation_id as! CloudRecordId).record, action: .none)
        }
    
        record["text"] = NSString(string: self.text)
        record["last_modified"] = NSDate(timeIntervalSince1970: self.last_modified.timeIntervalSince1970)
        
        // Image as CKAsset
        if( self.image != nil ) {
            let data = UIImageJPEGRepresentation(self.image!, 1.0)
            let url = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(NSUUID().uuidString+".dat")
            if url != nil {
                do {
                    try data!.write(to: url!, options: [.atomic])
                } catch let e as NSError {
                    print("Error! \(e)")
                }
                let asset = CKAsset(fileURL: url!)
                record["image"] = asset
                assets.urls.append(url!)
            }
        }
    }
}

extension UserActivity {
    convenience init(record: CKRecord) {
        self.init(
            user_id: RecordId(record: record, forKey: "user_id"),
            thread_id: RecordId(record: record, forKey: "thread_id")
        )
        self.last_read = Date(timeIntervalSince1970: (record["last_read"] as! NSDate).timeIntervalSince1970)
    }
    
    func fillRecord(record: CKRecord) {
        record["user_id"] = NSString(string: self.user_id.id)
        record["thread_id"] = NSString(string: self.thread_id.id)
        record["last_read"] = NSDate(timeIntervalSince1970: self.last_read.timeIntervalSince1970)
    }
}

class CloudAssets {
    var urls = [URL]()
    
    func clean() {
        for url in urls {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                
            }
        }
        urls.removeAll()
    }
    
    func saveCompletionHandler(record: CKRecord?, error: Error?) {
        if( error != nil ) {
            print(error!)
        }
        clean()
    }

}

class CloudDBModel : DBProtocol {
    // Represents the default container specified in the iCloud section of the Capabilities tab for the project.
    let container: CKContainer
    let publicDB: CKDatabase
    let privateDB: CKDatabase
    
    // MARK: - Initializers
    init() {
        container = CKContainer.default()
        publicDB = container.publicCloudDatabase
        privateDB = container.privateCloudDatabase
    }
    
    func saveUser(user: User) {
        let dbid = user.id as? CloudRecordId
        var record : CKRecord
        if( dbid == nil ) {
            record = CKRecord(recordType: "User")
            user.id = CloudRecordId(record: record, id: user.id.id)
        } else {
            record = dbid!.record
        }
        user.fillRecord(record: record)
        self.publicDB.save(record, completionHandler: self.saveCompletionHandler)
    }
    
    func saveMessage(message: Message) {
        let dbid = message.id as? CloudRecordId
        var record : CKRecord
        if( dbid == nil ) {
            record = CKRecord(recordType: "Message")
            message.id = CloudRecordId(record: record, id: message.id.id)
        } else {
            record = dbid!.record
        }
        
        let assets = CloudAssets()
        message.fillRecord(record: record, assets: assets)
        self.publicDB.save(record, completionHandler: assets.saveCompletionHandler)
    }
    
    func saveGroup(group: Group) {
        let dbid = group.id as? CloudRecordId
        var record : CKRecord
        if( dbid == nil ) {
            record = CKRecord(recordType: "Group")
            group.id = CloudRecordId(record: record, id: group.id.id)
        } else {
            record = dbid!.record
        }
        
        group.fillRecord(record: record)
        self.publicDB.save(record, completionHandler: self.saveCompletionHandler)
    }
    
    func addUserToGroup(group: Group, user: User) {
        let record = CKRecord(recordType: "GroupUserFolder")
        record["group_id"] = NSString(string: group.id.id)
        record["user_id"] = NSString(string: user.id.id)
        let gdbid = group.id as? CloudRecordId
        if( gdbid != nil ) {
            record["group_reference"] = CKReference(record: gdbid!.record, action: .none)
        }
        let udbid = user.id as? CloudRecordId
        if( udbid != nil ) {
            record["user_reference"] = CKReference(record: udbid!.record, action: .none)
        }
        self.publicDB.save(record, completionHandler: self.saveCompletionHandler)
    }
    
    func saveConversationThread(conversationThread: ConversationThread) {
        let dbid = conversationThread.id as? CloudRecordId
        var record : CKRecord
        if( dbid == nil ) {
            record = CKRecord(recordType: "ConversationThread")
            conversationThread.id = CloudRecordId(record: record, id: conversationThread.id.id)
        } else {
            record = dbid!.record
        }
        
        conversationThread.fillRecord(record: record)
        self.publicDB.save(record, completionHandler: self.saveCompletionHandler)
    }
    
    func saveActivity(activity: UserActivity) {
        let dbid = activity.id as? CloudRecordId
        var record : CKRecord
        if( dbid == nil ) {
            record = CKRecord(recordType: "UserActivity")
            activity.id = CloudRecordId(record: record, id: activity.id.id)
        } else {
            record = dbid!.record
        }
        
        activity.fillRecord(record: record)
        self.publicDB.save(record, completionHandler: self.saveCompletionHandler)
    }
    
    func saveCompletionHandler(record: CKRecord?, error: Error?) {
        if( error != nil ) {
            print(error!)
        }
    }
    
    /*****************************************************************************************/
    
    func getUser(userId: RecordId, completion: @escaping (User) -> ()) {
        let query = CKQuery(recordType: "User", predicate: NSPredicate(format: String("user_id = %@"), argumentArray: [userId.id]))
        publicDB.perform(query, inZoneWith: nil, completionHandler: { results, error -> Void in
            if results!.count > 0 {
                let record = results![0]
                let user = User(record: record)
                completion(user)
            }
        })
    }
    
    func getUser(phoneNumber: String, completion: @escaping (User?) -> Void) {
        let query = CKQuery(recordType: "User", predicate: NSPredicate(format: String("phoneNumber = %@"), argumentArray: [phoneNumber]))
        publicDB.perform(query, inZoneWith: nil, completionHandler: { results, error -> Void in
            if results!.count > 0 {
                let record = results![0]
                let user = User(record: record)
                completion(user)
            } else {
                completion(nil)
            }
        })
    }
    
    func getGroupsForUser(userId: RecordId, completion: @escaping ([Group]) -> ()) {
        let query = CKQuery(recordType: "GroupUserFolder", predicate: NSPredicate(format: String("user_id = %@"), argumentArray: [userId.id]))
        publicDB.perform(query, inZoneWith: nil, completionHandler: { results, error -> Void in
            if results != nil && results!.count > 0 {
                var gr_rids = [CKRecordID]()
                for r in results! {
                    let gr_ref = r["group_reference"] as! CKReference
                    gr_rids.append(gr_ref.recordID)
                }
                
                let fetchOp = CKFetchRecordsOperation(recordIDs: gr_rids)
                fetchOp.database = self.publicDB
                fetchOp.fetchRecordsCompletionBlock = ({ recordsTable , error -> Void in
                    if( recordsTable == nil ) {
                        return
                    }
                    var groups = [Group]()
                    for gr_id in gr_rids {
                        let record = recordsTable![gr_id]
                        if( record != nil ) {
                           let group = Group(record: record!)
                           groups.append(group)
                        }
                    }
                    completion(groups)
                })
                fetchOp.start()
                
            } else {
                completion([])
            }
        })
    }
    
    func getUsersForGroup(groupId: RecordId, completion: @escaping ([User]) -> ()) {
        let query = CKQuery(recordType: "GroupUserFolder", predicate: NSPredicate(format: String("group_id = %@"), argumentArray: [groupId.id]))
        publicDB.perform(query, inZoneWith: nil, completionHandler: { results, error -> Void in
            if results != nil && results!.count > 0 {
                var ur_rids = [CKRecordID]()
                for r in results! {
                    let ur_ref = r["user_reference"] as! CKReference
                    ur_rids.append(ur_ref.recordID)
                }
                
                let fetchOp = CKFetchRecordsOperation(recordIDs: ur_rids)
                fetchOp.database = self.publicDB
                fetchOp.fetchRecordsCompletionBlock = ({ recordsTable , error -> Void in
                    if( recordsTable == nil ) {
                        return
                    }
                    var users = [User]()
                    for ur_id in ur_rids {
                        let record = recordsTable![ur_id]
                        if( record != nil ) {
                            let user = User(record: record!)
                            users.append(user)
                        }
                    }
                    completion(users)
                })
                fetchOp.start()
                
            } else {
                completion([])
            }
        })

    }

    func getThreadsForGroup(groupId: RecordId, completion: @escaping ([ConversationThread]) -> ()) {
        let query = CKQuery(recordType: "ConversationThread", predicate: NSPredicate(format: String("group_id = %@"), argumentArray: [groupId.id]))
        publicDB.perform(query, inZoneWith: nil, completionHandler: { results, error -> Void in
            if results != nil && results!.count > 0 {
                var conversationThreads = [ConversationThread]()
                for r in results! {
                   let cthread = ConversationThread(record: r)
                    conversationThreads.append(cthread)
                }
                completion(conversationThreads)
            }
        })
    }
    
    func getThread(threadId: RecordId, completion: @escaping (ConversationThread?) -> ()) {
        let query = CKQuery(recordType: "ConversationThread", predicate: NSPredicate(format: String("id = %@"), argumentArray: [threadId.id]))
        publicDB.perform(query, inZoneWith: nil, completionHandler: { results, error -> Void in
            if results != nil && results!.count > 0 {
                let cthread = ConversationThread(record: results![0])
                completion(cthread)
            }
        })
    }

    func getMessagesForThread(threadId: RecordId, completion: @escaping ([Message]) -> ()) {
        let query = CKQuery(recordType: "Message", predicate: NSPredicate(format: String("thread_id = %@"), argumentArray: [threadId.id]))
        publicDB.perform(query, inZoneWith: nil, completionHandler: { results, error -> Void in
            var messages = [Message]()
            if( results != nil ) {
                for r in results! {
                    let message = Message(record: r)
                    messages.append(message)
                }
                completion(messages)
            }
        })
    }
    
    func getActivity(userId: RecordId, threadId: RecordId, completion: @escaping (UserActivity?) -> ()) {
        let query = CKQuery(recordType: "UserActivity", predicate: NSPredicate(format: String("(thread_id = %@) AND (user_id = %@)"), argumentArray: [threadId.id, userId.id]))
        publicDB.perform(query, inZoneWith: nil, completionHandler: { results, error -> Void in
            if results != nil && results!.count > 0 {
                let record = results![0]
                let usera = UserActivity(record: record)
                completion(usera)
            } else {
                completion(nil)
            }
        })
    }
    
    func getActivities(userId: RecordId, completion: @escaping ([UserActivity]) -> ()) {
        let query = CKQuery(recordType: "UserActivity", predicate: NSPredicate(format: String("user_id = %@"), argumentArray: [userId.id]))
        publicDB.perform(query, inZoneWith: nil, completionHandler: { results, error -> Void in
            if results != nil {
                var user_acs = [UserActivity]()
                for record in results! {
                    let usera = UserActivity(record: record)
                    user_acs.append(usera)
                }
                completion(user_acs)
            }
        })

    }
    
    class DeleteCompletionConfirmation {
        let types = ["User", "Group", "Message", "UserActivity", "ConversationThread", "GroupUserFolder"]
        var done = [String:Bool]()
        let fullCompletion : () -> Void
        
        init(full: @escaping ()-> Void) {
            self.fullCompletion = full
            for type in types {
                done[type] = false
            }
        }
        func completion(type: String) {
            done[type] = true
            var allDone = true
            for d in done.values {
                if( !d ) {
                    allDone = false
                    break
                }
            }
            if( allDone ) {
                fullCompletion()
            }
        }
    }
    
    func deleteAllRecords(completion: @escaping () -> Void){
        let complete = DeleteCompletionConfirmation(full: completion)
        for type in complete.types {
            deleteAllRecords(recordType: type, completion: complete.completion)
        }
    }
    
    func deleteAllRecords(recordType: String, completion: @escaping (String) -> ()) {
    
        // fetch records from iCloud, get their recordID and then delete them
        
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(format: "TRUEPREDICATE", argumentArray: nil))
        publicDB.perform(query, inZoneWith: nil, completionHandler: { (records, error) in
            var recordIDsArray: [CKRecordID] = []
            for record in records! {
                recordIDsArray.append(record.recordID)
            }
        
            let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDsArray)
            operation.modifyRecordsCompletionBlock = {
                (savedRecords: [CKRecord]?, deletedRecordIDs: [CKRecordID]?, error: Error?) in
                 print("deleted all records of type ", recordType)
                
                completion(recordType)
            }
        
            self.publicDB.add(operation)
        })
    }

}
