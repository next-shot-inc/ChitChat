//
//  User+CoreDataProperties.swift
//  ChitChat
//
//  Created by next-shot on 3/8/17.
//  Copyright © 2017 next-shot. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension UserInfo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserInfo> {
        return NSFetchRequest<UserInfo>(entityName: "UserInfo");
    }

    @NSManaged public var name: String?
    @NSManaged public var telephoneNumber: String?
    @NSManaged public var photo: NSData?

}
