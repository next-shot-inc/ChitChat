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
    var record: CKRecord
    
    init(record: CKRecord) {
        self.record = record
        super.init(string: String(record["id"] as! NSString))
    }
    init(record: CKRecord, id: String) {
        self.record = record
        super.init(string: id)
    }
}

class ReferenceCloudRecordId : RecordId {
    var recordId : CKRecordID
    init(recordId: CKRecordID, id: String) {
        self.recordId = recordId
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
        let passKeyRecord = record["passKey"] as? NSString
        if( passKeyRecord != nil ) {
            self.passKey = String(passKeyRecord!)
        }
        
        let recoveryKeyRecord = record["recoveryKey"] as? NSString
        if( recoveryKeyRecord != nil ) {
            self.recoveryKey = String(recoveryKeyRecord!)
        }
    }
    
    func fillRecord(record: CKRecord) {
        record["id"] = NSString(string: self.id.id)
        record["label"] = NSString(string: self.label!)
        record["phoneNumber"] = NSString(string: self.phoneNumber)
        if( self.icon != nil ) {
            record["iconBytes"] = NSData(data: UIImageJPEGRepresentation(self.icon!, 1.0)!)
        } else {
            record["iconBytes"] = NSData()
        }
        if( self.passKey != nil ) {
            record["passKey"] = NSString(string: self.passKey!)
        }
        if( self.recoveryKey != nil ) {
            record["recoveryKey"] = NSString(string: self.recoveryKey!)
        }
    }
}

extension UserInvitation {
    convenience init(record: CKRecord) {
        self.init(
            id: CloudRecordId(record: record),
            from_user_id : RecordId(record: record, forKey: "from_user_id"),
            to_group_id: RecordId(record: record, forKey: "to_group_id"),
            to_user : String(record["to_user"] as! NSString)
        )
        self.date_created = Date(
            timeIntervalSince1970: (record["date_created"] as! NSDate).timeIntervalSince1970
        )
        self.accepted = (record["accepted"] as! NSNumber) as! Bool
    }
    
    func fillRecord(record: CKRecord) {
        record["id"] = NSString(string: self.id.id)
        record["from_user_id"] = NSString(string: self.from_user_id.id)
        record["to_group_id"] = NSString(string: self.to_group_id.id)
        record["to_user"] = NSString(string: self.to_user)
        let gdbid = to_group_id as? CloudRecordId
        if( gdbid != nil ) {
            record["to_group_reference"] = CKReference(record: gdbid!.record, action: .none)
        }
        record["date_created"] = NSDate(timeIntervalSince1970: self.date_created.timeIntervalSince1970)
        record["accepted"] = NSNumber(booleanLiteral: self.accepted)
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
        details = String(record["details"] as! NSString)
        
        let act_ref = record["activity_reference"] as? CKReference
        if( act_ref == nil ) {
            activity_id = RecordId(record: record, forKey: "activity_id")
        } else {
            let id = String(record["activity_id"] as! NSString)
            activity_id = CloudRecordId(record: CKRecord(recordType: "GroupActivity", recordID: act_ref!.recordID), id: id)
        }
    }
    
    func fillRecord(record: CKRecord) {
        record["id"] = NSString(string: self.id.id)
        record["name"] = NSString(string: self.name)
        if( self.icon != nil ) {
            record.setObject(NSData(data: UIImageJPEGRepresentation(self.icon!, 1.0)!), forKey: "iconBytes")
        } else {
            record.setObject(NSData(), forKey: "iconBytes")
        }
        record["details"] = NSString(string: self.details)
        
        record["activity_id"] = NSString(string: self.activity_id.id)
        if( self.activity_id is CloudRecordId ) {
            record["activity_reference"] = CKReference(record: (self.activity_id as! CloudRecordId).record, action: .none)
        }

    }
}

extension GroupActivity {
    convenience init(record: CKRecord) {
        self.init(
            id: CloudRecordId(record: record),
            group_id: RecordId(record: record, forKey: "group_id")
        )
        
        self.last_modified = Date(
            timeIntervalSince1970: (record["last_modified"] as! NSDate).timeIntervalSince1970
        )

        // Special handling of lastly added records
        let lu_record = record["last_user_id"]
        if( lu_record != nil ) {
            last_userId = RecordId(record: record, forKey: "last_user_id")
        }
        let lm_record = record["last_message"]
        if( lm_record != nil ) {
            last_message = String(lm_record as! NSString)
        }
    }
    
    func fillRecord(record: CKRecord) {
        record["id"] = NSString(string: self.id.id)
        record["group_id"] = NSString(string: self.group_id.id)

        record["last_modified"] = NSDate(timeIntervalSince1970: self.last_modified.timeIntervalSince1970)
        
        if( last_userId != nil ) {
            record["last_user_id"] = NSString(string: self.last_userId!.id)
        }
        record["last_message"] = NSString(string: self.last_message)
    }
}

extension ConversationThread {
    convenience init(record: CKRecord, createdByUser: Bool) {
        let gr_ref = record["group_reference"] as? CKReference
        let group_id : RecordId
        if( gr_ref == nil ) {
            group_id = RecordId(record: record, forKey: "group_id")
        } else {
            let id = String(record["group_id"] as! NSString)
            group_id = ReferenceCloudRecordId(recordId: gr_ref!.recordID, id: id)
        }
        let raw_user_id = record["user_id"] as? NSString
        var user_id : RecordId?
        if( user_id == nil && createdByUser ) {
            user_id = model.me().id
        } else if( raw_user_id != nil ) {
            user_id = RecordId(string: String(raw_user_id!))
        }
        
        self.init(
            id: CloudRecordId(record: record),
            group_id: group_id,
            user_id: user_id
        )
        self.title = String(record["title"] as! NSString)
        self.last_modified = Date(timeIntervalSince1970: (record["last_modified"] as! NSDate).timeIntervalSince1970)
    }
    
