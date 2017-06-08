//
//  FriendsAndGroup.swift
//  ChitChat
//
//  Created by next-shot on 6/7/17.
//  Copyright © 2017 next-shot. All rights reserved.
//

import Foundation
import UIKit

class FriendsAndGroup {
    var groups_received = 0
    let groups : [Group]
    let completion : (([User]) -> Void)
    
    init(groups: [Group], completion: @escaping ([User]) -> Void) {
        self.groups = groups
        self.completion = completion
        for group in groups {
            model.getUsersForGroup(group: group, completion: self.getGroupUsers)
        }
    }
    
    func getGroupUsers(users: [User]) {
        DispatchQueue.main.async(execute: {
            self.groups_received += 1
            if( self.groups.count == self.groups_received ) {
                let silent_friends = self.analyze_groups_and_friends()
                self.completion(silent_friends)
            }
        })
    }
    
    func analyze_groups_and_friends() -> [User] {
        var friends = [User]()
        var private_groups = [RecordId:Group]()
        let me = model.me()

        for group in groups {
            let users = model.getUsers(group: group)
            for user in users {
                if( user.id == model.me().id ) {
                    continue
                }
                let contained = friends.contains(where: { (friend) -> Bool in
                    return friend.id == user.id
                })
                if( !contained ) {
                    friends.append(user)
                }
            }
            if( users.count == 2 && group.name == "%%Symetric%%" ) {
                let other = users.first!.id == me.id ? users.last! : users.first!
                private_groups[other.id] = group
            }
        }
        
        var silent_friends = [User]()
        for friend in friends {
            let grp = private_groups[friend.id]
            if( grp == nil ) {
                silent_friends.append(friend)
            }
        }
        return silent_friends
    }
    
    func createGroup(user: User) -> Group {
        // Create Group
        let group = Group(id: RecordId(), name: "%%Symetric%%")
        group.details = (user.label ?? " ") + "%%" + (model.me().label ?? " ")
        
        let groupActivity = GroupActivity(group_id: group.id)
        model.saveActivity(groupActivity: groupActivity)
        group.activity_id = groupActivity.id
        
        model.saveGroup(group: group)
        
        model.addUserToGroup(group: group, user: user)
        model.addUserToGroup(group: group, user: model.me())
        
        // Create default thread
        let cthread = ConversationThread(id: RecordId(), group_id: group.id, user_id: model.me().id)
        cthread.title = "Main"
        model.saveConversationThread(conversationThread: cthread)
        
        // Create first message
        let message = Message(thread: cthread, user: model.me())
        message.text = "Hello"
        model.saveMessage(message: message, completion:  {})
        
        return group
    }
    
    class func isPair(group: Group) -> Bool {
        return group.name == "%%Symetric%%"
    }
    
    class func getName(group: Group) -> String {
        if( isPair(group: group) ) {
            let users = model.getUsers(group: group)
            let me = model.me()
            if( users.count == 2 ) {
                let other = users.first!.id == me.id ? users.last! : users.first!
                return other.label ?? " "
            } else {
                let detail = group.details
                let split = detail.components(separatedBy: "%%")
                if( me.label != nil && split.count == 2 ) {
                    return split[0] == me.label ? split[1] : split[0]
                } else {
                    return " "
                }
            }
        } else {
            return group.name
        }
    }
    
    class func getIcon(group: Group) -> UIImage? {
        if( isPair(group: group) ) {
            let users = model.getUsers(group: group)
            let me = model.me()
            if( users.count == 2 ) {
                let other = users.first!.id == me.id ? users.last! : users.first!
                return other.icon ?? UIImage(named: "user_male3-32")
            } else {
                return UIImage(named: "user_male3-32")
            }
        } else {
            return group.icon
        }
    }
}
