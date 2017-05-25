//
//  DrawingTextView.swift
//  ChitChat
//
//  Created by next-shot on 3/17/17.
//  Copyright © 2017 next-shot. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class DrawingTextView: UILabel {
    // *******************************************************
    // DEFINITIONS (Because I'm not brilliant and I'll forget most this tomorrow.)
    // Radius: A straight line from the center to the circumference of a circle.
    // Circumference: The distance around the edge (outer line) the circle.
    // Arc: A part of the circumference of a circle. Like a length or section of the circumference.
    // Theta: A label or name that represents an angle.
    // Subtend: A letter has a width. If you put the letter on the circumference, the letter's width
    //          gives you an arc. So now that you have an arc (a length on the circumference) you can
    //          use that to get an angle. You get an angle when you draw a line from the center of the
    //          circle to each end point of your arc. So "subtend" means to get an angle from an arc.
    // Chord: A line segment connecting two points on a curve. If you have an arc then there is a
    //          start point and an end point. If you draw a straight line from start point to end point
    //          then you have a "chord".
    // sin: (Super simple/incomplete definition) Or "sine" takes an angle in degrees and gives you a number.
    // asin: Or "asine" takes a number and gives you an angle in degrees. Opposite of sine.
    //          More complete definition: http://www.mathsisfun.com/sine-cosine-tangent.html
    // cosine: Also takes an angle in degrees and gives you another number from using the two radiuses (radii).
    // *******************************************************

    
    @IBInspectable var angle: CGFloat = 0
    @IBInspectable var clockwise: Bool = true
    @IBInspectable var radius : CGFloat = 100
    var images = [UIImage]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func draw(_ rect: CGRect) {
        let r = centreArcPerpendicular()
        drawStamps(rect: r.rect, topLine: r.topLine, botLine: r.botLine)
    }
    
    func computeLineRanges(characters: [String], attributes: [String: Any], size: CGSize) -> [(min: Int, max: Int)] {
        var textWidth : CGFloat = 0
        var maxHeight : CGFloat = 0
        var has_newLine = false
        let l = characters.count
        for i in 0 ..< l {
            let attr = characters[i].size(attributes: attributes)
            let cw = attr.width
            textWidth += cw
            maxHeight = max(maxHeight, attr.height)
            
            if( characters[i] == "\n" ) {
                has_newLine = true
            }
        }
        
        var ranges : [(min: Int, max: Int)] = []
        var lastBreak = 0
        if( textWidth > size.width || has_newLine ) {
            // Find line ranges
            var lastSpace = 0
            var textWidth : CGFloat = 0
            var textWidthSinceLastSpace : CGFloat = 0
            for i in 0 ..< l {
                let cw = characters[i].size(attributes: attributes).width
                if( characters[i] == " " ) {
                    lastSpace = i
                    textWidthSinceLastSpace = 0
                } else if( characters[i] == "\n" && i > 0 ) {
                    ranges.append((min: lastBreak, max: i-1))
                    textWidth = 0
                    textWidthSinceLastSpace = 0
                    lastBreak = i+1
                }
                if( textWidth+cw > size.width ) {
                    if( lastSpace == 0 ) {
                        ranges.append((min: lastBreak, max: i-1))
                        textWidth = 0
                        lastBreak = i
                    } else {
                        ranges.append((min: lastBreak, max: lastSpace))
                        textWidth = textWidthSinceLastSpace
                        lastBreak = lastSpace+1
                    }
                }
                textWidth += cw
                textWidthSinceLastSpace += cw
            }
        }
        ranges.append((min: lastBreak, max: l-1))
        return ranges
    }
    
    func computeSize(_ size: CGSize) -> CGSize {
        let str = self.text ?? ""
        let characters: [String] = str.characters.map { String($0) } // An array of single character strings, each character in str
        let stampHeight : CGFloat = 32+4
        
        if( characters.count == 0 ) {
            return CGSize(width: size.width, height: 2*(stampHeight) + self.font.capHeight)
        }
        
        let radius = getRadiusForLabel()
        
        let attributes: [String : Any] = [NSFontAttributeName: self.font]
        
        let ranges = computeLineRanges(characters: characters, attributes: attributes, size: size)
        var csize = CGSize()
        
        // Draw multiple lines
        var minX : CGFloat = 1e+30
        var minY : CGFloat = 1e+30
        var maxX : CGFloat = -1e+30
        var maxY : CGFloat = -1e+30
        var overallMaxHeight : CGFloat = 0
        var computed = false
        var curYTranslation : CGFloat = 0
        for (i,range) in ranges.enumerated() {
            if( range.max < range.min ) {
                continue
            }
            
            var arcs: [CGFloat] = [] // This will be the arcs subtended by each character
            var totalArc: CGFloat = 0 // ... and the total arc subtended by the string
            
            // Calculate the arc subtended by each letter and their total
            var maxHeight : CGFloat = 0
            for j in range.min ... range.max {
                let attr = characters[j].size(attributes: attributes)
                let cw = attr.width
                let arc = chordToArc(cw, radius: radius)
                arcs += [arc]
                totalArc += arc
                maxHeight = max(attr.height, maxHeight)
            }
            overallMaxHeight = max(maxHeight, overallMaxHeight)
            
            // Are we writing clockwise (right way up at 12 o'clock, upside down at 6 o'clock)
            // or anti-clockwise (right way up at 6 o'clock)?
            let direction: CGFloat = clockwise ? -1 : 1
            let radiantAngle = angle/180*CGFloat(Double.pi)
            
            // Compute bounding box of string
            var thetaI = radiantAngle - direction * totalArc / 2
            var li = 0
            for _ in range.min ... range.max {
                thetaI += direction * arcs[li] / 2
                let x = radius * cos(thetaI)
                let y = radius * sin(thetaI) + curYTranslation
                minX = min(minX, x)
                maxX = max(maxX, x)
                minY = min(minY, y)
                maxY = max(maxY, y)
                thetaI += direction * arcs[li] / 2
                li += 1
                
                computed = true
            }
            let verticalPadding : CGFloat = 2
            curYTranslation += maxHeight + verticalPadding
            if( i == 0 ) {
                minY -= (maxHeight+4)
            }
        }
        
        if( !computed ) {
            return CGSize(width: size.width, height: 2*(stampHeight) + self.font.capHeight)
        }
        
        var extraSpace : CGFloat = 0
        if( abs(maxY - minY) < CGFloat(ranges.count+1)*overallMaxHeight + 2*stampHeight ) {
            extraSpace = CGFloat(ranges.count+1)*overallMaxHeight + 2*stampHeight - abs(maxY - minY)
        }
        
        let cgSize = CGSize(width: abs(maxX-minX), height: abs(maxY-minY) + extraSpace)
        csize.width = max(csize.width, cgSize.width)
        csize.height = max(csize.height, cgSize.height)
        return csize
    }
    
    /**
     This draws the self.text around an arc of radius r,
     with the text centred at polar angle theta
     */
    func centreArcPerpendicular() -> (rect:CGRect, topLine: Polyline, botLine: Polyline) {
        guard let context = UIGraphicsGetCurrentContext() else { return (CGRect(), Polyline(), Polyline()) }
        
        context.saveGState()
        
        let str = self.text ?? ""
        let size = self.bounds.size
        context.translateBy(x: size.width / 2, y: size.height / 2)
        
        var cgSize = CGSize()
        
        let radius = getRadiusForLabel()
        let attributes: [String : Any] = [NSFontAttributeName: self.font]
        
        let characters: [String] = str.characters.map { String($0) } // An array of single character strings, each character in str
        
        let ranges = computeLineRanges(characters: characters, attributes: attributes, size: bounds.size)

        let top_polyline = Polyline()
        let bot_polyline = Polyline()
        
        // Draw multiple lines
        for (ri,range) in ranges.enumerated() {
            if( range.max <= range.min ) {
                continue
            }
            
            var arcs: [CGFloat] = [] // This will be the arcs subtended by each character
            var totalArc: CGFloat = 0 // ... and the total arc subtended by the string
            
            // Calculate the arc subtended by each letter and their total
            var maxHeight : CGFloat = 0
            for i in range.min ... range.max {
                let attr = characters[i].size(attributes: attributes)
                let cw = attr.width
                let arc = chordToArc(cw, radius: radius)
                arcs += [arc]
                totalArc += arc
                maxHeight = max(maxHeight, attr.height)
            }
            
            // Are we writing clockwise (right way up at 12 o'clock, upside down at 6 o'clock)
            // or anti-clockwise (right way up at 6 o'clock)?
            let direction: CGFloat = clockwise ? -1 : 1
            let slantCorrection = clockwise ? -CGFloat(Double.pi/2) : CGFloat(Double.pi/2)
            
            let radiantAngle = angle/180*CGFloat(Double.pi)
            
            if( ri == 0 ) {
                // Compute bounding box of string
                var thetaI = radiantAngle - direction * totalArc / 2
                var minX : CGFloat = 1e+30
                var minY : CGFloat = 1e+30
                var maxX : CGFloat = -1e+30
                var maxY : CGFloat = -1e+30
                var li = 0
                for _ in range.min ... range.max {
                    thetaI += direction * arcs[li] / 2
                    let x = radius * cos(thetaI)
                    let y = radius * sin(thetaI)
                    minX = min(minX, x)
                    maxX = max(maxX, x)
                    minY = min(minY, y)
                    maxY = max(maxY, y)
                    thetaI += direction * arcs[li] / 2
                    
                    top_polyline.vertices.append(Point2d(x: x, y: -y))
                    li += 1
                }
                
                context.translateBy(x: (minX + maxX)/2, y: maxY - maxHeight*CGFloat(ranges.count-1) + 4)
                top_polyline.translate(x: (minX + maxX)/2, y: maxY - maxHeight*CGFloat(ranges.count) + 4)
                
                bot_polyline.vertices = top_polyline.vertices.reversed()
                bot_polyline.translate(x: 0, y:2*maxHeight)
            
                cgSize = CGSize(width: abs(maxX-minX) + maxHeight, height: abs(maxY-minY) + maxHeight*CGFloat(ranges.count))
            } else {
                let verticalPadding : CGFloat = 2
                context.translateBy(x: 0, y: maxHeight+verticalPadding)
                bot_polyline.translate(x: 0, y: maxHeight+verticalPadding)
            }
            
            // The centre of the first character will then be at
            // thetaI = theta - totalArc / 2 + arcs[0] / 2
            // But we add the last term inside the loop
            var thetaI = radiantAngle - direction * totalArc / 2
            
            var li = 0
            for i in range.min ... range.max {
                thetaI += direction * arcs[li] / 2
                // Call centre with each character in turn.
                // Remember to add +/-90º to the slantAngle otherwise
                // the characters will "stack" round the arc rather than "text flow"
                centre(text: characters[i], context: context, radius: radius, angle: thetaI, slantAngle: thetaI + slantCorrection)
                // The centre of the next character will then be at
                // thetaI = thetaI + arcs[i] / 2 + arcs[i + 1] / 2
                // but again we leave the last term to the start of the next loop...
                thetaI += direction * arcs[li] / 2
                li += 1
            }
        }
        
        context.restoreGState()
        
        top_polyline.translate(x: size.width / 2, y: size.height / 2)
        bot_polyline.translate(x: size.width / 2, y: size.height / 2)
        /*
        context.move (to: CGPoint(x: polyline.vertices[0].x, y: polyline.vertices[0].y))
        for i in 1 ..< polyline.vertices.count {
            context.addLine(to: CGPoint(x: polyline.vertices[i].x, y: polyline.vertices[i].y))
        }
        context.strokePath()
        context.move (to: CGPoint(x: bot_polyline.vertices[0].x, y: bot_polyline.vertices[0].y))
        for i in 1 ..< bot_polyline.vertices.count {
            context.addLine(to: CGPoint(x: bot_polyline.vertices[i].x, y: bot_polyline.vertices[i].y))
        }
        context.strokePath()
        */

        return (CGRect(
            origin: CGPoint(x: (bounds.minX + bounds.maxX)/2 - cgSize.width/2,
                            y: (bounds.minY + bounds.maxY)/2 - cgSize.height/2),
            size: cgSize
        ), top_polyline , bot_polyline)
    }
    
    func chordToArc(_ chord: CGFloat, radius: CGFloat) -> CGFloat {
        // *******************************************************
        // Simple geometry
        // *******************************************************
        return 2 * asin(chord / (2 * radius))
    }
    
    /**
     This draws the String str centred at the position
     specified by the polar coordinates (r, theta)
     i.e. the x= r * cos(theta) y= r * sin(theta)
     and rotated by the angle slantAngle
     */
    func centre(text str: String, context: CGContext, radius r:CGFloat, angle theta: CGFloat, slantAngle: CGFloat) {
        // Set the text attributes
        let attributes = [NSForegroundColorAttributeName: self.textColor,
                          NSFontAttributeName: self.font] as [String : Any]
        // Save the context
        context.saveGState()
        // Move the origin to the centre of the text (negating the y-axis manually)
        context.translateBy(x: r * cos(theta), y: -(r * sin(theta)))
        // Rotate the coordinate system
        context.rotate(by: -slantAngle)
        // Calculate the width of the text
        let offset = str.size(attributes: attributes)
        // Move the origin by half the size of the text
        context.translateBy(x: -offset.width / 2, y: -offset.height / 2) // Move the origin to the centre of the text (negating the y-axis manually)
        // Draw the text
        str.draw(at: CGPoint(x: 0, y: 0), withAttributes: attributes)
        // Restore the context
        context.restoreGState()
    }
    
    func getRadiusForLabel() -> CGFloat {
        /*
            // Imagine the bounds of this label will have a circle inside it.
            // The circle will be as big as the smallest width or height of this label.
            // But we need to fit the size of the font on the circle so make the circle a little
            // smaller so the text does not get drawn outside the bounds of the circle.
            let smallestWidthOrHeight = min(self.bounds.size.height, self.bounds.size.width)
            let heightOfFont = self.text?.size(attributes: [NSFontAttributeName: self.font]).height ?? 0
            
            // Dividing the smallestWidthOrHeight by 2 gives us the radius for the circle.
            return (smallestWidthOrHeight/2) - heightOfFont + 5
        } else {
        */
            return radius
        //}
    }
    
    func drawStamps(rect: CGRect, topLine: Polyline, botLine: Polyline) {
        if( topLine.vertices.count == 0 || botLine.vertices.count == 0 ) {
            return
        }
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let width : CGFloat = 32
        let height : CGFloat = 32
        
        let time = Int(NSDate().timeIntervalSinceReferenceDate)
        
        let gen = Generate1DLocations(seed: time)
        
        func drawStampsAlongLine(
            line: Polyline,offset: CGFloat
        ) {
            let locs = gen.generate(n: 5, r: Float(width*2), xmin: 0, xmax: Float(line.length()))
            
            let pline = ParametricPolyline(polyline: line)
            for loc in locs {
                var p = pline.location(Double(loc))
                if( p.x + width/2 > bounds.width ) {
                    p.x = bounds.width - width/2
                }
                if( p.x - width/2 < 0 ) {
                    p.x = width/2
                }
                var rect = CGRect(x: p.x - width/2, y: p.y + offset , width: width, height: height)
                if( images.count == 1 ) {
                    let scale = drand48()*0.5 + 0.5
                    rect.size = rect.size.applying(CGAffineTransform(scaleX: CGFloat(scale), y: CGFloat(scale)))
                }
                
                if( images.count > 0 ) {
                    let n = min(Int(drand48()*Double(images.count)), images.count-1)
                    images[n].imageRendererFormat.opaque = false
                    //let cgimage = images[n].cgImage
                    context.saveGState()
                    //let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: rect.size.height+2.0*rect.origin.y)
                    //context.concatenate(flipVertical)
                    images[n].draw(in: rect)
                    //context.draw(cgimage!, in: rect, byTiling: false)
                    context.restoreGState()
                } else {
                    context.stroke(rect)
                }
            }
        }

        drawStampsAlongLine(line: topLine, offset: -height)
        drawStampsAlongLine(line: botLine, offset: 0)
        
        /*
        let gen2D = Generate2DLocations(seed: time)
        let points = gen2D.generate(
            n: 2, r: 64, xmin: self.bounds.minX + width/2, xmax: bounds.maxX - width/2, ymin: bounds.minY + height/2, ymax: bounds.maxY - height/2,
            mask: CGRect(origin: CGPoint(x: rect.origin.x - width/2, y: rect.origin.y - height/2), size: CGSize(width: rect.size.width - width, height: rect.size.height - height))
        )
        for p in points {
            let rect = CGRect(x: p.x, y: p.y, width: 32, height: 32)
        
            context.draw(cgimage!, in: rect, byTiling: false)
        }
        */
    }
    
}