    func fillRecord(record: CKRecord) {
        record["id"] = NSString(string: self.id.id)
        record["group_id"] = NSString(string: self.group_id.id)
        if( self.group_id is CloudRecordId ) {
            record["group_reference"] = CKReference(record: (self.group_id as! CloudRecordId).record, action: .none)
        } else if( self.group_id is ReferenceCloudRecordId ) {
            record["group_reference"] = CKReference(recordID: (self.group_id as! ReferenceCloudRecordId).recordId, action: .none)
        }
        record["title"] = NSString(string: self.title)
        record["last_modified"] = NSDate(timeIntervalSince1970: self.last_modified.timeIntervalSince1970)
        if( self.user_id != nil ) {
            record["user_id"] = NSString(string: self.user_id!.id)
        }
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
        self.fromName = String(record["fromName"] as! NSString)
        self.inThread = String(record["inThread"] as! NSString)
        
        // Special handling of lastly added records
        let opt_record = record["options"]
        if( opt_record != nil ) {
            self.options = String(opt_record as! NSString)
        }
        let group_id = record["group_id"]
        if( group_id != nil ) {
            self.group_id = RecordId(record: record, forKey: "group_id")
        }
        
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
        
        if( self.group_id != nil ) {
            record["group_id"] = NSString(string: self.group_id!.id)
        }
    
        record["text"] = NSString(string: self.text)
        record["last_modified"] = NSDate(timeIntervalSince1970: self.last_modified.timeIntervalSince1970)
        record["fromName"] = NSString(string: self.fromName)
        record["inThread"] = NSString(string: self.inThread)
        record["options"] = NSString(string: self.options)
        
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
    
    func getCreationDate() -> Date? {
        if( self.id is CloudRecordId ) {
            let record = (self.id as! CloudRecordId).record
            return record.creationDate
        }
        return nil
    }
    
    func registeredForSave() -> Bool {
        return self.id is CloudRecordId
    }
    func unsaved() -> Bool {
        if( self.id is CloudRecordId ) {
            let record = (self.id as! CloudRecordId).record
            if( record.modificationDate == nil ) {
                return true
            }
            // 10 second difference time between server and device.
            return record.modificationDate! < Date(timeInterval: -10, since: self.last_modified)
        }
        return true
    }
}

extension UserActivity {
    convenience init(record: CKRecord) {
        self.init(
            id: CloudRecordId(record: record),
            user_id: RecordId(record: record, forKey: "user_id"),
            thread_id: RecordId(record: record, forKey: "thread_id")
        )
        self.last_read = Date(timeIntervalSince1970: (record["last_read"] as! NSDate).timeIntervalSince1970)
    }
    
    func fillRecord(record: CKRecord) {
        record["id"] =  NSString(string: self.id.id)
        record["user_id"] = NSString(string: self.user_id.id)
        record["thread_id"] = NSString(string: self.thread_id.id)
        record["last_read"] = NSDate(timeIntervalSince1970: self.last_read.timeIntervalSince1970)
    }
}

extension DecorationStamp {
    convenience init(record: CKRecord) {
        let imageData = record["image"] as! NSData
        let image = UIImage(data: imageData as Data)
        let theme_ref = record["theme_reference"] as? CKReference
        let id = String(record["theme_id"] as! NSString)
        var themeId : RecordId
        if( theme_ref == nil ) {
            themeId = RecordId(string: id)
        } else {
            themeId = CloudRecordId(record: CKRecord(recordType: "DecorationTheme", recordID: theme_ref!.recordID), id: id)
        }
        self.init(
            id: CloudRecordId(record: record),
            theme : themeId, image: image!
        )
    }
    
    func fillRecord(record: CKRecord) {
        record["id"] =  NSString(string: self.id.id)
        record["image"] = NSData(data: UIImagePNGRepresentation(self.image)!)
        record["theme_id"] = NSString(string: self.theme_id.id)
        if( self.theme_id is CloudRecordId ) {
            record["theme_reference"] = CKReference(record: (self.theme_id as! CloudRecordId).record, action: .deleteSelf)
        }
    }
}

extension DecorationTheme {
    convenience init(record: CKRecord) {
        self.init(
            id: CloudRecordId(record: record),
            name:String(record["name"] as! NSString)
        )
        let sd = record["special_date"]
        if( sd != nil ) {
            self.special_date = Date(timeIntervalSince1970: (sd as! NSDate).timeIntervalSince1970)
        }
    }
    func fillRecord(record: CKRecord) {
        record["id"] =  NSString(string: self.id.id)
        record["name"] = NSString(string: self.name)
        if( self.special_date != nil ) {
            record["special_date"] = NSDate(timeIntervalSince1970: self.special_date!.timeIntervalSince1970)
        }
    }
}

extension PollRecord {
    convenience init(record: CKRecord) {
        self.init(
            id: CloudRecordId(record: record),
            user_id: RecordId(record: record, forKey: "user_id"),
            poll_id: RecordId(record: record, forKey: "poll_id"),
            checked_option: (record["checked_option"] as! NSNumber) as! Int
        )
        self.date_created = Date(timeIntervalSince1970: (record["date_created"] as! NSDate).timeIntervalSince1970)
    }
    func fillRecord(record: CKRecord) {
        record["id"] =  NSString(string: self.id.id)
        record["user_id"] = NSString(string: self.user_id.id)
        record["poll_id"] = NSString(string: self.poll_id.id)
        record["checked_option"] = NSNumber(value: self.checked_option)
        record["date_created"] = NSDate(timeIntervalSince1970: self.date_created.timeIntervalSince1970)
    }
}


class CloudAssets {
    var urls = [URL]()
    let db_model : CloudDBModel
    var completion : (() -> ())?
    
    init(db_model: CloudDBModel) {
        self.db_model = db_model
        self.completion = nil
    }
    
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
        if( completion != nil ) {
            completion!()
        }
        db_model.saveCompletionHandler(record: record, error: error)
    }

}

class CloudDBModel : DBProtocol {
    // Represents the default container specified in the iCloud section of the Capabilities tab for the project.
    let container: CKContainer
    let publicDB: CKDatabase
    let privateDB: CKDatabase
    var userRecordInfo : (ckrecord: CKRecordID, user: User)?
    var dateLimit : TimeInterval = 5
    
    // MARK: - Initializers
    init() {
        container = CKContainer.default()
        publicDB = container.publicCloudDatabase
        privateDB = container.privateCloudDatabase
        userRecordInfo = nil
    }
    
    func setMessageFetchTimeLimit(numberOfDays: TimeInterval) {
        dateLimit = numberOfDays
    }
    
    func setAsUser(user: User) {
        container.fetchUserRecordID(completionHandler: { (recordId, error) -> Void in
            if( error != nil ) {
                print(error!)
            } else if( recordId != nil ) {
                self.userRecordInfo = (recordId!, user)
            }
        })
    }
    
