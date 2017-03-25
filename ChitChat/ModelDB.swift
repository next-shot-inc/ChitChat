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
    func getUser(userId: RecordId, completion: @escaping (User) -> ())
    func getUser(phoneNumber: String, completion: @escaping (User?) -> ())
    func getActivities(userId: RecordId, completion: @escaping ([UserActivity]) -> ())
    func getActivity(userId: RecordId, threadId: RecordId, completion: @escaping (UserActivity?) -> ())
    func getActivityForGroup(groupId: RecordId, completion: @escaping (GroupActivity?) -> ())
    func getActivitiesForGroups(groups: [Group], completion: @escaping ([GroupActivity]) -> ())
    func getDecorationThemes(completion: @escaping ([DecorationTheme]) -> ())
    func getDecorationStamps(theme: DecorationTheme, completion: @escaping ([DecorationStamp]) -> ())
    func setMessageFetchTimeLimit(numberOfDays: TimeInterval)
    
    func saveUser(user: User)
    func saveMessage(message: Message, completion: @escaping () -> ())
    func saveGroup(group: Group)
    func saveActivity(activity: GroupActivity)
    func addUserToGroup(group: Group, user: User)
    func saveConversationThread(conversationThread: ConversationThread)
    func saveActivity(activity: UserActivity)
    func saveDecorationThemes(themes: [DecorationTheme])
    func saveDecorationStamps(stamps: [DecorationStamp])
    
    func setupNotifications(cthread: ConversationThread)
    func setupNotifications(groupId: RecordId)
    func setupNotifications(userId: RecordId)
    func didReceiveNotification(userInfo: [AnyHashable : Any], views: [ModelView])
    func setAppBadgeNumber(number: Int)
    
    func setAsUser(user: User)
    func isCreatedByUser(record: RecordId) -> Bool
    
    func deleteRecord(record: RecordId, completion: @escaping () -> Void)
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
    }
    func getDecorationThemes(completion: @escaping ([DecorationTheme]) -> ()) {
    }
    
    func saveUser(user: User) {
        let already = users.contains(where: ({ (u) -> Bool in
            user.id == u.id
        }))
        if( !already ) {
            users.append(user)
        }
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
    func addUserToGroup(group: Group, user: User) {
        groupUserFolder.entries.append((user_id: user.id, group_id: group.id))
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
        
    }
    func saveDecorationStamps(stamps: [DecorationStamp]) {
    }
    
    func setupNotifications(cthread: ConversationThread) {
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
    
    func setMessageFetchTimeLimit(numberOfDays: TimeInterval) {
        
    }
}

