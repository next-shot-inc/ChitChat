//
//  ExpenseMessage.swift
//  ChitChat
//
//  Created by next-shot on 6/9/17.
//  Copyright © 2017 next-shot. All rights reserved.
//

import Foundation
import UIKit

// The expense record itself.
// Extract from the MessageRecord payLoad the amount and reason for the expense.
class ExpenseRecord : MessageRecord, MessageRecordDelegate {
    var amount: Float
    var reason: String
    
    init(id: RecordId, user_id: RecordId, expense_tab_id: RecordId, amount: Float, reason: String) {
        self.amount = amount
        self.reason = reason
        super.init(id: id, message_id: expense_tab_id, user_id: user_id, type: "ExpenseRecord")
        self.delegate = self
        self.payLoad = getPayLoad()
    }
    
    init(message: Message, user: User, amount: Float, reason: String) {
        self.amount = amount
        self.reason = reason
        super.init(message: message, user: user, type: "ExpenseRecord")
        self.delegate = self
        self.payLoad = self.getPayLoad()
    }
    
    init(record: MessageRecord) {
        self.amount = 0
        self.reason = String()
        super.init(record: record, type: "ExpenseRecord")
        self.delegate = self
        
        initFromPayload(string: record.payLoad)
    }
    
    func put(dict: NSMutableDictionary) {
        dict.setValue(NSNumber(value: amount), forKey: "amount")
        dict.setValue(NSString(string: reason),  forKey: "reason")
    }
    
    func fetch(dict: NSDictionary) {
        amount = (dict["amount"] as! NSNumber) as! Float
        reason = (dict["reason"] as! NSString) as String
    }
    
}

// Comptabilize current expenses
class ExpenseData {
    var expenses = [RecordId:Float]()
    var myDues = [RecordId:Float]()
    var expenseUsers = [String]()
    var myDueUsers = [String]()
    var usersToId = [String:RecordId]()
    
    init(expenseRecords: [ExpenseRecord], message: Message, options: MessageOptions?) {
        // Sum all the expenses and per-person expenses.
        var total : Float = 0
        for er in expenseRecords {
            let ce = expenses[er.user_id]
            expenses[er.user_id] = (ce ?? 0) + er.amount
            total += er.amount
        }
        
        // Add people that have not paid (starting by the current user)
        let me = model.me()
        if( expenses[me.id] == nil ) {
            expenses[me.id] = 0
        }
        
        let group = model.getGroup(id: message.group_id!)
        if( group != nil ) {
            let users = model.getUsers(group: group!)
            for u in users {
                if( expenses[u.id] == nil ) {
                    expenses[u.id] = 0
                }
            }
        }
        
        // Each users should have spend this amount
        let splitExpense = total/Float(expenses.count)
        
        // Compute the total amount dues by summing all the overpaid expenses.
        var totalDue : Float = 0
        for ex in expenses {
            if( ex.value > splitExpense ) {
                totalDue += (ex.value - splitExpense)
            }
            
            let user = model.getUser(userId: ex.key)
            if( user != nil ) {
                let name = user!.id == me.id ? "Me" : (user!.label ?? " ")
                if( ex.value != 0 || ex.key == me.id ) {
                    // Do not add people that have no paid anything, except for me
                    // (as this list is used to control the "paid expenses" portion of the table).
                    expenseUsers.append(name)
                }
                usersToId[name] = ex.key
            }
        }
        let myExpense = expenses[me.id] ?? 0
        
        // Compute the amount due to each users that have overpaid. 
        // and the amount each user owe me if I have overpaid.
        let due = splitExpense - myExpense
        for ex in expenses {
            if( ex.key == me.id ) {
                continue
            }
            if( due > 0 && ex.value > splitExpense ) {
                // If I owe something, I owe it to the people that paid more.
                myDues[ex.key] = due * (ex.value - splitExpense)/totalDue
            } else if( due < 0 && ex.value < splitExpense ) {
                // If I am owed something, it is by the people that paid less
                myDues[ex.key] = due * (splitExpense - ex.value)/totalDue
            }
        }
        
        for md in myDues {
            let user = model.getUser(userId: md.key)
            let name = user?.label ?? " "
            myDueUsers.append(name)
            usersToId[name] = md.key
        }
        
        expenseUsers.sort { (s1, s2) -> Bool in return s1 < s2 }
        myDueUsers.sort { (s1, s2) -> Bool in return s1 < s2 }
    }
}

