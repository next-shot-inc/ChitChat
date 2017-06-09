//
//  BubbleView.swift
//  ChitChat
//
//  Created by next-shot on 5/11/17.
//  Copyright © 2017 next-shot. All rights reserved.
//

import Foundation
import UIKit

public func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

public func += ( left: inout CGPoint, right: CGPoint) {
    left = left + right
}

@IBDesignable
class BubbleView : UIView {
    @IBInspectable var fillColor : UIColor?
    @IBInspectable var strokeColor: UIColor?
    @IBInspectable var forceStretch : Bool = false
    var strokeWidth : CGFloat = 2.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func draw(_ rect: CGRect) {
        let size = self.bounds.size
        var ratio = size.width/size.height
        if( ratio > 1 ) {
            ratio = 1/ratio
        }
        if( ratio < 0.8 || forceStretch ) {
            draw_stretch_aspect()
        } else {
            draw_keep_aspect_ratio()
        }
    }
    
    func draw_keep_aspect_ratio() {
        // SVG Path definition: c dcx1,dcy1 dcx2,dcy2, dx,dy
        // dc1x,dc1y, dc2x,dc2y are all relative to the initial point, not the end point. dx and dy are the distance to the right and down, respectively.
        // dc1x,dc1y, dc2x,dc2y are control points for the initial point and end point
        let coords : [Float] = [0,6.2958, -5.91,11.4, -13.2,11.4, -1.2456,0, -2.451,-0.1488, -3.594,-0.4272, 0,0, -2.2842,2.8434, -6.006,2.8272, 1.8006,-2.5548, 1.7976,-4.6038, 1.7976,-4.6038, -3.273,-2.0748, -5.3976,-5.421, -5.3976,-9.1962, 0,-6.2958, 5.9094,-11.4, 13.2,-11.4, 7.29,0, 13.2,5.1042, 13.2,11.4]
        
        var points = [CGPoint](repeating: CGPoint(), count: coords.count/2)
        for i in 0..<coords.count/2 {
            points[i] = CGPoint(x: CGFloat(coords[i*2]), y: CGFloat(coords[i*2+1]))
        }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        context.saveGState()
        var size = self.bounds.size
        size.width -= 3
        size.height -= 3
        
        context.translateBy(x: size.width, y: size.height/2)
        
        let sx = size.width/27.5
        let sy = size.height/26
        let sc = min(sx, sy)
        context.scaleBy(x: sx, y: sy)
        
        context.move(to: CGPoint(x: -0.5, y: -1))
        var curPoint = context.currentPointOfPath
        for i in 0 ..< points.count/3 {
           context.addCurve(to: curPoint + points[i*3+2], control1: curPoint + points[i*3], control2: curPoint + points[i*3+1])
            curPoint = context.currentPointOfPath
        }
        context.setLineWidth(strokeWidth/sc)
        context.closePath()
        
        let path = context.path!
        if( strokeColor != nil ) {
            context.setStrokeColor(strokeColor!.cgColor)
            context.strokePath()
            context.setShadow(offset: CGSize(width: 3, height: 3), blur: 5)
            context.addPath(path)
            context.setFillColor(UIColor.white.cgColor)
            context.fillPath()
        }
        
        if( fillColor != nil ) {
            context.addPath(path)

            //2 - get the current context
            let colors = [fillColor!.cgColor, UIColor.white.cgColor]
            
            //3 - set up the color space
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            
            //4 - set up the color stops
            let colorLocations:[CGFloat] = [0.0, 1.0]
            
            //5 - create the gradient
            let gradient = CGGradient(colorsSpace: colorSpace,colors: colors as CFArray, locations: colorLocations)
            
            context.clip()
            
            //6 - draw the gradient
            let startPoint = CGPoint(x:-27, y: 0)
            let endPoint = CGPoint(x: 0, y:0)
            context.drawLinearGradient(
                gradient!, start: startPoint, end: endPoint, options: CGGradientDrawingOptions(rawValue: 0)
            )

            
            //context.setFillColor(fillColor!.cgColor)
            //context.fillPath()
        }
        context.restoreGState()
    }
    