    func isCreatedByUser(record: RecordId) -> Bool {
        let cloudRecordId = record as? CloudRecordId
        if( cloudRecordId != nil ) {
            return isCreatedByUser(record: cloudRecordId!.record)
        }
        return false
    }
    
    func isCreatedByUser(record: CKRecord) -> Bool {
        return record.creatorUserRecordID == userRecordInfo?.ckrecord || record.creatorUserRecordID?.recordName == "__defaultOwner__"
    }
    
    // Notify (with an alert) when a new Message has been added to the thread
    // Notify when a message has been edited.
    func setupNotifications(cthread: ConversationThread) {
        
        let predicateFormat = "(thread_id == %@) AND (user_id != %@)"
        
        /*
         * Superseeded by the group based notification of new messages.
        let new_key = "new_type_Message_thread_id_\(cthread.id.id)_user_id\(model.me().id.id)"
        
        subscribe(subscriptionId: new_key, predicateFormat: predicateFormat, createSubscription: { () -> Void in
            let new_message_subscription = CKQuerySubscription(
                recordType: "Message", predicate: NSPredicate(format: predicateFormat, argumentArray: [cthread.id.id, model.me().id.id]),
                subscriptionID: new_key, options: [CKQuerySubscriptionOptions.firesOnRecordCreation]
            )
            let notificationInfo = CKNotificationInfo()
            notificationInfo.alertLocalizationKey = "New message fom %1$@ in %2$@: %3$@"
            notificationInfo.shouldBadge = true
            notificationInfo.alertLocalizationArgs = ["fromName", "inThread", "text"]
            notificationInfo.soundName = "default"
            
            new_message_subscription.notificationInfo = notificationInfo
            
            self.publicDB.save(new_message_subscription, completionHandler: { (sub, error) -> Void in
                if( error != nil ) {
                    print(error!)
                }
            })
        })
        */
        
        let edit_key = "edit_type_Message_thread_id_\(cthread.id.id)_user_id\(model.me().id.id)"
        
        subscribe(subscriptionId: edit_key, predicateFormat: predicateFormat, createSubscription: { () -> Void in
            let edit_message_subscription = CKQuerySubscription(
                recordType: "Message", predicate: NSPredicate(format: predicateFormat, argumentArray: [cthread.id.id, model.me().id.id]),
                subscriptionID: edit_key, options: [CKQuerySubscriptionOptions.firesOnRecordUpdate]
            )
            
            // If you don’t set any of the alertBody, soundName, or shouldBadge properties,
            // the push notification is sent at a lower priority that doesn’t cause the system to alert the user.
            let edit_notificationInfo = CKNotificationInfo()
            edit_notificationInfo.soundName = "default"
            edit_notificationInfo.shouldSendContentAvailable = true // To make sure it is sent
            edit_message_subscription.notificationInfo = edit_notificationInfo
            
            self.publicDB.save(edit_message_subscription, completionHandler: { (sub, error) -> Void in
                if( error != nil ) {
                    print(error!)
                }
            })
        })
    }
    
    func removeConversationThreadNotification(cthreadId: RecordId) {
        let new_key = "new_type_Message_thread_id_\(cthreadId.id)_user_id\(model.me().id.id)"
        unsubscribe(key: new_key, completionHandler: {})
        
        let edit_key = "edit_type_Message_thread_id_\(cthreadId.id)_user_id\(model.me().id.id)"
        unsubscribe(key: edit_key, completionHandler: {})
    }
    
    // Notify (with an alert) when a user has been added to a group
    func setupNotifications(userId: RecordId) {
        let predicateFormat = "user_id == %@"
        
        let new_key = "new_type_Group_user_id\(model.me().id.id)"
        
        subscribe(subscriptionId: new_key, predicateFormat: predicateFormat, createSubscription: { () -> Void in
            let new_group_subscription = CKQuerySubscription(
                recordType: "GroupUserFolder", predicate: NSPredicate(format: predicateFormat, argumentArray: [model.me().id.id]),
                subscriptionID: new_key, options: [CKQuerySubscriptionOptions.firesOnRecordCreation]
            )
            let notificationInfo = CKNotificationInfo()
            notificationInfo.alertLocalizationKey = "New group %1$@ fom %2$@"
            notificationInfo.shouldBadge = true
            notificationInfo.alertLocalizationArgs = ["groupName", "fromName"]

            notificationInfo.soundName = "default"
            notificationInfo.shouldSendContentAvailable = true // To make sure it is sent
            
            new_group_subscription.notificationInfo = notificationInfo
            
            self.publicDB.save(new_group_subscription, completionHandler: { (sub, error) -> Void in
                if( error != nil ) {
                    print(error!)
                }
            })
        })

    }
    