class ExpenseTableCell : UITableViewCell {

    @IBOutlet weak var separator: UIView!
    @IBOutlet weak var user: UILabel!
    @IBOutlet weak var amount: UILabel!
    
}

// The table view data source for an Expense: one row per user total expense, and 
// one row per amount due
class ExpenseMessageData : NSObject, UITableViewDataSource, UITableViewDelegate {
    var expenseData : ExpenseData!
    weak var controller : MessagesViewController?
    weak var expenseMessageCell: ExpenseMessageCell?
    
    init(data: ExpenseData, ctrler: MessagesViewController?, cell: ExpenseMessageCell) {
        self.expenseData = data
        self.controller = ctrler
        self.expenseMessageCell = cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if( section == 0 ) {
            return expenseData.expenseUsers.count
        } else {
            return expenseData.myDueUsers.count == 0 ? 0 : expenseData.myDueUsers.count + 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell : ExpenseTableCell!
        let userName : String!
        let amount : Float!
        
        if( indexPath.section == 0 ) {
            cell = tableView.dequeueReusableCell(withIdentifier: "ExpenseTableCell") as! ExpenseTableCell
            
            userName = expenseData.expenseUsers[indexPath.row]
            amount = expenseData.expenses[expenseData.usersToId[userName]!]
            
            if( indexPath.row == 0 ) {
                cell.separator.isHidden = true
            }
        } else {
            if( indexPath.row == 0 ) {
                return tableView.dequeueReusableCell(withIdentifier: "ExpenseHeaderCell")!
            }
            
            cell = tableView.dequeueReusableCell(withIdentifier: "ExpenseTableCell") as! ExpenseTableCell
            
            userName = expenseData.myDueUsers[indexPath.row-1]
            amount = expenseData.myDues[expenseData.usersToId[userName]!]
            
            cell.accessoryType = .none
        }
        
        cell.user.text = userName
        
        let nfc = NumberFormatter()
        nfc.numberStyle = .currencyAccounting
        nfc.maximumFractionDigits = 2
        cell.amount.text = nfc.string(from: NSNumber(value: amount))
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        controller?.selectedMessage = expenseMessageCell?.message
        controller?.performSegue(withIdentifier: "showExpenseDetails", sender: self)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if( indexPath.section == 0 ) {
            return indexPath
        }
        // does not allow selection of the myDues rows.
        return nil
    }
}

// Displays a table with the expenses for each users of the group (if any) and for the current user
// Displays the dues due to the other users of the group.
// Allow the current user to add an expense to the shared expense tab.

class ExpenseMessageCell : UICollectionViewCell, MessageBaseCellDelegate, UITextFieldDelegate {
    @IBOutlet weak var labelView: UIView!
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var spentStackView: UIStackView!
    @IBOutlet weak var addExpenseButton: UIButton!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var reasonTextField: UITextField!
    
    weak var controller: MessagesViewController?
    var message: Message?
    var data: ExpenseMessageData?
    var expenseRecord : ExpenseRecord?
    var tapper : UITapGestureRecognizer?

    func initialize(message: Message, controller : MessagesViewController?) {
        self.message = message
        self.controller = controller
        
        title.text = message.text
        fromLabel.text = getFromName(message: message)
        amountTextField.delegate = self
        reasonTextField.delegate = self
        spentStackView.isHidden = true
        
        updateExpenses()
    }
    
    func userIcon() -> UIImageView? {
        return iconView
    }
    func containerView() -> UIView? {
        return labelView
    }
    