    func draw_stretch_aspect() {
        let curve1 : [CGFloat]  = [-1.2456,0, -2.186169,-0.1488, -3.329169,-0.4272, 0,0, -2.2842,2.8434, -6.006,2.8272, 1.8006,-2.5548, 1.7976,-4.6038, 1.7976,-4.6038, -3.273,-2.0748, -5.3976,-5.421, -5.3976,-9.1962]
        let seg1 : [CGFloat] = [0,-0.582623]
        let curve2 : [CGFloat] = [0,-6.2958, 5.803468,-10.870339, 13.094068,-10.870339]
        let seg2 : [CGFloat] = [0.635593,0]
        let curve3 : [CGFloat] = [7.29,0, 12.723305,4.64591, 12.723305,11.505932]
        let seg3 : [CGFloat] = [0,0.370763]
        let curve4 : [CGFloat] = [0,6.2958, -5.454693,10.763724, -12.744693,10.763724]
        
        let size = self.bounds.size
        let sx = size.width/27
        let sy = size.height/26
        let sc = min(sx, sy)
        
        let tx = sc == sx ? size.width/2 : 13*sc+2
        let ty = size.height
        
        var p = sc == sx ? CGPoint(x: 0, y: -4) : CGPoint(x: 0, y: -2.8)
        p.x = p.x * sc + tx
        p.y = p.y * sc + ty
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        context.move(to: p)
        
        func drawCurve(curve: [CGFloat]) {
            for i in 0 ..< curve.count/6 {
                var to = CGPoint(x: curve[i*6 + 4], y: curve[i*6 + 5])
                to.x = to.x * sc + p.x
                to.y = to.y * sc + p.y
                var c1 = CGPoint(x: curve[i*6 + 0], y: curve[i*6 + 1])
                c1.x = c1.x * sc + p.x
                c1.y = c1.y * sc + p.y
                var c2 = CGPoint(x: curve[i*6 + 2], y: curve[i*6 + 3])
                c2.x = c2.x * sc + p.x
                c2.y = c2.y * sc + p.y
                
                context.addCurve(to: to, control1: c1, control2:  c2)
                p = context.currentPointOfPath
            }
        }
        
        // bottom left corner (including the bubble anchor)
        drawCurve(curve: curve1)
        
        // left vertical connecting line
        if( sc == sx ) {
            p.y -= (size.height - size.width)
        }
        context.addLine(to: p)
        
        // top left corner
        drawCurve(curve: curve2)
        
        // top horizontal connecting line
        if( sc == sy ) {
            p.x += (size.width - size.height - 10)
        }
        context.addLine(to: p)
        
        // top right corner
        drawCurve(curve: curve3)
        
        // right vertical connecting line
        if( sc == sx ) {
            p.y += (size.height - size.width)
        }
        context.addLine(to: p)
        
        // bottom right corner
        drawCurve(curve: curve4)
        
        // bottom horizontal connecting line
        if( sc == sy ) {
            p.x -= (size.width - size.height - 10)
        }
        context.addLine(to: p)
        
        context.closePath()
        
        let path = context.path!
        if( strokeColor != nil ) {
            context.setLineWidth(strokeWidth)

            context.setStrokeColor(strokeColor!.cgColor)
            context.strokePath()
        }

        if( fillColor != nil ) {
            context.addPath(path)
            
            //2 - get the current context
            let colors = [fillColor!.cgColor, UIColor.white.cgColor]
            
            //3 - set up the color space
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            
            //4 - set up the color stops
            let colorLocations:[CGFloat] = [0.0, 1.0]
            
            //5 - create the gradient
            let gradient = CGGradient(colorsSpace: colorSpace,colors: colors as CFArray, locations: colorLocations)
            
            context.clip()
            
            //6 - draw the gradient
            let startPoint = CGPoint(x:0, y: 0)
            let endPoint = CGPoint(x: size.width, y:0)
            context.drawLinearGradient(
                gradient!, start: startPoint, end: endPoint, options: CGGradientDrawingOptions(rawValue: 0)
            )
        }

    }
}