struct Point2d {
    var x: CGFloat
    var y : CGFloat
    func dist_square(p: Point2d) -> Double {
        return Double(x - p.x) * Double(x - p.x) + Double(y - p.y) * Double(y - p.y)
    }
}

class Polyline {
    var vertices = [Point2d]()
    
    func translate(x: CGFloat, y: CGFloat) {
        for i in 0 ..< vertices.count {
            vertices[i].x += x
            vertices[i].y += y
        }
    }
    func length() -> Double {
        var l : Double = 0
        if( vertices.count == 0 ) {
            return 0
        }
        for i in 1 ..< vertices.count {
            let d = vertices[i].dist_square(p: vertices[i-1])
            l += sqrt(d)
        }
        return l
    }
}

class ParametricPolyline {
    let polyline: Polyline
    let distance : [Double]
    
    init(polyline: Polyline) {
        self.polyline = polyline
        if( polyline.vertices.count == 0 ) {
            self.distance = [Double]()
            return
        }
        
        var distance = [Double]()
        distance.append(0)
        
        var dist : Double = 0.0
        var px = polyline.vertices[0].x
        var py = polyline.vertices[0].y
        for i in 1 ..< polyline.vertices.count {
            let x = polyline.vertices[i].x
            let y = polyline.vertices[i].y
            let dx = Double(x-px)
            let dy = Double(y-py)
            let d = dx*dx + dy*dy
            dist += sqrt(d)
            distance.append(dist)
            px = x
            py = y
        }
        
        self.distance = distance
    }
    
