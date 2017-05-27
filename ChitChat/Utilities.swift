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

class ColorPaletteUIView : UIView {
    var palette : Int?
    
    override func draw(_ rect: CGRect) {
        let size = self.bounds.size
        let colors = ColorPalette.all_colors[palette ?? ColorPalette.cur]
        let states : [ColorPalette.States] = [.unread, .mine, .read, .unsent]
        let dx = size.width/CGFloat(states.count)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        for i in 0 ..< states.count {
            context.setFillColor(colors[states[i]]!.cgColor)
            context.fill(CGRect(x: dx*CGFloat(i), y: 0, width: dx, height: size.height))
        }
    }
    
    func generateImage(rect: CGRect) -> UIImage? {
        let size = rect.size
        let colors = ColorPalette.all_colors[palette ?? ColorPalette.cur]
        let states : [ColorPalette.States] = [.unread, .mine, .read, .unsent]
        let dx = size.width/CGFloat(states.count)
        
        UIGraphicsBeginImageContext(rect.size)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        for i in 0 ..< states.count {
             context.setFillColor(colors[states[i]]!.cgColor)
             context.fill(CGRect(x: dx*CGFloat(i), y: 0, width: dx, height: size.height))
        }
        
        let image =  UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        return image
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
    
    func resize(newSize: CGSize, center: CGPoint) -> UIImage {
        let translation = CGPoint(x: center.x - size.width/2, y: center.y - size.height/2)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        let context = UIGraphicsGetCurrentContext()
        
        // Set the quality level to use when rescaling
        context!.interpolationQuality = CGInterpolationQuality.high
        let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height)
        context!.concatenate(flipVertical)
        
        let tx = translation.x/size.width*newSize.width
        let ty = translation.y/size.height*newSize.height
        context!.draw(self.cgImage!, in: CGRect(x: -tx, y: -ty, width: newSize.width - tx, height: newSize.height - ty))
        
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
        .unread : UIColor(red: 80/256, green: 140/256, blue: 113/256, alpha: 1.0),
        .mine : UIColor(red: 143/256, green: 192/256, blue: 169/256, alpha: 1.0),
        .borderColor : UIColor(red: 74/256, green: 124/256, blue: 89/256, alpha: 1.0),
        .read : UIColor(red: 208/256, green: 229/256, blue: 219/256, alpha: 1.0),
        .unsent: UIColor(red: 220/256, green: 220/256, blue: 220/256, alpha: 1.0)
    ],
    // Blue
    [
        .unreadHighImportance : UIColor(red: 230/256, green: 57/256, blue: 70/255, alpha: 1.0),
        .unread : UIColor(red: 72/256, green: 127/256, blue: 164/256, alpha: 1.0),
        .mine : UIColor(red: 133/256, green: 176/256, blue: 202/256, alpha: 1.0),
        .borderColor : UIColor(red: 29/256, green: 53/256, blue: 87/256, alpha: 1.0),
        .read : UIColor(red: 220/256, green: 232/256, blue: 240/256, alpha: 1.0),
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
        if( message.user_id == model.me().id ) {
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