    // Notify when a new conversation thread is created
    // Notify when a conversation thread is deleted.
    // Notify when the group activity record is modified 
    func setupNotifications(groupId: RecordId) {
        let predicateFormat = "group_id == %@"
        
        let new_key = "new_type_ConversationThread_group_id_\(groupId.id)"
        
        subscribe(subscriptionId: new_key, predicateFormat: predicateFormat, createSubscription: { () -> Void in
            
            let new_cthread_subscription = CKQuerySubscription(
                recordType: "ConversationThread", predicate: NSPredicate(format: predicateFormat, argumentArray: [groupId.id]),
                subscriptionID: new_key, options: [CKQuerySubscriptionOptions.firesOnRecordCreation]
            )
            let notificationInfo = CKNotificationInfo()
            notificationInfo.soundName = "default"
            notificationInfo.shouldSendContentAvailable = true // To make sure it is sent
            
            new_cthread_subscription.notificationInfo = notificationInfo
            
            self.publicDB.save(new_cthread_subscription, completionHandler: { (sub, error) -> Void in
                if( error != nil ) {
                    print(error!)
                }
            })
        })
        
        let delete_key = "delete_type_ConversationThread_group_id_\(groupId.id)"
        
        subscribe(subscriptionId: delete_key, predicateFormat: predicateFormat, createSubscription: { () -> Void in
            
            let delete_cthread_subscription = CKQuerySubscription(
                recordType: "ConversationThread", predicate: NSPredicate(format: predicateFormat, argumentArray: [groupId.id]),
                subscriptionID: delete_key, options: [CKQuerySubscriptionOptions.firesOnRecordDeletion]
            )
            let notificationInfo = CKNotificationInfo()
            notificationInfo.soundName = "default"
            notificationInfo.desiredKeys = ["id"]
            notificationInfo.shouldSendContentAvailable = true // To make sure it is sent
            
            delete_cthread_subscription.notificationInfo = notificationInfo
            
            self.publicDB.save(delete_cthread_subscription, completionHandler: { (sub, error) -> Void in
                if( error != nil ) {
                    print(error!)
                }
            })
        })

        
        let edit_key = "edit_type_GroupActivity_group_id_\(groupId.id)"
        
        subscribe(subscriptionId: edit_key, predicateFormat: predicateFormat, createSubscription: { () -> Void in
            
            let edit_group_activity_subscription = CKQuerySubscription(
                recordType: "GroupActivity", predicate: NSPredicate(format: predicateFormat, argumentArray: [groupId.id]),
                subscriptionID: edit_key, options: [CKQuerySubscriptionOptions.firesOnRecordUpdate]
            )
            let notificationInfo = CKNotificationInfo()
            notificationInfo.soundName = "default"
            notificationInfo.shouldSendContentAvailable = true // To make sure it is sent
            
            edit_group_activity_subscription.notificationInfo = notificationInfo
            
            self.publicDB.save(edit_group_activity_subscription, completionHandler: { (sub, error) -> Void in
                if( error != nil ) {
                    print(error!)
                }
            })
        })

        // New Message
        let new_message_predicateFormat = "(group_id == %@) AND (user_id != %@)"
        
        let new_message_key = "new_type_Message_group_id_\(groupId.id)_user_id\(model.me().id.id)"
        
        subscribe(subscriptionId: new_message_key, predicateFormat: new_message_predicateFormat, createSubscription: { () -> Void in
            let new_message_subscription = CKQuerySubscription(
                recordType: "Message", predicate: NSPredicate(format: new_message_predicateFormat, argumentArray: [groupId.id, model.me().id.id]),
                subscriptionID: new_message_key, options: [CKQuerySubscriptionOptions.firesOnRecordCreation]
            )
            let notificationInfo = CKNotificationInfo()
            notificationInfo.alertLocalizationKey = "New message fom %1$@ in %2$@: %3$@"
            notificationInfo.shouldBadge = true
            notificationInfo.alertLocalizationArgs = ["fromName", "inThread", "text"]
            notificationInfo.soundName = "default"
            
            new_message_subscription.notificationInfo = notificationInfo
            
            self.publicDB.save(new_message_subscription, completionHandler: { (sub, error) -> Void in
                if( error != nil ) {
                    print(error!)
                }
            })
        })

    }
    
    func setupPollRecordNotifications(pollId: RecordId) {
        let predicateFormat = "poll_id == %@"
        
        let new_key = "new_type_PollRecord_poll_id_\(pollId.id)"
        
        subscribe(subscriptionId: new_key, predicateFormat: predicateFormat, createSubscription: { () -> Void in
            
            let new_pr_subscription = CKQuerySubscription(
                recordType: "PollRecord", predicate: NSPredicate(format: predicateFormat, argumentArray: [pollId.id]),
                subscriptionID: new_key, options: [CKQuerySubscriptionOptions.firesOnRecordCreation]
            )
            let notificationInfo = CKNotificationInfo()
            notificationInfo.soundName = "default"
            notificationInfo.shouldSendContentAvailable = true // To make sure it is sent
            
            new_pr_subscription.notificationInfo = notificationInfo
            
            self.publicDB.save(new_pr_subscription, completionHandler: { (sub, error) -> Void in
                if( error != nil ) {
                    print(error!)
                }
            })
        })
    }
    
    func removePollRecordNotification(pollId: RecordId) {
        let new_key = "new_type_PollRecord_poll_id_\(pollId.id)"
        unsubscribe(key: new_key, completionHandler: {})
    }

    
    // If the subscription exists and the predicate is the same, then we don't need to create this subscrioption.
    // If the predicate is different, then we first need to delete the old
    func subscribe(subscriptionId: String, predicateFormat: String, createSubscription: @escaping () -> Void) {
        publicDB.fetch(withSubscriptionID: subscriptionId, completionHandler: { (subscription, error) in
            let querySub = subscription as? CKQuerySubscription
            if querySub != nil {
                if predicateFormat != querySub!.predicate.predicateFormat {
                    self.unsubscribe(key: subscriptionId, completionHandler: createSubscription)
                }
            } else {
                createSubscription()
            }
        })
    }
    
    func unsubscribe(key: String, completionHandler: @escaping () -> Void) {
        let modifyOperation = CKModifySubscriptionsOperation()
        modifyOperation.subscriptionIDsToDelete = [key]
        modifyOperation.modifySubscriptionsCompletionBlock = { savedSubscriptions, deletedSubscriptions, error in
            completionHandler()
        }
        publicDB.add(modifyOperation)
    }
    
