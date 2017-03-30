//
//  ResourceDB.swift
//  ChitChat
//
//  Created by next-shot on 3/21/17.
//  Copyright © 2017 next-shot. All rights reserved.
//

import Foundation
import UIKit

class ResourceCatalog {
    var pictures = [String: [String]]()
    func append(theme: String, names: [String]) {
        pictures[theme] = names
    }
}

// The current catalog contains the images loaded in xassets.
// Typically these are temporarely loaded, to xfer to the DB
// This file also maintains the history of what has been loaded where.

class ResourceDB {
    private var developmentResourceCatalog1_0 = ResourceCatalog()
    private var developmentResourceCatalog1_1 = ResourceCatalog()
    private var developmentResourceCatalog1_2 = ResourceCatalog()
    init() {
        init1_2()
    }
    
    func init1_0() {
        var names : [String]
        names = ["rose", "bluebell", "sunflower", "daffodil", "wallflower"]
        developmentResourceCatalog1_0.append(theme: "flowers", names: names)
        
        names = ["clover32x32"]
        developmentResourceCatalog1_0.append(theme: "clovers", names: names)
        
        names = ["heart", "hearts"]
        developmentResourceCatalog1_0.append(theme: "hearts", names: names)
        
        names = ["musicnote1"]
        developmentResourceCatalog1_0.append(theme: "music notes", names: names)
        
        names = ["easter-egg-1", "easter-egg-2", "easter-egg-3", "easter-egg-4", "easter-egg-5"]
        developmentResourceCatalog1_0.append(theme: "easter", names: names)
    }
    
    func init1_1() {
        var names : [String]
        names = ["balloons", "cupcake", "fireworks", "birthday-cake", "candles", "cake"]
        developmentResourceCatalog1_1.append(theme: "birthday", names: names)
        
        names = ["confetti", "confetti-2", "celebration", "champagne", "candles", "garlands"]
        developmentResourceCatalog1_1.append(theme: "celebration", names: names)
        
        names = ["tree", "bird", "grass", "flower", "sun", "leaf"]
        developmentResourceCatalog1_1.append(theme: "spring", names: names)
    }
    
    func init1_2() {
        var names : [String]
        names = ["mountains", "lemonade", "sailboat", "sun-umbrella", "sunset", "butterfly"]
        developmentResourceCatalog1_2.append(theme: "summer", names: names)
        
        names = ["ice-cream", "ice-cream-2", "ice-cream-3", "ice-cream-4", "ice-cream-5", "ice-cream-6"]
        developmentResourceCatalog1_2.append(theme: "ice cream", names: names)
    }
    
    var currentCatalog : ResourceCatalog {
        get {
            return developmentResourceCatalog1_2
        }
    }
    
    func save(catalog: ResourceCatalog) {
        if( catalog.pictures.count == 0 ) {
            return
        }
        var themes = [DecorationTheme]()
        for v in catalog.pictures {
            let theme = DecorationTheme(name: v.key)
            themes.append(theme)
        }
        model.db_model.saveDecorationThemes(themes: themes)
        
        var stamps = [DecorationStamp]()
        for (i,v) in catalog.pictures.enumerated() {
            for n in v.value {
                let image = UIImage(named: n)
                if( image != nil ) {
                    let stamp = DecorationStamp(theme: themes[i].id, image: image!)
                    stamps.append(stamp)
                }
            }
        }

        model.db_model.saveDecorationStamps(stamps: stamps)
    }
}