    func updateExpenses() {
        model.getExpenseItems(expense_tab: message!, completion: { (records) in
            if( self.controller == nil || self.message == nil ) {
                return
            }
            DispatchQueue.main.async(execute: {
                let data = ExpenseData(expenseRecords: records, message: self.message!, options: nil)
                self.data = ExpenseMessageData(data: data, ctrler: self.controller, cell: self)
                self.tableView.dataSource = self.data
                self.tableView.delegate = self.data
                self.tableView.reloadData()
            })
        })
    }
    
    // Callback linked to the addExpense action.
    // At first an expense Record is created, the icon is changed to "send",
    // and the textField to enter the reason and amount are shown (embedded inside the spentStackView).
    //
    // Once the information is filled-in for the expenseRecord, save the record
    // and flip back the UI to the "add" option.
    @IBAction func addExpenseAction(_ sender: Any) {
        if( expenseRecord == nil ) {
            expenseRecord = ExpenseRecord(
                message: message!, user: model.me(), amount: 0, reason: ""
            )
            addExpenseButton.setImage(UIImage(named: "sent-32"), for: .normal)
            spentStackView.isHidden = false
        } else {
            // Store ExpenseRecord.
            if( amountTextField.text != nil ) {
                expenseRecord!.amount = Float(amountTextField.text!) ?? 0
            }
            if( reasonTextField.text != nil ) {
                expenseRecord!.reason = reasonTextField.text!
            }
            
            model.saveExpenseItem(expenseRecord: expenseRecord!)
            expenseRecord = nil
            addExpenseButton.setImage(UIImage(named: "plus-32"), for: .normal)
            spentStackView.isHidden = true
            updateExpenses()
        }
    }
    
    // TextField Delegates function
    func textFieldShouldBeginEditing(_ textView: UITextField) -> Bool {
        tapper = UITapGestureRecognizer(target: self, action:#selector(endEditingWithTouch))
        tapper!.cancelsTouchesInView = false
        controller?.view.addGestureRecognizer(tapper!)
        
        return true
    }
    
    func textFieldDidEndEditing(_ textView: UITextField) {
        if( controller != nil ) {
            if( tapper != nil ) {
                controller!.view.removeGestureRecognizer(tapper!)
            }
        }
        if( expenseRecord != nil ) {
            if( amountTextField.text != nil ) {
                expenseRecord!.amount = Float(amountTextField.text!) ?? 0
            }
            if( reasonTextField.text != nil ) {
                expenseRecord!.reason = reasonTextField.text!
            }
        }
    }
    
    @objc func endEditingWithTouch() {
        amountTextField.resignFirstResponder()
        reasonTextField.resignFirstResponder()
    }

}

// Compute the height of the expense message (shows 4 rows by default)
class ExpenseMessageCellSizeDelegate : MessageBaseCellSizeDelegate {
    func size(message: Message, collectionView: UICollectionView) -> CGSize {
        let hspacing : CGFloat = 10
        let width = collectionView.bounds.width - 2*hspacing
        
        let count = 4
        
        let attributes: [NSAttributedStringKey : Any] = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 17)]
        
        let height = max(message.text.size(withAttributes: attributes).height, 28)
        
        let heightFromLabels : CGFloat = 16 + height
        let vspacing : CGFloat = 5
        
        return CGSize(width: width, height: CGFloat(count)*height + heightFromLabels + 4*vspacing + CGFloat(count)*vspacing)
    }
}

/****************************************************************/
// Classes used to display the details of expenses.

// Display the details of a particular expense (reason, date, amount)
class ExpenseDetailsTableViewCell : UITableViewCell {
    
    @IBOutlet weak var reason: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var amount: UILabel!
}

// Display the name of the category of expenses.
class ExpenseDetailsHeaderTableViewCell : UITableViewCell {
    
    @IBOutlet weak var header: UILabel!
}

class ExpenseDetailsDataSource : NSObject, UITableViewDataSource {
    weak var ctrler: ExpenseDetailsTableViewController?
    var records : [ExpenseRecord]
    var headers = [String]()
    var sortedRecords = [String:[ExpenseRecord]]()
    var total : Float = 0
    var lastDate : Date
    