    func didReceiveNotification(userInfo: [AnyHashable : Any], views: [ModelView]) {
        let notification: CKNotification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        if( notification.notificationType == CKNotificationType.query ) {
            let queryNotification = notification as! CKQueryNotification
            let recordId = queryNotification.recordID
            if( recordId != nil ) {
                if( queryNotification.queryNotificationReason == .recordDeleted ) {
                    let rid = queryNotification.recordFields?["id"] as? NSString
                    if( rid != nil ) {
                        let recordId = RecordId(string: String(rid!))
                        for view in views {
                            if( view.notify_delete_conversation != nil ) {
                                view.notify_delete_conversation!(recordId)
                            }
                        }
                    }
                    return
                }
                publicDB.fetch(withRecordID: recordId!, completionHandler: { (record, error) -> Void in
                    if( record != nil ) {
                        if( record!.recordType == "Message" ) {
                            let message = Message(record: record!)
                            DispatchQueue.main.async {
                                if( queryNotification.queryNotificationReason == .recordCreated ) {
                                   for view in views {
                                      if( view.notify_new_message != nil ) {
                                          view.notify_new_message!(message)
                                      }
                                   }
                                } else {
                                    for view in views {
                                        if( view.notify_edit_message != nil ) {
                                            view.notify_edit_message!(message)
                                        }
                                    }
                                }
                            }
                        } else if( record!.recordType == "ConversationThread" ) {
                            let cthread = ConversationThread(record: record!, createdByUser: false )
                            DispatchQueue.main.async {
                                if( queryNotification.queryNotificationReason == .recordCreated ) {
                                   for view in views {
                                       if( view.notify_new_conversation != nil ) {
                                            view.notify_new_conversation!(cthread)
                                       }
                                   }
                                }
                            }
                        } else if( record!.recordType == "GroupActivity" ) {
                            let grActivity = GroupActivity(record: record!)
                            DispatchQueue.main.async {
                                if( queryNotification.queryNotificationReason == .recordUpdated ) {
                                    for view in views {
                                        if( view.notify_edit_group_activity != nil ) {
                                            view.notify_edit_group_activity!(grActivity)
                                        }
                                    }
                                }
                            }
                        } else if( record!.recordType == "GroupUserFolder" ) {
                            let group_ref = record!["group_reference"] as! CKReference
                            // Get the group newly added to the user
                            self.publicDB.fetch(withRecordID: group_ref.recordID, completionHandler: { (grp_record, error) -> Void in
                                if( grp_record != nil ) {
                                    let group = Group(record: grp_record!)
                                    DispatchQueue.main.async {
                                        if( queryNotification.queryNotificationReason == .recordCreated ) {
                                            for view in views {
                                                if( view.notify_new_group != nil ) {
                                                    view.notify_new_group!(group)
                                                }
                                            }
                                        }
                                    }
                                }
                            })

                        } else if( record!.recordType == "PollRecord" ) {
                            let pollRecord = PollRecord(record: record!)
                            DispatchQueue.main.async {
                                if( queryNotification.queryNotificationReason == .recordCreated ) {
                                    for view in views {
                                        if( view.notify_new_poll_record != nil ) {
                                            view.notify_new_poll_record!(pollRecord)
                                        }
                                    }
                                }
                            }
                        }
                    }
                })
            }
        }
    }
    
    func setAppBadgeNumber(number: Int) {
        let badgeResetOperation = CKModifyBadgeOperation(badgeValue: number)
        badgeResetOperation.modifyBadgeCompletionBlock = { (error) -> Void in
            if error != nil {
                print("Error resetting badge: \(String(describing: error!))")
            }
            else {
                UIApplication.shared.applicationIconBadgeNumber = number
            }
        }
        CKContainer.default().add(badgeResetOperation)
    }
    
    /*******************************************************************************/
    
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
    
    func saveUserInvitation(userInvitation: UserInvitation) {
        let dbid = userInvitation.id as? CloudRecordId
        var record : CKRecord
        if( dbid == nil ) {
            record = CKRecord(recordType: "UserInvitation")
            userInvitation.id = CloudRecordId(record: record, id: userInvitation.id.id)
        } else {
            record = dbid!.record
        }
        userInvitation.fillRecord(record: record)
        self.publicDB.save(record, completionHandler: self.saveCompletionHandler)
    }
    
    func saveMessage(message: Message, completion: @escaping () -> ()) {
        let dbid = message.id as? CloudRecordId
        var record : CKRecord
        if( dbid == nil ) {
            record = CKRecord(recordType: "Message")
            message.id = CloudRecordId(record: record, id: message.id.id)
        } else {
            record = dbid!.record
        }
        
        let assets = CloudAssets(db_model: self)
        message.fillRecord(record: record, assets: assets)
        assets.completion = completion
        
        self.publicDB.save(record, completionHandler: assets.saveCompletionHandler)
    }
    
    func saveGroup(group: Group) {
        let dbid = group.id as? CloudRecordId
        var record : CKRecord
        if( dbid == nil ) {
            record = CKRecord(recordType: "Group")
            group.id = CloudRecordId(record: record, id: group.id.id)
            group.fillRecord(record: record)
            self.publicDB.save(record, completionHandler: self.saveCompletionHandler)
        } else {
            record = dbid!.record
            group.fillRecord(record: record)
            
            // By default, the save operation object reports an error if a newer version of a record is found on the server.
            // Has we change only the "last-modified-date" we can safely overwrite
            let ops: CKModifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
            ops.perRecordCompletionBlock = self.saveCompletionHandler
            ops.savePolicy = CKRecordSavePolicy.changedKeys
            
            self.publicDB.add(ops)
        }
    }
    
    func addUserToGroup(group: Group, user: User, by: User) {
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
        // For notification information.
        if( by.label != nil ) {
           record["fromName"] = NSString(string: by.label!)
        }
        record["groupName"] = NSString(string: group.name)
        self.publicDB.save(record, completionHandler: self.saveCompletionHandler)
    }
    
    func saveConversationThread(conversationThread: ConversationThread) {
        let dbid = conversationThread.id as? CloudRecordId
        var record : CKRecord
        if( dbid == nil ) {
            record = CKRecord(recordType: "ConversationThread")
            conversationThread.id = CloudRecordId(record: record, id: conversationThread.id.id)
            
            conversationThread.fillRecord(record: record)
            self.publicDB.save(record, completionHandler: self.saveCompletionHandler)
        } else {
            record = dbid!.record
            conversationThread.fillRecord(record: record)
            
            // Has we change only the "last-modified-date" we can safely overwrite
            let ops: CKModifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
            ops.perRecordCompletionBlock = self.saveCompletionHandler
            ops.savePolicy = CKRecordSavePolicy.changedKeys
            
            self.publicDB.add(ops)
        }
    }
    
    func saveActivity(activity: UserActivity) {
        let dbid = activity.id as? CloudRecordId
        var record : CKRecord
        if( dbid == nil ) {
            record = CKRecord(recordType: "UserActivity")
            activity.id = CloudRecordId(record: record, id: activity.id.id)
            activity.fillRecord(record: record)
            self.publicDB.save(record, completionHandler: self.saveCompletionHandler)
        } else {
            record = dbid!.record
            activity.fillRecord(record: record)
            
            // Has we change only the "last_read" we can safely overwrite
            let ops: CKModifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
            ops.perRecordCompletionBlock = self.saveCompletionHandler
            ops.savePolicy = CKRecordSavePolicy.changedKeys
            
            self.publicDB.add(ops)
        }
    }
    