    func location(_ t: Double) -> Point2d {
        let idx = lower_bound(t)
        let n = distance.count
        if( t < distance[0] ) {
            return polyline.vertices[0]
        } else if( t > distance[n-1] ) {
            return polyline.vertices.last!
        } else {
            let h = CGFloat((t - distance[idx])/(distance[idx+1] - distance[idx]))
            let p0 = polyline.vertices[idx]
            let p1 = polyline.vertices[idx+1]
            return Point2d(x: p0.x*(1-h) + p1.x*h, y: p0.y*(1-h) + p1.y*h)
        }
    }
    
    private func lower_bound(_ t: Double) -> Int {
        let n = distance.count
        if( t < distance[0] ) {
            return 0
        }
        for i in 0 ..< n {
            if( t < distance[i] ) {
                return i-1
            }
        }
        return n-1
    }
}

class Generate2DLocations {
    init( seed: Int) {
        srand48( seed )
    }
    
    func generate(
        n: Int, r: CGFloat, xmin: CGFloat, xmax: CGFloat, ymin: CGFloat, ymax: CGFloat, mask: CGRect
    ) -> [Point2d] {
        var points = [Point2d]()
        
        let k = 30
        var x0 = CGFloat(drand48())*(xmax - xmin) + xmin
        var y0 = CGFloat(drand48())*(ymax - xmin) + ymin
        for _ in 1..<k {
            // Generate a point choosen uniformly
            if( mask.contains(CGPoint(x: x0, y: y0)) ) {
                x0 = CGFloat(drand48())*(xmax - xmin) + xmin
                y0 = CGFloat(drand48())*(ymax - xmin) + ymin
            } else {
                break
            }
        }
        points.append(Point2d(x: x0, y: y0))
        
        var active = [Int]()
        active.append(0)
        
        while( active.count > 0 && points.count < n ) {
            // Choose a random index in the list of active points.
            let i = Int(drand48()*Double((active.count-1)))
            // Find if we can generate a new point in the vicinity of this point
            let np = select(
                p: points[active[i]], points: points, r: r, xmin: xmin, xmax: xmax, ymin: ymin, ymax: ymax,
                mask: mask
            )
            if( np != nil ) {
                // Append the new point to the list of points
                points.append(np!)
                active.append(points.count-1)
            } else {
                // Remove the point from the list of active points
                active.remove(at: i)
            }
        }
        return points
    }
    
