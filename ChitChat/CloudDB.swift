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
        record["id"] = NSString(string: self.id.id)
        record["label"] = NSString(string: self.label!)
        record["phoneNumber"] = NSString(string: self.phoneNumber)
        if( self.icon != nil ) {
            record["iconBytes"] = NSData(data: UIImageJPEGRepresentation(self.icon!, 1.0)!)
        } else {
            record["iconBytes"] = NSData()
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
        self.fromName = String(record["fromName"] as! NSString)
        self.inThread = String(record["inThread"] as! NSString)
        
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
        record["fromName"] = NSString(string: self.fromName)
        record["inThread"] = NSString(string: self.inThread)
        
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
    
    func setupNotifications(cthread: ConversationThread) {
        
        let predicateFormat = "(thread_id == %@) AND (user_id != %@)"
        
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
            
            new_message_subscription.notificationInfo = notificationInfo
            
            self.publicDB.save(new_message_subscription, completionHandler: { (sub, error) -> Void in
                if( error != nil ) {
                    print(error!)
                }
            })
        })
        
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
    
    func setupNotifications(userId: RecordId) {
        let predicateFormat = "user_id == %@"
        
        let new_key = "new_type_Group_user_id\(model.me().id.id)"
        
        subscribe(subscriptionId: new_key, predicateFormat: predicateFormat, createSubscription: { () -> Void in
            let new_group_subscription = CKQuerySubscription(
                recordType: "GroupUserFolder", predicate: NSPredicate(format: predicateFormat, argumentArray: [model.me().id.id]),
                subscriptionID: new_key, options: [CKQuerySubscriptionOptions.firesOnRecordCreation]
            )
            let notificationInfo = CKNotificationInfo()
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
                            let cthread = ConversationThread(record: record!)
                            DispatchQueue.main.async {
                                for view in views {
                                    if( view.notify_new_conversation != nil ) {
                                        view.notify_new_conversation!(cthread)
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
                print("Error resetting badge: \(error)")
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
                if( error != nil ) {
                    print(error!)
                }
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
            if results != nil && results!.count > 0 {
                let activity = GroupActivity(record: results![0])
                completion(activity)
            } else {
                completion(nil)
            }
        })
    }

    func getThreadsForGroup(groupId: RecordId, completion: @escaping ([ConversationThread]) -> ()) {
        let query = CKQuery(recordType: "ConversationThread", predicate: NSPredicate(format: String("group_id = %@"), argumentArray: [groupId.id]))
        query.sortDescriptors = [NSSortDescriptor(key: "last_modified", ascending: false)]
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
        query.sortDescriptors = [NSSortDescriptor(key: "last_modified", ascending: true)]
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
        let types = ["User", "Group", "Message", "UserActivity", "ConversationThread", "GroupUserFolder", "GroupActivity", "subscriptions"]
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
            if( type == "subscriptions" ) {
                deleteAllSubscriptions(completion: complete.completion)
            } else {
                deleteAllRecords(recordType: type, completion: complete.completion)
            }
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
    
    func deleteAllSubscriptions(completion: @escaping (String) -> ()) {
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
}
