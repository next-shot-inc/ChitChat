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
        
        let recoveryQuestion = record["recoveryQuestion"] as? NSString
        if( recoveryQuestion != nil ) {
            self.recoveryQuestion = String(recoveryQuestion!)
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
        if( self.recoveryQuestion != nil ) {
            record["recoveryQuestion"] = NSString(string: self.recoveryQuestion!)
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
        
        let to_user_label_string = record["to_user_label"] as? NSString
        if( to_user_label_string != nil ) {
            self.to_user_label = String(to_user_label_string!)
        }
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
        if( to_user_label != nil ) {
            record["to_user_label"] = NSString(string: to_user_label!)
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
        
        let createdFromMessage_ref = record["createdFromMessage_reference"] as? CKReference
        if( createdFromMessage_ref != nil ) {
            let id = String(record["createdFromMessage_id"] as! NSString)
            createdFromMessage_id = ReferenceCloudRecordId(recordId: createdFromMessage_ref!.recordID, id: id)
        } else {
            let createdFromMessage_id = record["createdFromMessage_id"] as? NSString
            if( createdFromMessage_id != nil ) {
               self.createdFromMessage_id = RecordId(string: String(createdFromMessage_id!))
            }
        }
    }
    
    func fillRecord(record: CKRecord) {
        record["id"] = NSString(string: self.id.id)
        record["group_id"] = NSString(string: self.group_id.id)
        if( self.group_id is CloudRecordId ) {
            record["group_reference"] = CKReference(record: (self.group_id as! CloudRecordId).record, action: .deleteSelf)
        } else if( self.group_id is ReferenceCloudRecordId ) {
            record["group_reference"] = CKReference(recordID: (self.group_id as! ReferenceCloudRecordId).recordId, action: .deleteSelf)
        }
        record["title"] = NSString(string: self.title)
        record["last_modified"] = NSDate(timeIntervalSince1970: self.last_modified.timeIntervalSince1970)
        if( self.user_id != nil ) {
            record["user_id"] = NSString(string: self.user_id!.id)
        }
        if( self.createdFromMessage_id != nil ) {
            record["createdFromMessage_id"] = NSString(string: self.createdFromMessage_id!.id)
            if( self.createdFromMessage_id! is CloudRecordId ) {
                record["createdFromMessage_reference"] = CKReference(record: (self.createdFromMessage_id! as! CloudRecordId).record, action: .none)
            } else if( self.createdFromMessage_id! is ReferenceCloudRecordId ) {
                record["createdFromMessage_reference"] = CKReference(recordID: (self.createdFromMessage_id! as! ReferenceCloudRecordId).recordId, action: .none)
            }
        }
    }
}

extension Message {
    convenience init(record: CKRecord) {
        let thread_ref = record["thread_reference"] as? CKReference
        let thread_id : RecordId
        if( thread_ref == nil ) {
            thread_id = RecordId(record: record, forKey: "thread_id")
        } else {
            let id = String(record["thread_id"] as! NSString)
            thread_id = ReferenceCloudRecordId(recordId: thread_ref!.recordID, id: id)
        }
        
        self.init(
            id: CloudRecordId(record: record),
            threadId: thread_id,
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
            record["thread_reference"] = CKReference(record: (self.conversation_id as! CloudRecordId).record, action: .deleteSelf)
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
        if( self.largeImage != nil ) {
            let data = UIImageJPEGRepresentation(self.largeImage!, 1.0)
            let url = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(NSUUID().uuidString+".dat")
            if url != nil {
                do {
                    try data!.write(to: url!, options: [.atomic])
                } catch let e as NSError {
                    print("Error! \(e)")
                }
                let asset = CKAsset(fileURL: url!)
                record["largeImage"] = asset
                assets.urls.append(url!)
            }
        }
    }
    
    class func getDesiredKeys() -> [String] {
        return ["id", "user_id", "thread_id", "thread_reference", "group_id", "text", "last_modified", "fromName", "inThread", "options", "image"]
    }
    class func getLargeImageKey() -> [String] {
        return ["largeImage"]
    }
    
    func getLargeImage(record: CKRecord) {
        let asset = record["largeImage"] as? CKAsset
        if( asset != nil ) {
            let imageData: Data
            do {
                imageData = try Data(contentsOf: asset!.fileURL)
                self.largeImage = UIImage(data: imageData)
            } catch {
                
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

extension MessageRecord {
    // Includes migration code for PollMessage record to more generic MessageRecord
    convenience init(record: CKRecord) {
        let typeRecord = record["type"]
        var recordType = String("PollRecord")
        if( typeRecord != nil ) {
            recordType = (typeRecord as! NSString) as String
        }
        
        let message_ref = record["message_reference"] as? CKReference
        let message_id : RecordId
        if( message_ref == nil ) {
            message_id = RecordId(record: record, forKey: "poll_id")
        } else {
            let id = String(record["poll_id"] as! NSString)
            message_id = ReferenceCloudRecordId(recordId: message_ref!.recordID, id: id)
        }
        
        self.init(
            id: CloudRecordId(record: record),
            message_id: message_id,
            user_id: RecordId(record: record, forKey: "user_id"),
            type: recordType
        )
        let payLoadRecord = record["payLoad"]
        if( payLoadRecord != nil ) {
            self.payLoad = (payLoadRecord as! NSString) as String
        } else {
            // Backward compatibility
            let checkedOptionRecord = record["checked_option"]
            if( checkedOptionRecord != nil ) {
                let checkedOption = (checkedOptionRecord as! NSNumber) as! Int
                self.payLoad = "{ \"checked_option\" : \(checkedOption), \"version\" : \"1.0\", \"type\" : \"PollRecord\" }"
            }
        }
        self.date_created = Date(timeIntervalSince1970: (record["date_created"] as! NSDate).timeIntervalSince1970)
        
        let group_id = record["group_id"]
        if( group_id != nil ) {
            self.group_id = RecordId(record: record, forKey: "group_id")
        }

        if( self.group_id != nil ) {
            record["group_id"] = NSString(string: self.group_id!.id)
        }
        
    }
    func fillRecord(record: CKRecord) {
        record["id"] =  NSString(string: self.id.id)
        record["user_id"] = NSString(string: self.user_id.id)
        record["poll_id"] = NSString(string: self.message_id.id)
        record["payLoad"] = NSString(string: self.payLoad)
        record["date_created"] = NSDate(timeIntervalSince1970: self.date_created.timeIntervalSince1970)
        record["type"] = NSString(string: self.type)
        if( group_id != nil ) {
            record["group_id"] = NSString(string: self.group_id!.id)
        }
        if( self.message_id is CloudRecordId ) {
            record["message_reference"] = CKReference(record: (self.message_id as! CloudRecordId).record, action: .deleteSelf)
        } else if( self.message_id is ReferenceCloudRecordId ) {
            record["message_reference"] = CKReference(recordID: (self.message_id as! ReferenceCloudRecordId).recordId, action: .deleteSelf)
        }
    }
}


class CloudDBCursor : DBCursor {
    let impl : CKQueryCursor
    init(impl: CKQueryCursor) {
        self.impl = impl
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
    func setupNotifications(cthread: ConversationThread, groupId: RecordId) {
        
        let predicateFormat = "group_id == %@"
        
        let edit_message_key = "edit_type_Message_group_id_\(groupId.id)"
        
        subscribe(subscriptionId: edit_message_key, predicateFormat: predicateFormat, createSubscription: { () -> Void in
            let edit_message_subscription = CKQuerySubscription(
                recordType: "Message", predicate: NSPredicate(format: predicateFormat, argumentArray: [groupId.id]),
                subscriptionID: edit_message_key, options: [CKQuerySubscriptionOptions.firesOnRecordUpdate]
            )
            
            // If you don’t set any of the alertBody, soundName, or shouldBadge properties,
            // the push notification is sent at a lower priority that doesn’t cause the system to alert the user.
            let edit_notificationInfo = CKNotificationInfo()
            //edit_notificationInfo.soundName = "default"
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
        let edit_key = "edit_type_Message_thread_id_\(cthreadId.id)"
        unsubscribe(key: edit_key, completionHandler: {})
    }
    
    //
    func setupNotifications(userId: RecordId) {
        let new_key = "new_type_GroupUserFolder_user_id\(model.me().id.id)"
        
        /*
         Notify when a user has been added to a group
         */
        let predicateFormat = "user_id == %@"
        subscribe(subscriptionId: new_key, predicateFormat: predicateFormat, createSubscription: { () -> Void in
            let new_group_subscription = CKQuerySubscription(
                recordType: "GroupUserFolder", predicate: NSPredicate(format: predicateFormat, argumentArray: [model.me().id.id]),
                subscriptionID: new_key, options: [CKQuerySubscriptionOptions.firesOnRecordCreation]
            )
            let notificationInfo = CKNotificationInfo()
            //notificationInfo.alertLocalizationKey = "New group %1$@ fom %2$@"
            //notificationInfo.shouldBadge = true
            //notificationInfo.alertLocalizationArgs = ["groupName", "fromName"]

            //notificationInfo.soundName = "default"
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
    // Notify when a conversation thread is deleted
    // Notify when the group activity record is modified
    // Notify when a new message is sent.
    func setupNotifications(groupId: RecordId) {
        
        let predicateFormat = "group_id == %@"
        let new_key = "new_type_ConversationThread_group_id_\(groupId.id)"
        
        subscribe(subscriptionId: new_key, predicateFormat: predicateFormat, createSubscription: { () -> Void in
            
            let new_cthread_subscription = CKQuerySubscription(
                recordType: "ConversationThread", predicate: NSPredicate(format: predicateFormat, argumentArray: [groupId.id]),
                subscriptionID: new_key, options: [CKQuerySubscriptionOptions.firesOnRecordCreation]
            )
            let notificationInfo = CKNotificationInfo()
            //notificationInfo.soundName = "default"
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
            //notificationInfo.soundName = "default"
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
            //notificationInfo.soundName = "default"
            notificationInfo.shouldSendContentAvailable = true // To make sure it is sent
            
            edit_group_activity_subscription.notificationInfo = notificationInfo
            
            self.publicDB.save(edit_group_activity_subscription, completionHandler: { (sub, error) -> Void in
                if( error != nil ) {
                    print(error!)
                }
            })
        })
 

        // New Message
        
        let new_message_key = "new_type_Message_group_id_\(groupId.id)"
        
        subscribe(subscriptionId: new_message_key, predicateFormat: predicateFormat, createSubscription: { () -> Void in
            let new_message_subscription = CKQuerySubscription(
                recordType: "Message",
                predicate: NSPredicate(format: predicateFormat, argumentArray: [groupId.id]),
                subscriptionID: new_message_key,
                options: [CKQuerySubscriptionOptions.firesOnRecordCreation]
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

         
        // New Message Record
        let new_message_record_key = "new_type_PollRecord_group_id_\(groupId.id)"
        
        subscribe(subscriptionId: new_message_record_key, predicateFormat: predicateFormat, createSubscription: { () -> Void in
            let new_message_record_subscription = CKQuerySubscription(
                recordType: "PollRecord",
                predicate: NSPredicate(format: predicateFormat, argumentArray: [groupId.id]),
                subscriptionID: new_message_record_key,
                options: [CKQuerySubscriptionOptions.firesOnRecordCreation]
            )
            let notificationInfo = CKNotificationInfo()
            notificationInfo.shouldSendContentAvailable = true // To make sure it is sent
            //notificationInfo.soundName = "default"
            
            new_message_record_subscription.notificationInfo = notificationInfo
            
            self.publicDB.save(new_message_record_subscription, completionHandler: { (sub, error) -> Void in
                if( error != nil ) {
                    print(error!)
                }
            })
        })
        
        let mrecord_predicateFormat = "(group_id == %@) AND (type == 'LocationRecord')"
        let edit_mrecord_key = "edit_type_PollRecord_group_id_\(groupId.id)_LR"
        
        subscribe(subscriptionId: edit_mrecord_key, predicateFormat: predicateFormat, createSubscription: { () -> Void in
            let edit_mrecord_subscription = CKQuerySubscription(
                recordType: "PollRecord", predicate: NSPredicate(format: mrecord_predicateFormat, argumentArray: [groupId.id]),
                subscriptionID: edit_mrecord_key, options: [CKQuerySubscriptionOptions.firesOnRecordUpdate]
            )
            
            // If you don’t set any of the alertBody, soundName, or shouldBadge properties,
            // the push notification is sent at a lower priority that doesn’t cause the system to alert the user.
            let edit_notificationInfo = CKNotificationInfo()
            //edit_notificationInfo.soundName = "default"
            edit_notificationInfo.shouldSendContentAvailable = true // To make sure it is sent
            edit_mrecord_subscription.notificationInfo = edit_notificationInfo
            
            self.publicDB.save(edit_mrecord_subscription, completionHandler: { (sub, error) -> Void in
                if( error != nil ) {
                    print(error!)
                }
            })
        })

    }
    
    func removeGroupNotification(groupId: RecordId) {
         let new_key = "new_type_ConversationThread_group_id_\(groupId.id)"
        unsubscribe(key: new_key, completionHandler: {})
        let delete_key = "delete_type_ConversationThread_group_id_\(groupId.id)"
         unsubscribe(key: delete_key, completionHandler: {})
        let new_message_key = "new_type_Message_group_id_\(groupId.id)"
         unsubscribe(key: new_message_key, completionHandler: {})
        let edit_message_key = "edit_type_Message_group_id_\(groupId.id)"
        unsubscribe(key: edit_message_key, completionHandler: {})
        let new_message_record_key = "new_type_PollRecord_group_id_\(groupId.id)"
        unsubscribe(key: new_message_record_key, completionHandler: {})
        let edit_mrecord_key = "edit_type_PollRecord_group_id_\(groupId.id)_LR"
        unsubscribe(key: edit_mrecord_key, completionHandler: {})
    }
    
    // If the subscription exists and the predicate is the same, then we don't need to create this subscrioption.
    // If the predicate is different, then we first need to delete the old
    func subscribe(subscriptionId: String, predicateFormat: String, createSubscription: @escaping () -> Void) {
        publicDB.fetch(withSubscriptionID: subscriptionId, completionHandler: { (subscription, error) in
            let querySub = subscription as? CKQuerySubscription
            if querySub != nil {
                // Always fails: as the query sub.predicate is without variable while the predicate format is with variable.
                //if predicateFormat != querySub!.predicate.predicateFormat {
                    //self.unsubscribe(key: subscriptionId, completionHandler: createSubscription)
                //}
                // Do nothing
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
                        DispatchQueue.main.async {
                           for view in views {
                               if( view.notify_delete_conversation != nil ) {
                                  view.notify_delete_conversation!(recordId)
                               }
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
                            let user_id = String(record!["user_id"] as! NSString)
                            if( user_id == model.me().id.id ) {
                                // Get the group newly added to the user
                                self.publicDB.fetch(withRecordID: group_ref.recordID, completionHandler: { (grp_record, error) -> Void in
                                    if( grp_record != nil ) {
                                        let group = Group(record: grp_record!)
                                        DispatchQueue.main.async {
                                            if( queryNotification.queryNotificationReason == .recordCreated ) {
                                                model.addMeToGroup(group: group)
                                            }
                                        }
                                    }
                                })
                            }
                        } else if( record!.recordType == "PollRecord" ) {
                            let messageRecord = MessageRecord(record: record!)
                            DispatchQueue.main.async {
                                if( queryNotification.queryNotificationReason == .recordCreated ) {
                                    for view in views {
                                        if( view.notify_new_message_record != nil ) {
                                            view.notify_new_message_record!(messageRecord)
                                        }
                                    }
                                } else {
                                    for view in views {
                                        if( view.notify_edit_message_record != nil ) {
                                            view.notify_edit_message_record!(messageRecord)
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
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = number
        }
    }
    
    /*******************************************************************************/
    
    func saveUser(user: User, completion: @escaping (_ status: Bool) -> ()) {
        let dbid = user.id as? CloudRecordId
        var record : CKRecord
        if( dbid == nil ) {
            record = CKRecord(recordType: "User")
            user.id = CloudRecordId(record: record, id: user.id.id)
        } else {
            record = dbid!.record
        }
        user.fillRecord(record: record)
        
        self.publicDB.save(record, completionHandler: ({ (record, error) in
            self.saveCompletionHandler(record: record, error: error)
            completion(error == nil)
        }))
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
    
    func addUserToFriends(user: User, friend: User) {
        let record = CKRecord(recordType: "FriendsUserFolder")
        record["friend_id"] = NSString(string: friend.id.id)
        record["user_id"] = NSString(string: user.id.id)
        let frbid = friend.id as? CloudRecordId
        if( frbid != nil ) {
            record["friend_reference"] = CKReference(record: frbid!.record, action: .none)
        }
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

    func saveMessageRecord(messageRecord: MessageRecord) {
        let dbid = messageRecord.id as? CloudRecordId
        var record : CKRecord
        if( dbid == nil ) {
            record = CKRecord(recordType: "PollRecord")
            messageRecord.id = CloudRecordId(record: record, id: messageRecord.id.id)
            messageRecord.fillRecord(record: record)
            
            self.publicDB.save(record, completionHandler: self.saveCompletionHandler)
        } else {
            record = dbid!.record
            messageRecord.fillRecord(record: record)
            
            // Has we should be up-to-date we can safely overwrite
            let ops: CKModifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
            ops.perRecordCompletionBlock = self.saveCompletionHandler
            ops.savePolicy = CKRecordSavePolicy.changedKeys
            
            self.publicDB.add(ops)
        }
        
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
                    let seconds = Double(truncating: retry)
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
    
    func getUserInvitations(to_group: Group, completion: @escaping ([UserInvitation]) -> ()) {
        let query = CKQuery(recordType: "UserInvitation", predicate: NSPredicate(
            format: String("(to_group_id = %@) AND (accepted == 0)"), argumentArray: [to_group.id.id])
        )
        publicDB.perform(query, inZoneWith: nil, completionHandler: { results, error -> Void in
            if( error != nil ) {
                self.getCompletionHandler(error: error)
            }
            
            if( results != nil ) {
                var invitations = [UserInvitation]()
                for r in results! {
                    let invitation = UserInvitation(record: r)
                    invitations.append(invitation)
                }
                completion(invitations)
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
            if results != nil  {
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
        
        var messages = [Message]()
        
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.desiredKeys = Message.getDesiredKeys()
        queryOperation.recordFetchedBlock = { record -> Void in
            let message = Message(record: record)
            messages.append(message)
        }
        
        queryOperation.queryCompletionBlock = { cursor, error -> Void in
            if( cursor == nil ) {
                completion(messages)
            } else {
                let nqueryOperation = CKQueryOperation(cursor: cursor!)
                nqueryOperation.queryCompletionBlock = queryOperation.queryCompletionBlock
                nqueryOperation.recordFetchedBlock = queryOperation.recordFetchedBlock
                nqueryOperation.desiredKeys = queryOperation.desiredKeys
                self.publicDB.add(nqueryOperation)
            }
        }
        publicDB.add(queryOperation)
    }
    
    func getMessagesForThread(threadId: RecordId, dateLimit: (min: Int, max: Int), completion: @escaping ([Message]) -> ()) {
        let numberOfDaysMax = min(self.dateLimit, TimeInterval(dateLimit.max))
        let secondsInADay : TimeInterval = 24*60*60
        let min_date = Date(timeInterval: -numberOfDaysMax*secondsInADay, since: Date())
        let max_date = Date(timeInterval: -TimeInterval(dateLimit.min)*secondsInADay, since: Date())
        let query = CKQuery(recordType: "Message", predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: String("(thread_id = %@)"), argumentArray: [threadId.id]),
            NSPredicate(format: String("(last_modified > %@)"), argumentArray: [min_date]),
            NSPredicate(format: String("(last_modified <= %@)"), argumentArray: [max_date])
        ]))
        query.sortDescriptors = [NSSortDescriptor(key: "last_modified", ascending: true)]
        
        var messages = [Message]()
        
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.desiredKeys = Message.getDesiredKeys()
        queryOperation.recordFetchedBlock = { record -> Void in
            let message = Message(record: record)
            messages.append(message)
        }
        
        queryOperation.queryCompletionBlock = { cursor, error -> Void in
            if( cursor == nil ) {
                completion(messages)
            } else {
                let nqueryOperation = CKQueryOperation(cursor: cursor!)
                nqueryOperation.queryCompletionBlock = queryOperation.queryCompletionBlock
                nqueryOperation.recordFetchedBlock = queryOperation.recordFetchedBlock
                nqueryOperation.desiredKeys = queryOperation.desiredKeys
                self.publicDB.add(nqueryOperation)
            }
            
        }
        publicDB.add(queryOperation)
    }
    
    func getMessageStartingThread(conversationThread: ConversationThread, completion: @escaping (Message) -> ()) {
        if( conversationThread.createdFromMessage_id is ReferenceCloudRecordId ) {
             let mRecordId = (conversationThread.createdFromMessage_id as! ReferenceCloudRecordId).recordId
            
             let fetchOp = CKFetchRecordsOperation(recordIDs: [mRecordId])
             fetchOp.desiredKeys = Message.getDesiredKeys()
             fetchOp.perRecordCompletionBlock = { record, recordId, error -> Void in
                if( record != nil ) {
                    let message = Message(record: record!)
                    completion(message)
                }
            }
            publicDB.add(fetchOp)
        }
    }
    
    func getMessageLargeImage(message: Message, completion: @escaping () -> ()) {
        let query = CKQuery(recordType: "Message", predicate: NSPredicate(format: String("id = %@"), argumentArray: [message.id.id]))
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.desiredKeys = Message.getLargeImageKey()
        queryOperation.recordFetchedBlock = { record -> Void in
            message.getLargeImage(record: record)
        }
        
        queryOperation.queryCompletionBlock = { cursor, error -> Void in
            if( cursor == nil ) {
                completion()
            } else {
                let nqueryOperation = CKQueryOperation(cursor: cursor!)
                nqueryOperation.queryCompletionBlock = queryOperation.queryCompletionBlock
                nqueryOperation.recordFetchedBlock = queryOperation.recordFetchedBlock
                nqueryOperation.desiredKeys = queryOperation.desiredKeys
                self.publicDB.add(nqueryOperation)
            }
        }
        publicDB.add(queryOperation)
    }
    
    func getUserActivityDates(userId: RecordId, completion: @escaping ([Date]) -> ()) {
        let query = CKQuery(recordType: "Message", predicate: NSPredicate(format: String("user_id = %@"), argumentArray: [userId.id]))
        
        var dates = [Date]()
        
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.desiredKeys = ["last_modified"]
        queryOperation.recordFetchedBlock = { record -> Void in
            let date = Date(timeIntervalSince1970: (record["last_modified"] as! NSDate).timeIntervalSince1970)
            dates.append(date)
        }
        
        queryOperation.queryCompletionBlock = { cursor, error -> Void in
            if( cursor == nil ) {
                completion(dates)
            } else {
                let nqueryOperation = CKQueryOperation(cursor: cursor!)
                nqueryOperation.queryCompletionBlock = queryOperation.queryCompletionBlock
                nqueryOperation.recordFetchedBlock = queryOperation.recordFetchedBlock
                nqueryOperation.desiredKeys = queryOperation.desiredKeys
                self.publicDB.add(nqueryOperation)
            }
        }
        publicDB.add(queryOperation)
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
    
    func getMessageRecords(message: Message, type: String, completion: @escaping ([MessageRecord]) -> Void ) {
        let query = CKQuery(recordType: "PollRecord", predicate: NSPredicate(format: "poll_id = %@ and type = %@", argumentArray: [message.id.id, type]))
        publicDB.perform(query, inZoneWith: nil, completionHandler: { results, error -> Void in
            var records = [MessageRecord]()
            if results!.count > 0 {
                for record in results! {
                    let messageRecord = MessageRecord(record: record)
                    records.append(messageRecord)
                }
                completion(records)
            } else {
                completion(records)
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
                    let seconds = Double(truncating: retry)
                    print("Debug: Should retry in \(seconds) seconds. \(error!)")
                }
            }
        }
    }

    
    /******************************************************************************************************/
    
    func deleteGroup(group: Group, completion: @escaping ()-> ()) {
        let cloudRecordId = group.id as? CloudRecordId
        if( cloudRecordId == nil ) {
            return
        }
        var recordIDsArray: [CKRecordID] = [cloudRecordId!.record.recordID]
        
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDsArray)
        operation.modifyRecordsCompletionBlock = {
            (savedRecords: [CKRecord]?, deletedRecordIDs: [CKRecordID]?, error: Error?) in
            
            print("delete group ", group.name)
            
            completion()
        }
        
        self.publicDB.add(operation)
        
        removeGroupNotification(groupId: group.id)
    }
    
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
    // Filter message records which are still unread by some users of the group.
    func doDeleteOldMessage(records: [CKRecord], user: User, completion: @escaping ()-> ()) {
        var toDeleteRecords = [CKRecord]()
        var processedRecord = 0
        for record in records {
            let message = Message(record: record)
            self.getMessageRecords(message: message, type: "ReadMessageRecord", completion: { (readRecords) in
                if( readRecords.count > 0 ) {
                    self.getUsersForGroup(groupId: message.group_id!, completion: { (users) in
                        // For all users of the group
                        var allFound = true
                        for group_user in users {
                            var foundReadRecord = false
                            if( group_user.id == user.id ) {
                                // The author of the message automatically reads it.
                                foundReadRecord = true
                            } else {
                                // See if there is a read Record for this user
                                for readRecord in readRecords {
                                    if( group_user.id == readRecord.user_id ) {
                                        foundReadRecord = true
                                        break
                                    }
                                }
                            }
                            if( !foundReadRecord) {
                                // This user has no read records of this message. Cannot delete it.
                                allFound = false
                                break
                            }
                        }
                        if( allFound ) {
                            toDeleteRecords.append(record)
                        }
                        processedRecord += 1
                        if( processedRecord == records.count ) {
                            self.deleteUserRecords(records: toDeleteRecords, error: nil, user: user, message: "Delete old Messages for ", completion: completion)
                        }
                    })
                } else {
                    processedRecord += 1
                    if( processedRecord == records.count ) {
                        self.deleteUserRecords(records: toDeleteRecords, error: nil, user: user, message: "Delete old Messages for ", completion: completion)
                    }
                }
            })
        }
    }
    
    func deleteOldMessages(olderThan: Date, user: User, completion: @escaping () -> ()) {
        let query = CKQuery(recordType: "Message", predicate: NSPredicate(format: String("(user_id = %@) AND (last_modified <= %@)"), argumentArray: [user.id.id, olderThan]))
        
        var records = [CKRecord]()
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.desiredKeys = Message.getDesiredKeys()
        queryOperation.recordFetchedBlock = { record -> Void in
            records.append(record)
        }
        
        queryOperation.queryCompletionBlock = { cursor, error -> Void in
            if( cursor == nil ) {
                self.doDeleteOldMessage(records: records, user: user, completion: completion)
               
            } else {
                let nqueryOperation = CKQueryOperation(cursor: cursor!)
                nqueryOperation.queryCompletionBlock = queryOperation.queryCompletionBlock
                nqueryOperation.recordFetchedBlock = queryOperation.recordFetchedBlock
                nqueryOperation.desiredKeys = queryOperation.desiredKeys
                self.publicDB.add(nqueryOperation)
            }
        }
        publicDB.add(queryOperation)
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

    func deleteOldMessageRecords(olderThan: Date, user: User, completion: @escaping () -> ()) {
        // They are now deleted by deleting the Message.
        /*
        let query = CKQuery(recordType: "PollRecord", predicate: NSPredicate(format: String("(user_id = %@) AND (date_created <= %@)"), argumentArray: [user.id.id, olderThan]))
        publicDB.perform(query, inZoneWith: nil, completionHandler: { (records, error) in
           
            self.deleteUserRecords(records: records, error: error, user: user, message: "Delete old Message Records for ", completion: completion)
        })
        */
    }
}