    init(records: [ExpenseRecord], controller: ExpenseDetailsTableViewController) {
        self.records = records
        self.ctrler = controller
        
        // Sort the expenses per users.
        total = 0
        lastDate = controller.message!.last_modified
        for r in records {
            let user = model.getUser(userId: r.user_id)
            if( user != nil && user!.label != nil ) {
                let label = user!.id == model.me().id ? "Me" : user!.label!
                if( !headers.contains(label) ) {
                    headers.append(label)
                }
                var sorted = sortedRecords[label]
                if( sorted == nil ) {
                    sortedRecords[label] = [r]
                } else {
                    sorted!.append(r)
                    sortedRecords[label] = sorted
                }
            }
            total += r.amount
            if( r.date_created > lastDate ) {
                lastDate = r.date_created
            }
        }
        headers.sort { (s1, s2) -> Bool in return s1 < s2 }
        for st in sortedRecords {
            var sorted = st.value
            sorted.sort(by: { (ex1, ex2) -> Bool in
                return ex1.date_created < ex2.date_created
            })
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Flatten view of the records + 2 rows for the Total section.
        return records.count + headers.count + 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var row = indexPath.row
        var section = 0
        
        // Total section
        if( row == records.count + headers.count ) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ExpenseDetailsHeaderTableViewCell") as! ExpenseDetailsHeaderTableViewCell
            cell.header.text = "Total"
            return cell

        } else if( row == records.count + headers.count + 1 ){
            let cell = tableView.dequeueReusableCell(withIdentifier: "ExpenseDetailsTableViewCell") as! ExpenseDetailsTableViewCell
            
            cell.reason.text = "Total"
            let longDateFormatter = DateFormatter()
            longDateFormatter.locale = Locale.current
            longDateFormatter.setLocalizedDateFormatFromTemplate("MMM d, HH:mm")
            longDateFormatter.timeZone = TimeZone.current

            cell.date.text = longDateFormatter.string(from: lastDate)
            let nfc = NumberFormatter()
            nfc.numberStyle = .currencyAccounting
            nfc.maximumFractionDigits = 2
            cell.amount.text = nfc.string(from: NSNumber(value: total))
            return cell
        }
        
        // Flatten two level tree
        while( row >= 0 ) {
            if( row == 0 ) {
                // Section header
                let cell = tableView.dequeueReusableCell(withIdentifier: "ExpenseDetailsHeaderTableViewCell") as! ExpenseDetailsHeaderTableViewCell
                
                cell.header.text = headers[section]
                return cell
            } else {
                row -= 1
                for er in sortedRecords[headers[section]]! {
                    if( row == 0 ) {
                        let cell = tableView.dequeueReusableCell(withIdentifier: "ExpenseDetailsTableViewCell") as! ExpenseDetailsTableViewCell
                        cell.reason.text = er.reason
                        
                        let longDateFormatter = DateFormatter()
                        longDateFormatter.locale = Locale.current
                        longDateFormatter.setLocalizedDateFormatFromTemplate("MMM d, HH:mm")
                        longDateFormatter.timeZone = TimeZone.current
                        let longDate = longDateFormatter.string(from: er.date_created)
                        cell.date.text = longDate
                        
                        let nfc = NumberFormatter()
                        nfc.numberStyle = .currencyAccounting
                        nfc.maximumFractionDigits = 2
                        cell.amount.text = nfc.string(from: NSNumber(value: er.amount))
                        return cell
                    }
                    row -= 1
                }
                section += 1
            }
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExpenseDetailsHeaderTableViewCell") as! ExpenseDetailsHeaderTableViewCell
        return cell
    }

}

class ExpenseDetailsTableViewController : UITableViewController {
    var message: Message?
    var data: ExpenseDetailsDataSource?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if( message != nil ) {
            model.getExpenseItems(expense_tab: message!, completion: { (records) in
                DispatchQueue.main.async(execute: {
                    self.data = ExpenseDetailsDataSource(
                        records: records, controller: self
                    )
                    self.tableView.dataSource = self.data
                    self.tableView.reloadData()
                })
            })

        }
    }
}
