//
//  DecoratedImageView.swift
//  ChitChat
//
//  Created by next-shot on 3/24/17.
//  Copyright © 2017 next-shot. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class DecoratedImageView : UIView {
    @IBInspectable var frameSize : CGFloat = 10
    @IBInspectable var backgroundImage : UIImage?
    @IBInspectable var image : UIImage?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        if( image == nil ) {
            return
        }
        
        let imageSize = image!.size
        let sx = bounds.width/imageSize.width
        let sy = bounds.height/imageSize.height
        let sc = min(sx, sy)
        let imageScaledSize = CGSize(width: imageSize.width*sc, height: imageSize.height*sc)
        let imageScaledRect = CGRect(x: (bounds.width - imageScaledSize.width)/2,
                                     y: (bounds.height - imageScaledSize.height)/2,
                                     width: imageScaledSize.width, height: imageScaledSize.height)
        
        if( frameSize == 0 ) {
            self.image?.draw(in: imageScaledRect)
            return
        }
        
        let shadowSize: CGFloat = 2
        let allRect = CGRect(x: imageScaledRect.origin.x, y: imageScaledRect.origin.y,
                             width: imageScaledSize.width - shadowSize,
                             height: imageScaledSize.height - shadowSize)
        
        let limitedRect = CGRect(x: imageScaledRect.origin.x + frameSize + shadowSize,
                                 y: imageScaledRect.origin.y + frameSize + shadowSize,
                                 width: imageScaledSize.width - 2*frameSize - 2*shadowSize,
                                 height: imageScaledSize.height - 2*frameSize - 2*shadowSize)
        
        if( backgroundImage != nil ) {
            let bgI = backgroundImage!.cgImage
            if( bgI != nil ) {
                let frameRect = CGRect(x: imageScaledRect.origin.x,
                                       y: imageScaledRect.origin.y,
                                       width: imageScaledSize.width - shadowSize,
                                       height:imageScaledSize.height - shadowSize)
                context.saveGState()
                context.clip(to: frameRect)
                let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: frameRect.height)
                context.concatenate(flipVertical)
                context.draw(bgI!, in: CGRect(origin:
                        CGPoint(x: backgroundImage!.size.width*CGFloat(drand48()),
                                y: backgroundImage!.size.height*CGFloat(drand48())),
                        size: backgroundImage!.size), byTiling: true
                )
                context.restoreGState()
            }
            context.setFillColor(UIColor.white.cgColor)
            context.fill(limitedRect)
        }
        
        self.image?.draw(in: limitedRect)
        
        context.saveGState()
        context.setShadow(offset: CGSize(width: -1, height: -1), blur: 0.5)
        context.setLineWidth(0.5)
        context.setStrokeColor(UIColor.gray.cgColor)
        context.stroke(limitedRect)
        context.restoreGState()
        
        context.saveGState()
        context.setShadow(offset: CGSize(width: 1, height: 1), blur: 0.5)
        context.setLineWidth(0.5)
        context.setStrokeColor(UIColor.gray.cgColor)
        context.stroke(allRect)
        context.restoreGState()
    }

}
