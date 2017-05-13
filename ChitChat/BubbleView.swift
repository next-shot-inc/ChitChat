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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func draw(_ rect: CGRect) {
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
        let size = self.bounds.size
        
        context.translateBy(x: size.width, y: size.height/2)
        context.scaleBy(x: size.width/27, y: size.height/26)
        
        context.move(to: CGPoint(x: -0.25, y: -1))
        var curPoint = context.currentPointOfPath
        for i in 0 ..< points.count/3 {
           context.addCurve(to: curPoint + points[i*3+2], control1: curPoint + points[i*3], control2: curPoint + points[i*3+1])
            curPoint = context.currentPointOfPath
        }
        context.setLineWidth(2/size.width*26)
        context.closePath()
        
        let path = context.path!
        if( strokeColor != nil ) {
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
}