    func saveActivity(activity: GroupActivity) {
        let dbid = activity.id as? CloudRecordId
        var record : CKRecord
        if( dbid == nil ) {
            record = CKRecord(recordType: "GroupActivity")
            activity.id = CloudRecordId(record: record, id: activity.id.id)
            activity.fillRecord(record: record)
            self.publicDB.save(record, completionHandler: self.saveCompletionHandler)
        } else {
            record = dbid!.record
            activity.fillRecord(record: record)
            
            // Has we should be up-to-date we can safely overwrite
            let ops: CKModifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
            ops.perRecordCompletionBlock = self.saveCompletionHandler
            ops.savePolicy = CKRecordSavePolicy.changedKeys
            
            self.publicDB.add(ops)
        }
    }
    
    func saveDecorationThemes(themes: [DecorationTheme]) {
        var records = [CKRecord]()
        for theme in themes {
            let dbid = theme.id as? CloudRecordId
            var record : CKRecord
            if( dbid == nil ) {
                record = CKRecord(recordType: "DecorationTheme")
                theme.id = CloudRecordId(record: record, id: theme.id.id)
            } else {
                record = dbid!.record
            }
            theme.fillRecord(record: record)
            records.append(record)
        }
        
        // Has we should be up-to-date we can safely overwrite
        let ops: CKModifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        ops.perRecordCompletionBlock = self.saveCompletionHandler
        ops.savePolicy = CKRecordSavePolicy.changedKeys
        
        self.publicDB.add(ops)
    }
    
    func saveDecorationStamps(stamps: [DecorationStamp]) {
        var records = [CKRecord]()
        for stamp in stamps {
            let dbid = stamp.id as? CloudRecordId
            var record : CKRecord
            if( dbid == nil ) {
                record = CKRecord(recordType: "DecorationStamp")
                stamp.id = CloudRecordId(record: record, id: stamp.id.id)
            } else {
                record = dbid!.record
            }
            
            stamp.fillRecord(record: record)
            records.append(record)
        }
        
        // Has we should be up-to-date we can safely overwrite
        let ops: CKModifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        ops.perRecordCompletionBlock = self.saveCompletionHandler
        ops.savePolicy = CKRecordSavePolicy.changedKeys
        
        self.publicDB.add(ops)
    }

    func savePollVote(pollRecord: PollRecord) {
        let dbid = pollRecord.id as? CloudRecordId
        var record : CKRecord
        if( dbid == nil ) {
            record = CKRecord(recordType: "PollRecord")
            pollRecord.id = CloudRecordId(record: record, id: pollRecord.id.id)
        } else {
            record = dbid!.record
        }
        pollRecord.fillRecord(record: record)
        
        self.publicDB.save(record, completionHandler: self.saveCompletionHandler)
    }
    
    func saveCompletionHandler(record: CKRecord?, error: Error?) {
        if( error != nil ) {
            if( record != nil ) {
                print(record!)
            }
            print(error!)
            
            // Or if there is a retry delay specified in the error, then use that.
            if let userInfo = error?._userInfo as? NSDictionary {
                if let retry = userInfo[CKErrorRetryAfterKey] as? NSNumber {
                    let seconds = Double(retry)
                    print("Debug: Should retry in \(seconds) seconds. \(String(describing: error!))")
                }
            }
        }
    }
    
    /*****************************************************************************************/
    
    func getUser(userId: RecordId, completion: @escaping (User) -> ()) {
        let query = CKQuery(recordType: "User", predicate: NSPredicate(format: String("user_id = %@"), argumentArray: [userId.id]))
        publicDB.perform(query, inZoneWith: nil, completionHandler: { results, error -> Void in
            
            self.getCompletionHandler(error: error)
            
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
            if( error != nil ) {
                self.getCompletionHandler(error: error)
            } else if( results != nil ) {
                if results!.count > 0 {
                    let record = results![0]
                    let user = User(record: record)
                    completion(user)
                } else {
                    self.getCompletionHandler(error: error)
                    completion(nil)
                }
            }
        })
    }
    
