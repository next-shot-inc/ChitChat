//
//  UserActivity.swift
//  ChitChat
//
//  Created by next-shot on 2/13/18.
//  Copyright © 2018 next-shot. All rights reserved.
//

import Foundation
import UIKit

class UserActivityView : UIView {
    var labelFont: UIFont? = UIFont.systemFont(ofSize: 12)
    var axesColor: UIColor = UIColor.gray.withAlphaComponent(0.3)
    var labelColor : UIColor = UIColor.black
    
    var topInset: CGFloat = 20 // Height of the area at the top of the chart, containing the labels for the x-axis.
    var leftInset : CGFloat = 20 // Width of the area at the left of the chart, containing the labels for the y-axis
    var xLabelWidth : CGFloat = 20
    var xLabelHeight : CGFloat = 20
    var yLabelWidth : CGFloat = 20
    var yLabelHeight : CGFloat = 0
    let margin : CGFloat = 2
    
    enum ViewMode { case Hourly, Daily }
    var mode : ViewMode = .Hourly
    
    var grid = [Int]()
    var maxGridValue = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        getlabelWidth()
    }
    
    func getlabelWidth() {
        let attributes: [NSAttributedStringKey : Any] = [NSAttributedStringKey.font: self.labelFont]
        xLabelWidth = leftInset
        xLabelHeight = topInset
        for label in xLabels() {
            let attr = label.size(withAttributes: attributes)
             let ch = attr.height
            let cw = attr.width
            xLabelWidth = max(xLabelWidth, cw)
            xLabelHeight = max(xLabelHeight, ch)
        }
        
        yLabelWidth = leftInset
        yLabelHeight = 0
        for label in yLabels() {
            let attr = label.size(withAttributes: attributes)
            let ch = attr.height
            let cw = attr.width
            yLabelWidth = max(yLabelWidth, cw)
            yLabelHeight = max(yLabelHeight, ch)
        }
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        let attributes : [NSAttributedStringKey: Any] =
            [NSAttributedStringKey.foregroundColor: self.labelColor,
             NSAttributedStringKey.font: self.labelFont]
        
        
        let drawingHeight = bounds.height - xLabelHeight - margin
        let drawingWidth = bounds.width - yLabelWidth - 2*margin
        
        let nbCol = self.nbColumns()
        let nbRow = self.nbRows()
        let rectWidth = 1/CGFloat(nbCol)*drawingWidth
        let rectHeight = 1/CGFloat(nbRow)*drawingHeight
        
        let yLabels = self.yLabels()
        let yLabelInterval = CGFloat(nbRow)/CGFloat(yLabels.count)
        for (i,label) in yLabels.enumerated() {
            let ypos = yLabelInterval*CGFloat(i)/CGFloat(nbRow)*drawingHeight + margin + (yLabelInterval-1)/CGFloat(nbRow)/2*drawingHeight + (rectHeight-2*margin)/2
            let xpos = margin
            
            context.saveGState()
            // Move the origin to the centre of the text (negating the y-axis manually)
            context.translateBy(x: xpos, y: ypos)
            // Calculate the width of the text
            let offset = label.size(withAttributes: attributes)
            // Move the origin by half the size of the text
            context.translateBy(x: 0, y: offset.height/2) // Move the origin to the centre of the text (negating the y-axis manually)
            // Draw the text
            label.draw(at: CGPoint(x: 0, y: 0), withAttributes: attributes)
            // Restore the context
            context.restoreGState()
        }
        
        let xLabels = self.xLabels()
        let xLabelInterval = CGFloat(nbCol)/CGFloat(xLabels.count)
        for (i,label) in xLabels.enumerated() {
            let xpos = xLabelInterval * CGFloat(i)/CGFloat(nbCol)*drawingWidth + yLabelWidth + margin + (xLabelInterval-1)/CGFloat(nbCol)/2*drawingWidth + (rectWidth - 2*margin)/2
            let ypos = margin
            
            context.saveGState()
            // Move the origin to the centre of the text (negating the y-axis manually)
            context.translateBy(x: xpos, y: ypos)
            // Calculate the width of the text
            let offset = label.size(withAttributes: attributes)
            // Move the origin by half the size of the text
            context.translateBy(x: -offset.width/2, y: 0) // Move the origin to the centre of the text (negating the y-axis manually)
            // Draw the text
            label.draw(at: CGPoint(x: 0, y: 0), withAttributes: attributes)
            // Restore the context
            context.restoreGState()
        }
        
        context.setFillColor(self.axesColor.cgColor)
        let nbColorBins = 4
        let incColor = 0.6/CGFloat(nbColorBins) // 60% darker is plenty enough dark
        let clearColor = UIColor(red: 72.0/255.0, green: 1.0, blue: 111.0/255.0, alpha: 1.0)
        
        for j in 0..<nbRow {
            for i in 0..<nbCol {
                let rect = CGRect(
                    origin: CGPoint(x: CGFloat(i)*rectWidth + yLabelWidth + 2*margin,
                                    y: CGFloat(j)*rectHeight + yLabelHeight + margin),
                    size: CGSize(width: rectWidth - 2*margin, height: rectHeight - 2*margin)
                )
                if( grid.count > 0 ) {
                    let value = grid[j*nbCol + i]
                    if( value == 0 ) {
                        context.setFillColor(self.axesColor.cgColor)
                    } else {
                        let bin = Int(CGFloat(value)/CGFloat(maxGridValue)*CGFloat(nbColorBins)+0.5)
                        let color = clearColor.mixDarker(amount: CGFloat(bin)*incColor)
                        context.setFillColor(color.cgColor)
                    }
                }
                context.fill(rect)
            }
        }
    }
    
    func xLabels() -> [String] {
        switch mode {
        case .Hourly:
            return ["S", "M", "T", "W", "T", "F", "S"]
        default:
            // Compute the series of month since last records are kept
            var calendar = Calendar(identifier: .gregorian)
            calendar.locale = Locale.autoupdatingCurrent
            let lastDate = Date()
            let firstDate = Date(timeIntervalSinceNow: -Double(settingsDB.settings.nb_of_days_to_keep)*24*3600)
            let firstMonth = calendar.component(.month, from: firstDate)
            let lastMonth = calendar.component(.month, from: lastDate)
            var months = [String]()
            var curMonth = firstMonth
            months.append(calendar.veryShortMonthSymbols[curMonth-1])
            while( curMonth != lastMonth ) {
                curMonth += 1
                if( curMonth > 12 ) { curMonth = 1 }
                months.append(calendar.veryShortMonthSymbols[curMonth-1])
            }
            return months
        }
    }
    
    func yLabels() -> [String] {
        switch mode {
        case .Hourly:
            return ["12-3AM", "6-9AM", "9AM-12PM", "12-3PM", "3-6PM", "6-9PM", "9PM-12AM"]
        default:
            return ["M", "W", "F"]
        }
    }
    
    func nbColumns() -> Int {
        switch mode {
        case .Hourly:
            return 7
        default:
            let calendar = Calendar(identifier: .gregorian)
            let lastDate = Date()
            let firstDate = Date(timeIntervalSinceNow: -Double(settingsDB.settings.nb_of_days_to_keep)*24*3600)
            let firstMonth = calendar.component(.month, from: firstDate)
            var curYear = calendar.component(.year, from: firstDate)
            let lastMonth = calendar.component(.month, from: lastDate)
            var curMonth = firstMonth
            var nbdays = calendar.range(of: .day, in: .month, for: lastDate)!.count
            while (curMonth != lastMonth ) {
                let dateComponents = DateComponents(year: curYear, month: curMonth)
                let date = calendar.date(from: dateComponents)!
                let range = calendar.range(of: .day, in: .month, for: date)!
                let numDays = range.count
                nbdays += numDays
                
                curMonth += 1
                if( curMonth > 12 ) {
                    curMonth = 1
                    curYear += 1
                }
            }
            return Int(ceil(Float(nbdays)/7))
        }
    }
    
    func nbRows() -> Int {
        switch mode {
        case .Hourly:
            return 7
        default:
            return 7
        }
    }
    
    override var intrinsicContentSize: CGSize {
        get {
            getlabelWidth()
            return CGSize(width: CGFloat(nbColumns()*30) + yLabelWidth + 2*margin, height: CGFloat(nbRows()*30) +  xLabelHeight + 2*margin)
        }
    }
    
    func showDates(dates: [Date]) {
        let calendar = Calendar(identifier: .gregorian)
        
        let nbcol = nbColumns()
        let nbrow = nbRows()
        grid = [Int](repeating: 0, count: nbcol*nbrow)
        maxGridValue = 0
        let firstDate = Date(timeIntervalSinceNow: -Double(settingsDB.settings.nb_of_days_to_keep)*24*3600)
        
        for date in dates {
            if( date < firstDate ) {
                // Old records
                continue
            }
            
            let weekday_of = calendar.component(.weekday, from: date) // Sun = 1, Sat = 7
            let monthday_of = calendar.component(.day, from: date)
            let month_of = calendar.component(.month, from: date)
            let hour_of = calendar.component(.hour, from: date)
            let year_of = calendar.component(.year, from: date)
            
            let i,j : Int
            switch mode {
            case .Hourly :
                j = Int(Float(hour_of)/Float(24)*7)
                i = weekday_of-1
            default:
                j = weekday_of-1
                // Count the number of days since the beginning of keeping records.
                let firstMonth = calendar.component(.month, from: firstDate)
                let lastMonth = month_of
                var curMonth = firstMonth
                var curYear = calendar.component(.year, from: firstDate)
                var nbdays = monthday_of
                while (curMonth != lastMonth || year_of != curYear) {
                    
                    let dateComponents = DateComponents(year: curYear, month: curMonth)
                    let date = calendar.date(from: dateComponents)!
                    
                    let range = calendar.range(of: .day, in: .month, for: date)!
                    let numDays = range.count
                    nbdays += numDays
                    
                    curMonth += 1
                    if( curMonth > 12 ) {
                        curMonth = 1
                        curYear += 1
                    }
                }
                i = nbdays/7
            }
            grid[j*nbcol + i] += 1
            if( grid[j*nbcol + i] > maxGridValue ) {
                maxGridValue = grid[j*nbcol + i]
            }
        }
    }
}

class UserActivityViewController : UIViewController {
    
    @IBOutlet weak var userActivityView: UserActivityView!
    var dates = [Date]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        model.db_model.getUserActivityDates(userId: model.me().id, completion: { (dates) -> Void in
            DispatchQueue.main.async(execute: {
                self.dates = dates
                self.userActivityView.showDates(dates: dates)
                self.userActivityView.setNeedsDisplay()
            })
        })

    }
    
    @IBAction func toggleView(_ sender: UIBarButtonItem) {
        if( userActivityView.mode == .Daily ) {
            sender.title = "Daily"
            userActivityView.mode = .Hourly
            userActivityView.invalidateIntrinsicContentSize()
            userActivityView.showDates(dates: dates)
            userActivityView.setNeedsDisplay()
        } else {
            sender.title = "Hourly"
            userActivityView.mode = .Daily
            userActivityView.invalidateIntrinsicContentSize()
            userActivityView.showDates(dates: dates)
            userActivityView.setNeedsDisplay()
        }
    }
}
