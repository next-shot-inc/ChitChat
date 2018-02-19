//
//  ModelDB.swift
//  ChitChat
//
//  Created by next-shot on 3/10/17.
//  Copyright © 2017 next-shot. All rights reserved.
//

import Foundation

/*********************************************************************/

protocol DBProtocol {
    func getUsersForGroup(groupId: RecordId, completion: @escaping ([User]) -> ())
    func getGroupsForUser(userId: RecordId, completion: @escaping ([Group]) -> ())
    func getThreadsForGroup(groupId: RecordId, completion: @escaping ([ConversationThread]) -> ())
    func getThread(threadId: RecordId, completion: @escaping (ConversationThread?) -> ())
    func getMessagesForThread(threadId: RecordId, completion: @escaping ([Message]) -> ())
    func getMessagesForThread(threadId: RecordId, dateLimit: (min: Int, max: Int), completion: @escaping ([Message]) -> ())
    func getMessageStartingThread(conversationThread: ConversationThread, completion: @escaping (Message) -> ())
    func getMessageLargeImage(message: Message, completion: @escaping () -> ())
    func getUserActivityDates(userId: RecordId, completion: @escaping ([Date]) -> ())
    func getUser(userId: RecordId, completion: @escaping (User) -> ())
    func getUser(phoneNumber: String, completion: @escaping (User?) -> ())
    func getUserInvitations(to_user: String, completion: @escaping ([UserInvitation], [Group]) -> ())
    func getUserInvitations(to_group: Group, completion: @escaping ([UserInvitation]) -> ())
    func getActivities(userId: RecordId, completion: @escaping ([UserActivity]) -> ())
    func getActivity(userId: RecordId, threadId: RecordId, completion: @escaping (UserActivity?) -> ())
    func getActivityForGroup(groupId: RecordId, completion: @escaping (GroupActivity?) -> ())
    func getActivitiesForGroups(groups: [Group], completion: @escaping ([GroupActivity]) -> ())
    func getDecorationThemes(completion: @escaping ([DecorationTheme]) -> ())
    func getDecorationStamps(theme: DecorationTheme, completion: @escaping ([DecorationStamp]) -> ())
    func getMessageRecords(message: Message, type: String, completion: @escaping ([MessageRecord]) -> Void )
    func setMessageFetchTimeLimit(numberOfDays: TimeInterval)
    
    func saveUser(user: User, completion: @escaping (_ status: Bool) -> ())
    func saveUserInvitation(userInvitation: UserInvitation)
    func saveMessage(message: Message, completion: @escaping () -> ())
    func saveGroup(group: Group)
    func saveActivity(activity: GroupActivity)
    func addUserToGroup(group: Group, user: User, by: User)
    func addUserToFriends(user: User, friend: User)
    func saveConversationThread(conversationThread: ConversationThread)
    func saveActivity(activity: UserActivity)
    func saveDecorationThemes(themes: [DecorationTheme])
    func saveDecorationStamps(stamps: [DecorationStamp])
    func saveMessageRecord(messageRecord: MessageRecord)
    
    func setupNotifications(cthread: ConversationThread, groupId: RecordId)
    func removeConversationThreadNotification(cthreadId: RecordId)
    func setupNotifications(groupId: RecordId)
    func setupNotifications(userId: RecordId)
    func didReceiveNotification(userInfo: [AnyHashable : Any], views: [ModelView])
    func setAppBadgeNumber(number: Int)
    
    func setAsUser(user: User)
    func isCreatedByUser(record: RecordId) -> Bool
    
    func deleteRecord(record: RecordId, completion: @escaping () -> Void)
    func deleteConversation(cthread: ConversationThread, messages: [Message], user: User, completion: @escaping () -> ())
    func deleteGroup(group: Group, completion: @escaping () -> ())
    func deleteOldConversationThread(olderThan: Date, user: User, completion: @escaping () -> ())
    func deleteOldMessages(olderThan: Date, user: User, completion: @escaping () -> ())
    func deleteIrrelevantInvitations(olderThan: Date, user: User, completion: @escaping () -> ())
    func deleteOldMessageRecords(olderThan: Date, user: User, completion: @escaping () -> ())
    
}

class DBCursor {
    
}

/***************************************************************************************/

class InMemoryDB : DBProtocol {
    
    internal var users = [User]()
    internal var groups = [Group]()
    internal var conversations = [ConversationThread]()
    internal var messages = [Message]()
    internal var user_activities = [UserActivity]()
    internal var group_activities = [GroupActivity]()
    internal var groupUserFolder = GroupUserFolder()
    
    func getGroupsForUser(userId: RecordId, completion: @escaping ([Group]) -> ()) {
        let gids = groupUserFolder.getGroups(user_id: userId)
        var ugroups = [Group]()
        for gid in gids {
            for gr in groups {
                if( gid == gr.id ) {
                    ugroups.append(gr)
                    break
                }
            }
        }
        completion(groups)
    }
    
    func getUsersForGroup(groupId: RecordId, completion: @escaping ([User]) -> ()) {
        let uids = groupUserFolder.getUsers(group_id: groupId)
        var users = [User]()
        for uid in uids {
            for ur in users {
                if( uid == ur.id ) {
                    users.append(ur)
                    break
                }
            }
        }
        completion(users)
    }
    
    func getThreadsForGroup(groupId: RecordId, completion: @escaping ([ConversationThread]) -> ()) {
        let gcs = conversations.filter({ (thread: ConversationThread) -> Bool in
            thread.group_id.id == groupId.id
        })
        completion(gcs)
    }
    
    func getThread(threadId: RecordId, completion: @escaping (ConversationThread?) -> ()) {
        for c in conversations {
            if( c.id.id == threadId.id ) {
                completion(c)
                return
            }
        }
        completion(nil)
    }
    