    internal func select(
        p: Point2d, points: [Point2d], r: CGFloat, xmin: CGFloat, xmax: CGFloat, ymin: CGFloat, ymax: CGFloat, mask: CGRect
    ) -> Point2d? {
        let r_square = Double(r)*Double(r)
        
        // K tries to find a good point
        let k = 30
        for _ in 0..<k {
            // Generate a point choosen uniformly from the spherical annulus between radius r and 2r around p
            let rr = drand48()*Double(r) + Double(r)
            let x1 = p.x + CGFloat(rr*cos(drand48()*360/M_2_PI))
            let y1 = p.y + CGFloat(rr*sin(drand48()*360/M_2_PI))
            if( x1 < xmin || x1 > xmax || y1 < ymin || y1 > ymax || mask.contains(CGPoint(x: x1, y: y1)) ) {
                continue
            }
            let p1 = Point2d(x: x1, y: y1)
            
            // See if it is not too close from the other selected points
            // Using a brute force approach (should use a grid search)
            var ok = true
            for jp in points {
                let d = p1.dist_square(p: jp)
                if( d < r_square ) {
                    ok = false
                    break
                }
            }
            if( ok ) {
                return p1
            }
        }
        return nil
    }
}

class Generate1DLocations {
    init( seed: Int) {
        srand48( seed )
    }
    
