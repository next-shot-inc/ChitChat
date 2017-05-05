//
//  MessageOptions.swift
//  ChitChat
//
//  Created by next-shot on 3/18/17.
//  Copyright © 2017 next-shot. All rights reserved.
//

import Foundation

// 
// {
//    type : "decoratedImage" or "decoratedText" or "poll" or "thumb-up"
//    version : "1.0"
//
// }

class MessageOptions {
    var version : String = "1.0"
    var type : String
    var decorated : Bool = false
    var theme = String()
    var pollOptions = [String]()
    var pollRecord : PollRecord?
    
    init(type: String) {
        self.type = type
    }
    
    init(options: String) {
        type = "unknown"
        if( options.isEmpty ) {
            return
        }
        
        var jsonResult : Any?
        do {
            try jsonResult = JSONSerialization.jsonObject(
                with: options.data(using: String.Encoding.utf8)!,
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
            decorated = (jsonMessage["decorated"] as! NSNumber) as! Bool
            
            let rawTheme = jsonMessage["theme"]
            if( rawTheme != nil ) {
               theme = (jsonMessage["theme"] as! NSString) as String
            }
            
            let jsonPollOptions = jsonMessage["pollOptions"] as? NSArray
            if( jsonPollOptions != nil ) {
                for opt in jsonPollOptions! {
                    pollOptions.append((opt as! NSString) as String)
                }
            }
        }
    }
    
    func getString() -> String? {
        let dict = NSMutableDictionary()
        dict.setValue(NSString(string: type),  forKey: "type")
        dict.setValue(NSString(string: version), forKey:  "version")
        dict.setValue(NSNumber(value: decorated), forKey: "decorated")
        dict.setValue(NSString(string: theme), forKey: "theme")
        
        if( pollOptions.count > 0 ) {
            let array = NSMutableArray()
            for opt in pollOptions {
                array.add(NSString(string: opt))
            }
            dict.setValue(array, forKey: "pollOptions")
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: dict, options: [])
            return String(data: data, encoding: String.Encoding.utf8)
        } catch {
            return nil
        }
    }
}
