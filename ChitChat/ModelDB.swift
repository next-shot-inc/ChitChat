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
    
    func saveUser(user: User)
    func saveMessage(message: Message)
    func saveGroup(group: Group)
    func addUserToGroup(group: Group, user: User)
    func saveConversationThread(conversationThread: ConversationThread)
    func saveActivity(activity: UserActivity)
    
    func setupNotifications(cthread: ConversationThread)
    func setupNotifications(groupId: RecordId)
    func didReceiveNotification(userInfo: [AnyHashable : Any], views: [ModelView])
    func setAppBadgeNumber(number: Int)
}

/***************************************************************************************/

class InMemoryDB : DBProtocol {
    internal var users = [User]()
    internal var groups = [Group]()
    internal var conversations = [ConversationThread]()
    internal var messages = [Message]()
    internal var activities = [UserActivity]()
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
        completion(activities)
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
        for a in activities {
            if( a.user_id.id == userId.id && a.thread_id.id == threadId.id ) {
                return completion(a)
            }
        }
        return completion(nil)
    }
    
    func saveUser(user: User) {
        let already = users.contains(where: ({ (u) -> Bool in
            user.id == u.id
        }))
        if( !already ) {
            users.append(user)
        }
    }
    func saveMessage(message: Message) {
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
        activities.append(activity)
    }
    
    func setupNotifications(cthread: ConversationThread) {
    }
    func setupNotifications(groupId: RecordId) {
    }
    func didReceiveNotification(userInfo: [AnyHashable : Any], views: [ModelView]) {
    }
    func setAppBadgeNumber(number: Int) {
    }
}

