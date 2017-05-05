//
//  Utilities.swift
//  ChitChat
//
//  Created by next-shot on 3/8/17.
//  Copyright © 2017 next-shot. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

typealias GradientPoints = (startPoint: CGPoint, endPoint: CGPoint)

enum GradientOrientation {
    case topRightBottomLeft
    case topLeftBottomRight
    case horizontal
    case vertical
    
    var startPoint : CGPoint {
        get { return points.startPoint }
    }
    
    var endPoint : CGPoint {
        get { return points.endPoint }
    }
    
    var points : GradientPoints {
        get {
            switch(self) {
            case .topRightBottomLeft:
                return (CGPoint.init(x: 0.0,y: 1.0), CGPoint.init(x: 1.0,y: 0.0))
            case .topLeftBottomRight:
                return (CGPoint.init(x: 0.0,y: 0.0), CGPoint.init(x: 1,y: 1))
            case .horizontal:
                return (CGPoint.init(x: 0.0,y: 0.5), CGPoint.init(x: 1.0,y: 0.5))
            case .vertical:
                return (CGPoint.init(x: 0.0,y: 0.0), CGPoint.init(x: 0.0,y: 1.0))
            }
        }
    }
}

extension UIView {
    
    func applyGradient(withColours colours: [UIColor], locations: [NSNumber]? = nil) -> Void {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = self.bounds
        gradient.colors = colours.map { $0.cgColor }
        gradient.locations = locations
        self.layer.insertSublayer(gradient, at: 0)
    }
    
    func applyGradient(withColours colours: [UIColor], gradientOrientation orientation: GradientOrientation) -> Void {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = self.bounds
        gradient.colors = colours.map { $0.cgColor }
        gradient.startPoint = orientation.startPoint
        gradient.endPoint = orientation.endPoint
        self.layer.insertSublayer(gradient, at: 0)
    }
}

extension UIImage {
    func resize(newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        let context = UIGraphicsGetCurrentContext()
        
        // Set the quality level to use when rescaling
        context!.interpolationQuality = CGInterpolationQuality.high
        self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // Get the resized image from the context and a UIImage
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}

class ColorPalette {
    enum States : String {
        case unreadHighImportance, unread, mine, borderColor, read, unsent
    }
    // Red
    static let all_colors : [[States:UIColor]] = [[
        .unreadHighImportance : UIColor(red: 253/256, green: 83/256, blue: 66/255, alpha: 1.0),
        .unread : UIColor(red: 244/256, green: 117/256, blue: 107/256, alpha: 1.0),
        .mine : UIColor(red: 247/256, green: 195/256, blue: 195/256, alpha: 1.0),
        .borderColor : UIColor(red: 226/256, green: 66/256, blue: 77/256, alpha: 1.0),
        .read : UIColor(red: 255/256, green: 236/256, blue: 237/256, alpha: 1.0),
        .unsent: UIColor(red: 220/256, green: 220/256, blue: 220/256, alpha: 1.0)
    ],
    // Green
    [
        .unreadHighImportance : UIColor(red: 253/256, green: 83/256, blue: 66/255, alpha: 1.0),
        .unread : UIColor(red: 143/256, green: 192/256, blue: 169/256, alpha: 1.0),
        .mine : UIColor(red: 165/256, green: 211/256, blue: 171/256, alpha: 1.0),
        .borderColor : UIColor(red: 74/256, green: 124/256, blue: 89/256, alpha: 1.0),
        .read : UIColor(red: 200/256, green: 213/256, blue: 185/256, alpha: 1.0),
        .unsent: UIColor(red: 220/256, green: 220/256, blue: 220/256, alpha: 1.0)
    ],
    // Blue
    [
        .unreadHighImportance : UIColor(red: 230/256, green: 57/256, blue: 70/255, alpha: 1.0),
        .unread : UIColor(red: 168/256, green: 218/256, blue: 220/256, alpha: 1.0),
        .mine : UIColor(red: 111/256, green: 160/256, blue: 192/256, alpha: 1.0),
        .borderColor : UIColor(red: 29/256, green: 53/256, blue: 87/256, alpha: 1.0),
        .read : UIColor(red: 201/256, green: 248/256, blue: 238/256, alpha: 1.0),
        .unsent: UIColor(red: 220/256, green: 220/256, blue: 220/256, alpha: 1.0)
    ]
    ]

    static var cur = 2
    
    static var colors : [States:UIColor] {
        get {
            return all_colors[cur]
        }
    }
    
    class func backgroundColor(message: Message) -> UIColor {
        if( message.user_id.id == model.me().id.id ) {
            if( message.unsaved() ) {
                return all_colors[cur][.unsent]!
            } else {
                return all_colors[cur][.mine]!
            }
        } else {
            let activity = model.getMyActivity(threadId: message.conversation_id)
            if( activity == nil || activity!.last_read < message.last_modified ) {
                return all_colors[cur][.unread]!
            }
        }
        return all_colors[cur][.read]!
    }
}