    func getUserInvitations(to_user: String, completion: @escaping ([UserInvitation], [Group]) -> ()) {
        let query = CKQuery(recordType: "UserInvitation", predicate: NSPredicate(
            format: String("(to_user = %@) AND (accepted == 0)"), argumentArray: [to_user])
        )
        publicDB.perform(query, inZoneWith: nil, completionHandler: { results, error -> Void in
            if( error != nil ) {
                self.getCompletionHandler(error: error)
            }
            
            if( results != nil ) {
                var invitations = [UserInvitation]()
                var gr_rids = [CKRecordID]()
                for r in results! {
                    let invitation = UserInvitation(record: r)
                    invitations.append(invitation)
                    let gr_ref = r["to_group_reference"] as! CKReference
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
                    completion(invitations, groups)
                })
                fetchOp.start()
            } else {
                completion([], [])
            }
        })
    }
    
    func getGroupsForUser(userId: RecordId, completion: @escaping ([Group]) -> ()) {
        let query = CKQuery(recordType: "GroupUserFolder", predicate: NSPredicate(format: String("user_id = %@"), argumentArray: [userId.id]))
        publicDB.perform(query, inZoneWith: nil, completionHandler: { results, error -> Void in
            self.getCompletionHandler(error: error)
            
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
    
    func getActivitiesForGroups(groups: [Group], completion: @escaping (([GroupActivity]) -> Void )) {
        var ac_rids = [CKRecordID]()
        for g in groups {
            let activity_id = g.activity_id
            if( activity_id is CloudRecordId ) {
                let act_ref = (activity_id as! CloudRecordId).record
                ac_rids.append(act_ref.recordID)
            }
        }
        
        let fetchActivitiesOp = CKFetchRecordsOperation(recordIDs: ac_rids)
        fetchActivitiesOp.database = self.publicDB
        fetchActivitiesOp.fetchRecordsCompletionBlock = ({ recordsTable , error -> Void in
            if( recordsTable == nil ) {
                return
            }
            var groupActivities = [GroupActivity]()
            for ac_id in ac_rids {
                let record = recordsTable![ac_id]
                if( record != nil ) {
                    let ga = GroupActivity(record: record!)
                    groupActivities.append(ga)
                }
            }
            completion(groupActivities)
        })
        fetchActivitiesOp.start()
    }
    
    func getUsersForGroup(groupId: RecordId, completion: @escaping ([User]) -> ()) {
        let query = CKQuery(recordType: "GroupUserFolder", predicate: NSPredicate(format: String("group_id = %@"), argumentArray: [groupId.id]))
        publicDB.perform(query, inZoneWith: nil, completionHandler: { results, error -> Void in
            
            self.getCompletionHandler(error: error)
            
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
    
    func getActivityForGroup(groupId: RecordId, completion: @escaping (GroupActivity?) -> ()) {
        let query = CKQuery(recordType: "GroupActivity", predicate: NSPredicate(format: String("group_id = %@"), argumentArray: [groupId.id]))
        publicDB.perform(query, inZoneWith: nil, completionHandler: { results, error -> Void in
            self.getCompletionHandler(error: error)
            
            if results != nil && results!.count > 0 {
                let activity = GroupActivity(record: results![0])
                completion(activity)
            } else {
                completion(nil)
            }
        })
    }

    func getThreadsForGroup(groupId: RecordId, completion: @escaping ([ConversationThread]) -> ()) {
        let numberOfDaysMax = self.dateLimit
        let secondsInADay : TimeInterval = 24*60*60
        let date = Date(timeInterval: -numberOfDaysMax*secondsInADay, since: Date())
        
        let query = CKQuery(recordType: "ConversationThread", predicate: NSPredicate(format: String("(group_id = %@) AND (last_modified > %@)"), argumentArray: [groupId.id, date]))
        query.sortDescriptors = [NSSortDescriptor(key: "last_modified", ascending: false)]
        publicDB.perform(query, inZoneWith: nil, completionHandler: { results, error -> Void in
            self.getCompletionHandler(error: error)
            if results != nil && results!.count > 0 {
                var conversationThreads = [ConversationThread]()
                for r in results! {
                    let co = self.isCreatedByUser(record: r)
                    let cthread = ConversationThread(record: r, createdByUser: co)
                    conversationThreads.append(cthread)
                }
                completion(conversationThreads)
            }
        })
    }
    
    func getThread(threadId: RecordId, completion: @escaping (ConversationThread?) -> ()) {
        let query = CKQuery(recordType: "ConversationThread", predicate: NSPredicate(format: String("id = %@"), argumentArray: [threadId.id]))
        publicDB.perform(query, inZoneWith: nil, completionHandler: { results, error -> Void in
            if( error != nil ) {
                self.getCompletionHandler(error: error)
            }
            if results != nil && results!.count > 0 {
                let co = self.isCreatedByUser(record: results![0])
                let cthread = ConversationThread(record: results![0], createdByUser: co)
                completion(cthread)
            }
        })
    }

    func getMessagesForThread(threadId: RecordId, completion: @escaping ([Message]) -> ()) {
        let numberOfDaysMax = self.dateLimit
        let secondsInADay : TimeInterval = 24*60*60
        let date = Date(timeInterval: -numberOfDaysMax*secondsInADay, since: Date())
        let query = CKQuery(recordType: "Message", predicate: NSPredicate(format: String("(thread_id = %@) AND (last_modified > %@)"), argumentArray: [threadId.id, date]))
        query.sortDescriptors = [NSSortDescriptor(key: "last_modified", ascending: true)]
        publicDB.perform(query, inZoneWith: nil, completionHandler: { results, error -> Void in
            self.getCompletionHandler(error: error)
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
            self.getCompletionHandler(error: error)
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
            self.getCompletionHandler(error: error)
            
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
    
    func getDecorationStamps(theme: DecorationTheme, completion: @escaping ([DecorationStamp]) -> ()) {
        let query = CKQuery(recordType: "DecorationStamp", predicate: NSPredicate(format: "theme_id = %@", argumentArray: [theme.id.id]))
        publicDB.perform(query, inZoneWith: nil, completionHandler: { results, error -> Void in
            self.getCompletionHandler(error: error)
            
            if results != nil {
                var stamps = [DecorationStamp]()
                for record in results! {
                    let stamp = DecorationStamp(record: record)
                    stamps.append(stamp)
                }
                completion(stamps)
            }
            
        })

    }
    
    func getDecorationThemes(completion: @escaping ([DecorationTheme]) -> ()) {
        let query = CKQuery(recordType: "DecorationTheme", predicate: NSPredicate(format: "TRUEPREDICATE", argumentArray: nil))
        publicDB.perform(query, inZoneWith: nil, completionHandler: { results, error -> Void in
            if results!.count > 0 {
                var themes = [DecorationTheme]()
                for record in results! {
                    let theme = DecorationTheme(record: record)
                    themes.append(theme)
                }
                completion(themes)
            } else {
                self.getCompletionHandler(error: error)
            }
        })
    }
    
    func getPollVotes(poll: Message, completion: @escaping ([PollRecord]) -> Void ) {
        let query = CKQuery(recordType: "PollRecord", predicate: NSPredicate(format: "poll_id = %@", argumentArray: [poll.id.id]))
        publicDB.perform(query, inZoneWith: nil, completionHandler: { results, error -> Void in
            var votes = [PollRecord]()
            if results!.count > 0 {
                for record in results! {
                    let pollRecord = PollRecord(record: record)
                    votes.append(pollRecord)
                }
                completion(votes)
            } else {
                completion(votes)
                self.getCompletionHandler(error: error)
            }
        })
    }

    // Generic function to handles "fetch" request errors.
    func getCompletionHandler(error: Error?) {
        if( error != nil ) {
            print(error!)
            
            // Or if there is a retry delay specified in the error, then use that.
            if let userInfo = error?._userInfo as? NSDictionary {
                if let retry = userInfo[CKErrorRetryAfterKey] as? NSNumber {
                    let seconds = Double(retry)
                    print("Debug: Should retry in \(seconds) seconds. \(error!)")
                }
            }
        }
    }

    
    /******************************************************************************************************/
    
    func deleteConversation(cthread: ConversationThread, messages: [Message], user: User, completion: @escaping () -> ()) {
        let cloudRecordId = cthread.id as? CloudRecordId
        if( cloudRecordId == nil ) {
            return
        }
        
        var recordIDsArray: [CKRecordID] = [cloudRecordId!.record.recordID]
        for message in messages {
            if( message.user_id == user.id ) {
                let messageRecordId = message.id as? CloudRecordId
                if( messageRecordId != nil ) {
                    recordIDsArray.append(messageRecordId!.record.recordID)
                }
            }
        }
        
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDsArray)
        operation.modifyRecordsCompletionBlock = {
            (savedRecords: [CKRecord]?, deletedRecordIDs: [CKRecordID]?, error: Error?) in
            
            print("delete conversation ", cthread.title)
            
            completion()
        }
        
        self.publicDB.add(operation)
        
        removeConversationThreadNotification(cthreadId: cthread.id)
    }
    
    /*******************************************************************************************/
    
    private class DeleteCompletionConfirmation {
        let types = ["User", "UserInvitation", "Group", "Message", "UserActivity", "ConversationThread", "GroupUserFolder", "GroupActivity", "subscriptions"]
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
    
    func deleteRecord(record: RecordId, completion: @escaping () -> Void) {
        let cloudRecordId = record as? CloudRecordId
        if( cloudRecordId != nil ) {
            let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [cloudRecordId!.record.recordID])
            operation.modifyRecordsCompletionBlock = {
                (savedRecords: [CKRecord]?, deletedRecordIDs: [CKRecordID]?, error: Error?) in
                completion()
            }
            
            self.publicDB.add(operation)

        }
    }
    
    func deleteAllRecords(subscriptionsOnly: Bool, completion: @escaping () -> Void){
        if( subscriptionsOnly ) {
            deleteAllSubscriptions(completion: { (step) -> () in
                completion()
            })
            return
        }
        let complete = DeleteCompletionConfirmation(full: completion)
        for type in complete.types {
            if( type == "subscriptions" ) {
                deleteAllSubscriptions(completion: complete.completion)
            } else {
                deleteAllRecords(recordType: type, completion: complete.completion)
            }
        }
    }
    
    private func deleteAllRecords(recordType: String, completion: @escaping (String) -> ()) {
    
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
    
    private func deleteAllSubscriptions(completion: @escaping (String) -> ()) {
        publicDB.fetchAllSubscriptions { (subscriptions, error) in
            if( subscriptions == nil ) {
                if( error != nil ) {
                    print(error!)
                }
                return
            }
            
            var subscriptionIDsArray: [String] = []
            for sub in subscriptions! {
                subscriptionIDsArray.append(sub.subscriptionID)
            }
            
            let operation = CKModifySubscriptionsOperation(subscriptionsToSave: nil, subscriptionIDsToDelete: subscriptionIDsArray)
            operation.modifySubscriptionsCompletionBlock = {
                (saved, deleted, error) in
                print("deleted all subscriptions")
                completion("subscriptions")
            }
            
            self.publicDB.add(operation)
        }
    }
    
    /************************************************************************************/
    
    private func deleteUserRecords(records: [CKRecord]?, error: Error?, user: User, message: String, completion: @escaping () -> ()) {
        if( error != nil ) {
            print(error!)
            return
        }
        if( records == nil || records!.count == 0 ) {
            completion()
            return
        }
        
        var recordIDsArray: [CKRecordID] = []
        for record in records! {
            recordIDsArray.append(record.recordID)
        }
        
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDsArray)
        operation.modifyRecordsCompletionBlock = {
            (savedRecords: [CKRecord]?, deletedRecordIDs: [CKRecordID]?, error: Error?) in
            print(message, user.label ?? "unknown")
            
            if( error != nil ) {
                print(error!)
            }
            
            completion()
        }
        
        self.publicDB.add(operation)

    }
    
    func deleteOldMessages(olderThan: Date, user: User, completion: @escaping () -> ()) {
        let query = CKQuery(recordType: "Message", predicate: NSPredicate(format: String("(user_id = %@) AND (last_modified <= %@)"), argumentArray: [user.id.id, olderThan]))
        publicDB.perform(query, inZoneWith: nil, completionHandler: { (records, error) in
            self.deleteUserRecords(records: records, error: error, user: user, message: "Delete old Messages for ", completion: completion)
        })
    }
    
    func deleteOldConversationThread(olderThan: Date, user: User, completion: @escaping () -> ()) {
        let query = CKQuery(recordType: "ConversationThread", predicate: NSPredicate(format: String("(user_id = %@) AND (last_modified <= %@)"), argumentArray: [user.id.id, olderThan]))
        publicDB.perform(query, inZoneWith: nil, completionHandler: { (records, error) in
            
            if( records != nil ) {
                for record in records! {
                    let recordId = RecordId(string: String(record["id"] as! NSString))
                    self.removeConversationThreadNotification(cthreadId: recordId)
                }
            }
            
            self.deleteUserRecords(records: records, error: error, user: user, message: "Delete old conversations for ", completion: completion)
        })
    }

    func deleteIrrelevantInvitations(olderThan: Date, user: User, completion: @escaping () -> ()) {
        // OR queries are not supported by CloudKit. 
        // For more information see: https://developer.apple.com/library/ios/documentation/CloudKit/Reference/CKQuery_class/ 
        //
        // So decompose query into two queries: old invitations
        let query1 = CKQuery(
            recordType: "UserInvitation",
            predicate: NSPredicate(format: String("(from_user_id = %@) AND (date_created <= %@)"), argumentArray: [user.id.id, olderThan])
        )
        publicDB.perform(query1, inZoneWith: nil, completionHandler: { (records, error) in
            self.deleteUserRecords(records: records, error: error, user: user, message: "Delete old invitations for ", completion: completion)
        })

        // and accepted invitations.
        let query2 = CKQuery(
            recordType: "UserInvitation",
            predicate: NSPredicate(format: String("(from_user_id = %@) AND (accepted == 1)"), argumentArray: [user.id.id])
        )
        publicDB.perform(query2, inZoneWith: nil, completionHandler: { (records, error) in
            self.deleteUserRecords(records: records, error: error, user: user, message: "Delete accepted invitations for ", completion: completion)
        })
    }

    func deleteOldPollRecords(olderThan: Date, user: User, completion: @escaping () -> ()) {
        let query = CKQuery(recordType: "PollRecord", predicate: NSPredicate(format: String("(user_id = %@) AND (date_created <= %@)"), argumentArray: [user.id.id, olderThan]))
        publicDB.perform(query, inZoneWith: nil, completionHandler: { (records, error) in
            self.deleteUserRecords(records: records, error: error, user: user, message: "Delete old PollRecords for ", completion: completion)
        })
    }
}
