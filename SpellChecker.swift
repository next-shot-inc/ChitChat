//
//  SpellChecker.swift
//  ChitChat
//
//  Created by next-shot on 3/11/17.
//  Copyright © 2017 next-shot. All rights reserved.
//

import Foundation
import UIKit

// https://languagetool.org/http-api/languagetool-swagger.json

// JSon example
// {
//  "software":{"name":"LanguageTool","version":"3.7-SNAPSHOT","buildDate":"2017-03-08 21:01","apiVersion":"1","status":""},
//  "warnings":{"incompleteResults":false},"language":{"name":"English (US)","code":"en-US"},
//  "matches":[
//    {"message":"This sentence does not start with an uppercase letter",
//        "shortMessage":"",
//        "replacements":[{"value":"A"}],"offset":1,"length":1,
//        "context":{"text":"\"a text with many error\"","offset":1,"length":1},
//        "rule":{"id":"UPPERCASE_SENTENCE_START","description":"Checks that a sentence starts with an uppercase letter","issueType":"typographical","category":{"id":"CASING","name":"Capitalization"}}
//    },
//    {"message":"Possible agreement error. The noun error seems to be countable; consider using: \"many errors\".",
//        "shortMessage":"Grammatical problem",
//        "replacements":[{"value":"many errors"}],
//        "offset":13,"length":10,
//        "context":{"text":"\"a text with many error\"","offset":13,"length":10},
//        "rule":{"id":"MANY_NN","subId":"1","description":"Possible agreement error: 'many/several/few' + singular countable noun","issueType":"grammar","category":{"id":"GRAMMAR","name":"Grammar"}}
//    },
//    {"message":"Possible spelling mistake found",
//        "shortMessage":"Spelling mistake",
//        "replacements":[{"value":"many"},{"value":"men"},{"value":"deny"},{"value":"menu"},{"value":"mend"},{"value":"Meany"},{"value":"meany"},{"value":"men y"}],
//        "offset":13,"length":4,"
//         context":{"text":"\"a text with meny error\"","offset":13,"length":4},
//         "rule":{"id":"MORFOLOGIK_RULE_EN_US","description":"Possible spelling mistake","issueType":"misspelling","category":{"id":"TYPOS","name":"Possible Typo"}}
//    }
//    ]
// }

class SpellChecker {
    let textView: UITextView?
    let gtextView: GrowingTextView?
    
    init(textView: UITextView) {
        self.textView = textView
        self.gtextView = nil
    }
    init(textView: GrowingTextView) {
        self.gtextView = textView
        self.textView = nil
    }
    
    func text() -> String {
       if( textView != nil ) {
           return textView!.text!
       } else {
           return gtextView!.text!
       }
    }
    
    func font() -> UIFont {
        if( textView != nil ) {
            return textView!.font!
        } else {
            return gtextView!.font!
        }
    }
    
    func set(text: NSAttributedString) {
        if( textView != nil ) {
            textView!.attributedText = text
        } else {
            gtextView!.attributedText = text
        }
    }
    
    func lang() -> String? {
        if( textView != nil ) {
            return textView!.textInputMode?.primaryLanguage
        } else {
            return gtextView!.textInputMode?.primaryLanguage
        }
    }
    
    func check(completion: @escaping (_ nb_errors: Int) -> ()) {
        // Check keyboard language against supported languages.
        let supportedLanguages = [
            "ast-ES", "be-BY", "br-FR", "ca-ES", "ca-ES-valencia", "da-DK",
            "de", "de-AT", "de-CH", "de-DE", "el-GR", "en", "en-AU", "en-CA", "en-GB", "en-NZ", "en-US", "en-ZA",
            "eo", "es", "fa", "fr", "gl-ES", "it", "ja-JP", "km-KH", "nl",
            "pl-PL", "pt", "pt-AO", "pt-BR", "pt-MZ", "pt-PT", "ro-RO", "ru-RU",
            "sk-SK", "sl-SI", "sv", "ta-IN", "tl-PH", "uk-UA", "zh-CN", "auto"
        ]
        
        var lang = self.lang() ?? "auto"
        if( !supportedLanguages.contains(lang) ) {
            // Try without the extansion
            let firstDash = lang.characters.index(of: "-")
            if( firstDash != nil ) {
                lang = lang.substring(to: firstDash!)
                if( !supportedLanguages.contains(lang) ) {
                    lang = "auto"
                }
            }
        }
    
        //1
        let urlAsString = "https://languagetool.org/api/v2/check?language=\(lang)&text="
        let encodedString = text().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let fullURLString = urlAsString + encodedString!
        
        let url = URL(string: fullURLString)!
        let urlSession = URLSession.shared
        
        //2
        let task = urlSession.dataTask(
            with: url,
            completionHandler: { data, response, error -> Void in
                if (error != nil || data == nil ) {
                    print(error!.localizedDescription)
                } else {
                    var jsonResult : Any?
                    do {
                        try jsonResult = JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers)
                    } catch {
                        jsonResult = nil
                        print("JSON Error")
                    }
                    
                    if( jsonResult != nil && jsonResult is NSDictionary ) {
                        let string = self.text()
                        let astring = NSMutableAttributedString(
                            string: string,
                            attributes: [NSFontAttributeName: self.font()]
                        )
                        
                        let misspellAttributes = [
                            NSUnderlineStyleAttributeName: NSNumber(value: NSUnderlineStyle.styleSingle.rawValue),
                            NSUnderlineColorAttributeName: UIColor.blue
                        ] as [String : Any]
                        
                        let badgrammarAttributes = [
                            NSUnderlineStyleAttributeName: NSNumber(value: NSUnderlineStyle.styleThick.rawValue),
                            NSUnderlineColorAttributeName: UIColor.red
                        ] as [String : Any]
                    
                        let jsonMessage = jsonResult! as! NSDictionary
                        let jsonMatchArray = jsonMessage["matches"] as! NSArray
                        for i in 0..<jsonMatchArray.count {
                            let jsonDict = jsonMatchArray[i] as! NSDictionary
                            let rule = jsonDict["rule"] as! NSDictionary
                            let issueType = rule["issueType"] as! NSString
                            let offset = jsonDict["offset"] as! Int
                            let length = jsonDict["length"] as! Int
                            
                            let range = NSRange(location: offset, length: length)
                            if( issueType == "misspelling" ) {
                                astring.addAttributes(misspellAttributes, range: range)
                            } else {
                                astring.addAttributes(badgrammarAttributes, range: range)
                            }
                        }
                        
                        DispatchQueue.main.async(execute: {
                            self.set(text: astring)
                            completion(jsonMatchArray.count)
                        })
                    }
                }
        })
        task.resume()
    }
}