    func getActivities(userId: RecordId, completion: @escaping ([UserActivity]) -> ()) {
        completion(user_activities)
    }
    
    func getMessagesForThread(threadId: RecordId, completion: @escaping ([Message]) -> ()) {
        let ms = messages.filter({ (message: Message) -> Bool in
            message.conversation_id.id == threadId.id
        })
        completion(ms)
    }
    
    func getMessagesForThread(threadId: RecordId, dateLimit: (min: Int, max: Int), completion: @escaping ([Message]) -> ()) {
        // TODO
    }
    
    func getMessageStartingThread(conversationThread: ConversationThread, completion: @escaping (Message) -> ()) {
    }
    
    func getUserActivityDates(userId: RecordId, completion: @escaping ([Date]) -> ()) {
    }
    
    func getMessageLargeImage(message: Message, completion: @escaping () -> ()) {
        completion()
    }
    
    func getUser(userId: RecordId, completion: @escaping (User) -> ()) {
        for u in users {
            if( u.id.id == userId.id ) {
                return completion(u)
            }
        }
    }
    
    func getUser(phoneNumber: String, completion: @escaping (User?) -> ()) {
        for u in users {
            if( u.phoneNumber == phoneNumber ) {
                return completion(u)
            }
        }
        return completion(nil)
    }
    
    func getUserInvitations(to_user: String, completion: @escaping ([UserInvitation], [Group]) -> ()) {
        return completion([], [])
    }
    func getUserInvitations(to_group: Group, completion: @escaping ([UserInvitation]) -> ()) {
        return completion([])
    }
    
    func getActivity(userId: RecordId, threadId: RecordId, completion: @escaping (UserActivity?) -> ()) {
        for a in user_activities {
            if( a.user_id.id == userId.id && a.thread_id.id == threadId.id ) {
                return completion(a)
            }
        }
        return completion(nil)
    }
    
    func getActivityForGroup(groupId: RecordId, completion: @escaping (GroupActivity?) -> ()) {
        for a in group_activities {
            if( a.group_id.id == groupId.id ) {
                return completion(a)
            }
        }
        return completion(nil)
    }
    func getActivitiesForGroups(groups: [Group], completion: @escaping ([GroupActivity]) -> ()) {
        var acts = [GroupActivity]()
        for g in groups {
            for a in group_activities {
                if( a.group_id == g.id ) {
                    acts.append(a)
                    break
                }
            }
        }
        return completion(acts)
    }
    
    func getDecorationStamps(theme: DecorationTheme, completion: @escaping ([DecorationStamp]) -> ()) {
        // TODO
    }
    func getDecorationThemes(completion: @escaping ([DecorationTheme]) -> ()) {
        // TODO
    }
    func getMessageRecords(message: Message, type: String, completion: @escaping ([MessageRecord]) -> Void ) {
        // TODO
    }
    func saveMessageRecord(messageRecord: MessageRecord) {
        // TODO
    }
    
    func saveUser(user: User, completion: @escaping (_ status: Bool) -> ()) {
        let already = users.contains(where: ({ (u) -> Bool in
            user.id == u.id
        }))
        if( !already ) {
            users.append(user)
        }
    }
    
    func saveUserInvitation(userInvitation: UserInvitation) {
        // TODO
    }
    
    func saveMessage(message: Message, completion : @escaping () -> ()) {
        let contained = messages.contains(where: { mess -> Bool in
            return mess.id == message.id
        })
        if( !contained ) {
            messages.append(message)
        }
    }
    func saveGroup(group: Group) {
        groups.append(group)
    }
    func addUserToGroup(group: Group, user: User, by: User) {
        groupUserFolder.entries.append((user_id: user.id, group_id: group.id))
    }
    
    func addUserToFriends(user: User, friend: User) {
        // TODO
    }
    
    func saveConversationThread(conversationThread: ConversationThread) {
        conversations.append(conversationThread)
    }
    func saveActivity(activity: UserActivity) {
        user_activities.append(activity)
    }
    func saveActivity(activity: GroupActivity) {
        group_activities.append(activity)
    }
    func saveDecorationThemes(themes: [DecorationTheme]) {
        // TODO
    }
    func saveDecorationStamps(stamps: [DecorationStamp]) {
        // TODO
    }
    
    func setupNotifications(cthread: ConversationThread, groupId: RecordId) {
    }
    func removeConversationThreadNotification(cthreadId: RecordId) {
    }
    
    func setupNotifications(groupId: RecordId) {
    }
    func setupNotifications(userId: RecordId)  {
    }
    
    func didReceiveNotification(userInfo: [AnyHashable : Any], views: [ModelView]) {
    }
    func setAppBadgeNumber(number: Int) {
    }
    func setAsUser(user: User) {
    }
    func isCreatedByUser(record: RecordId) -> Bool {
        return false
    }
    
    func deleteRecord(record: RecordId, completion: @escaping () -> Void) {
    }
    
    func deleteGroup(group: Group, completion: @escaping () -> ()) {
    }
    
    func deleteConversation(cthread: ConversationThread, messages: [Message], user: User, completion: @escaping () -> ()) {
    }
    
    func deleteOldMessages(olderThan: Date, user: User, completion: @escaping () -> ()) {
    }
    
    func deleteOldConversationThread(olderThan: Date, user: User, completion: @escaping () -> ()) {
    }
    
    func deleteIrrelevantInvitations(olderThan: Date, user: User, completion: @escaping () -> ()) {
    }
    
    func deleteOldMessageRecords(olderThan: Date, user: User, completion: @escaping () -> ()) {
    }
    
    func setMessageFetchTimeLimit(numberOfDays: TimeInterval) {
        
    }
    
}