    func generate(n: Int, r: Float, xmin: Float, xmax: Float) -> [Float] {
        var xs = [Float]()
        if( n == 0 ) {
            return xs
        }
        
        let x0 = Float(drand48())*(xmax - xmin) + xmin
        xs.append(x0)
        
        var active = [Int]()
        active.append(0)
        
        while( active.count > 0 && xs.count < n ) {
            // Choose a random index in the list of active points.
            let i = min(Int(drand48()*Double((active.count))), active.count-1)
            // Find if we can generate a new point in the vicinity of this point
            let np = select(x: xs[active[i]], xs: xs, r: r, xmin: xmin, xmax: xmax)
            if( np != nil ) {
                // Append the new point to the list of points
                xs.append(np!)
                active.append(xs.count-1)
            } else {
                // Remove the point from the list of active points
                active.remove(at: i)
            }
        }
        return xs
    }
    
    internal func select(x: Float, xs: [Float], r: Float, xmin: Float, xmax: Float) -> Float? {
        // K tries to find a good point
        let k = 30
        for _ in 0..<k {
            // Generate a point choosen uniformly from the spherical annulus between radius r and 2r around p
            let rr = drand48()*Double(r) + Double(r)
            let x1 = x + Float(rr*cos(drand48()*360/M_2_PI))
            if( x1 < xmin || x1 > xmax ) {
                continue
            }
            
            // See if it is not too close from the other selected points
            var ok = true
            for jx in xs {
                if( abs(jx-x1) < r ) {
                    ok = false
                    break
                }
            }
            if( ok ) {
                return x1
            }
        }
        return nil
    }
}



