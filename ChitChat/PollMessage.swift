//
//  PollMessage.swift
//  ChitChat
//
//  Created by next-shot on 4/2/17.
//  Copyright © 2017 next-shot. All rights reserved.
//

import Foundation
import UIKit

// The voting record itself.
class PollRecord {
    var id: RecordId
    let user_id : RecordId
    let poll_id : RecordId
    var checked_option: Int
    var date_created = Date()
    
    init(id: RecordId, user_id: RecordId, poll_id: RecordId, checked_option: Int) {
        self.id = id
        self.user_id = user_id
        self.poll_id = poll_id
        self.checked_option = checked_option
    }
}

// Comptabilize current votes
class PollData {
    var nb_votes = 0
    var nb_total_votes = 0
    var elements = [(label: String,nb_votes: Int)]()
    var alreadyVoted = false
    
    init(pollRecords: [PollRecord], message: Message, options: MessageOptions?) {
        // The total number of votes = number of people in the group.
        let cthread = model.getConversationThread(threadId: message.conversation_id)
        if( cthread != nil ) {
            let group = model.getGroup(id: cthread!.group_id)
            if( group != nil ) {
                nb_total_votes = model.getUsers(group: group!).count
            }
        }
        if( nb_total_votes == 0 ) {
            nb_total_votes = pollRecords.count
        }
        
        // Assign votes to the proper choice.
        nb_votes = pollRecords.count
        let voteOptions = options?.pollOptions ?? MessageOptions(options: message.options).pollOptions
        for vo in voteOptions {
            elements.append((label: vo, nb_votes: 0))
        }
        
        for pr in pollRecords {
            if( pr.checked_option >= 0 && pr.checked_option < voteOptions.count ) {
                elements[pr.checked_option].nb_votes += 1
            }
            if( pr.user_id == model.me().id ) {
                alreadyVoted = true
            }
        }
    }
}

// This table cell shows a checkbox and a label.
// Notify the container of the button selection.
class VotingTableViewCell : UITableViewCell {
    @IBOutlet weak var choiceLabel: UILabel!
    @IBOutlet weak var checkButton: UIButton!
    
    weak var pollMessageCell : PollMessageCell?
    var index = 0
    
    func initialize(cell: PollMessageCell, index: Int) {
        checkButton.setImage(UIImage(named: "checked"), for: .selected)
        checkButton.setImage(UIImage(named: "unchecked"), for: .normal)
        
        pollMessageCell = cell
        self.index = index
        
        choiceLabel.text = cell.data!.pollData.elements[index].label
    }
    
    @IBAction func pushButton(_ sender: UIButton) {
        sender.isSelected = true
        pollMessageCell?.selectChoice(index)
    }
}

// This table cells shows a checkbox and a textfield 
// The checkbox allows the current user to vote, 
// The textfield allows the current user and creator of the poll to edit the choice label.
class EditChoiceTableViewCell : UITableViewCell, UITextFieldDelegate {

    weak var pollMessageCell : PollMessageCell?
    var index = 0
    
    @IBOutlet weak var choiceTextField: UITextField!
    
    @IBOutlet weak var checkButton: UIButton!
    
    var tapper : UITapGestureRecognizer?
    
    func initialize(cell: PollMessageCell, index: Int) {
        choiceTextField.delegate = self
        pollMessageCell = cell
        self.index = index
        
        let pollData = cell.data!.pollData!
        choiceTextField.text = pollData.elements[index].label
        if( cell.pollRecord?.checked_option == index ) {
            checkButton.isSelected = true
        }
        
        checkButton.setImage(UIImage(named: "checked"), for: .selected)
        checkButton.setImage(UIImage(named: "unchecked"), for: .normal)
    }
    
    @IBAction func pushButton(_ sender: UIButton) {
        sender.isSelected = true
        pollMessageCell?.selectChoice(index)
    }
    
    func textFieldShouldBeginEditing(_ textView: UITextField) -> Bool {
        tapper = UITapGestureRecognizer(target: self, action:#selector(endEditingWithTouch))
        tapper!.cancelsTouchesInView = false
        pollMessageCell?.controller?.view.addGestureRecognizer(tapper!)
        
        return true
    }
    
    func textFieldDidEndEditing(_ textView: UITextField) {
        if( pollMessageCell?.controller != nil ) {
            if( tapper != nil ) {
                pollMessageCell?.controller!.view.removeGestureRecognizer(tapper!)
            }
        }
        pollMessageCell?.changeChoice(text: textView.text!, index: index)
    }
    
    func endEditingWithTouch() {
        choiceTextField.resignFirstResponder()
    }
}

// Table cell which contains a simple "add choice" button
// This cell is only available to the user when it is creating the poll.
class AddNewChoiceTableViewCell : UITableViewCell {
    
    @IBOutlet weak var addButton: UIView!
    
    weak var pollMessageCell : PollMessageCell?
    
    func initialize(cell: PollMessageCell) {
        pollMessageCell = cell
    }
    
    @IBAction func pushButton(_ sender: Any) {
        pollMessageCell?.addChoice()
    }
}

// Table cell which display the result of the vote.
// It shows either the participation to the current vote
// or the current vote tally for a given option.
class ResultVoteTableViewCell : UITableViewCell {
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var choiceLabel: UILabel!
    @IBOutlet weak var choicePercent: UILabel!
    
    func initialize(cell: PollMessageCell, index: Int) {
        let formater = NumberFormatter()
        formater.maximumFractionDigits = 0
        
        let pollData = cell.data!.pollData!
        if( index == 0 ) {
            choiceLabel.text = "Participation:"
            let ratio = Float(pollData.nb_votes)/Float(pollData.nb_total_votes)
            choicePercent.text = formater.string(from: NSNumber(value: ratio*Float(100)))! + "%"
            progressView.progress = ratio
        } else {
            choiceLabel.text = pollData.elements[index-1].label
            let ratio = Float(pollData.elements[index-1].nb_votes)/Float(pollData.nb_votes)
            choicePercent.text = formater.string(from: NSNumber(value: ratio*Float(100)))! + "%"
            progressView.progress = ratio
        }
    }
}

// The table view data source for a Poll: one row per choice, and a summary row/add choice row.
class PollMessageData : NSObject, UITableViewDataSource {
    var pollData : PollData!
    enum State { case creating, voting, voted }
    var state : State
    weak var controller : MessagesViewController?
    weak var pollMessageCell: PollMessageCell?
    
    init(data: PollData, state: State, ctrler: MessagesViewController?, cell: PollMessageCell) {
        self.pollData = data
        self.state = state
        self.controller = ctrler
        self.pollMessageCell = cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let n = pollData.elements.count
        return (state == .creating || state == .voted) ? n+1 : n
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        switch state {
        case .creating :
            if( row == pollData.elements.count ) {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddNewChoiceTableViewCell") as! AddNewChoiceTableViewCell
                cell.initialize(cell: pollMessageCell!)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "EditChoiceTableViewCell") as! EditChoiceTableViewCell
                cell.initialize(cell: pollMessageCell!, index: row)
                return cell
            }
        case .voting:
            let cell = tableView.dequeueReusableCell(withIdentifier: "VotingTableViewCell") as! VotingTableViewCell
            cell.initialize(cell: pollMessageCell!, index: row)
            return cell
        case .voted:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ResultVoteTableViewCell") as! ResultVoteTableViewCell
            cell.initialize(cell: pollMessageCell!, index: row)
            cell.isUserInteractionEnabled = false
            return cell
        }
    }
}

// Listen to new PollRecord notifications.
class PollModelView : ModelView {
    weak var cell : PollMessageCell?
    
    init(cell: PollMessageCell) {
        self.cell = cell
        super.init()
        
        self.notify_new_poll_record = new_poll_record
    }
    
    func new_poll_record(record: PollRecord) {
        cell?.update()
    }
}

// CollectionViewCell part of the family of Message cells.
// Contains the usual icon, fromLabel.
// Contains the poll title (main message text) and a UITableView for the poll choices.

class PollMessageCell : UICollectionViewCell, MessageBaseCellDelegate {
    weak var controller: MessagesViewController?
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var labelView: UIView!
    @IBOutlet weak var pollTitle: UILabel!
    @IBOutlet weak var votingTableView: UITableView!
    @IBOutlet weak var submitButton: UIButton!
    
    var data: PollMessageData?
    var message: Message?
    var view : PollModelView?
    var pollRecord : PollRecord?
    
    deinit {
        if( view != nil ) {
            model.removeViews(views: [view!])
        }
    }
    
    func userIcon() -> UIImageView? {
        return iconView
    }
    func containerView() -> UIView? {
        return labelView
    }
    
    func initialize(message: Message, controller : MessagesViewController?) {
        self.message = message
        self.controller = controller
        
        pollTitle.text = message.text
        fromLabel.text = getFromName(message: message)
        
        let bg = ColorPalette.backgroundColor(message: message)
        labelView.backgroundColor = bg

        let editMode =  (message.user_id.id == model.me().id.id &&
            controller?.data?.messages.last === message)
        

        model.getPollVotes(poll: message, completion: { (records) in
            DispatchQueue.main.async(execute: {
                if( controller == nil ) {
                    return
                }
                let pollData = PollData(pollRecords: records, message: message, options: controller!.curMessageOption)
                var state : PollMessageData.State
                if( pollData.alreadyVoted ) {
                    // Readonly view of the poll.
                    state = .voted
                    if( pollData.nb_votes != pollData.nb_total_votes ) {
                        // Attach an observer to the poll
                        self.view = PollModelView(cell: self)
                        model.setupNotificationsForPoll(pollId: message.id, view: self.view!)
                    } else {
                        model.db_model.removePollRecordNotification(pollId: message.id)
                    }
                    self.submitButton.isHidden = true
                } else {
                    if( editMode ) {
                        // The poll is in creation mode, curMessage, curMessageOption have been set already
                        state = .creating
                        self.pollRecord = controller?.curMessageOption?.pollRecord
                        self.submitButton.isHidden = true
                    } else {
                        state = .voting
                        self.pollRecord = PollRecord(
                            id: RecordId(), user_id: model.me().id, poll_id: message.id, checked_option: -1
                        )
                        self.submitButton.isHidden = false
                    }
                }
                self.data = PollMessageData(data: pollData, state: state, ctrler: controller, cell: self)
                self.votingTableView.dataSource = self.data
                self.votingTableView.reloadData()
            })
        })
        
    }
    
    func addChoice() {
        // Add a new choice to the poll.
        let newChoice = "choice #\(data!.pollData.elements.count+1)"
        
        // Synchronize option and message
        controller?.curMessageOption?.pollOptions.append(newChoice)
        controller?.curMessage?.options = controller?.curMessageOption?.getString() ?? ""
        
        // Synchronize table.
        data!.pollData.elements.append((label: newChoice, nb_votes: 0))
        self.votingTableView.reloadData()
    }
    
    func selectChoice(_ index: Int) {
        // Unselect any other
        for i in 0 ..< data!.pollData.elements.count {
            if( i == index ) {
                continue
            }
            let cell = votingTableView.cellForRow(at: IndexPath(row: i, section: 0))
            let votingCell = cell as? VotingTableViewCell
            if( votingCell != nil ) {
                votingCell!.checkButton.isSelected = false
            }
            let editingVotingCell = cell as? EditChoiceTableViewCell
            if( editingVotingCell != nil ) {
                editingVotingCell!.checkButton.isSelected = false
            }
        }
        pollRecord?.checked_option = index
        if( controller != nil ) {
           controller!.sendButton.isEnabled = !controller!.textView.text.isEmpty
        }
    }
    
    func changeChoice(text: String, index: Int) {
        // Update label inside table data
        data?.pollData.elements[index].label = text
        
        // Synchronize option and message
        controller?.curMessageOption?.pollOptions[index] = text
        controller?.curMessage?.options = controller?.curMessageOption?.getString() ?? ""
    }
    
    func update() {
        // When a new Vote is cast, update the voted view.
        if( controller == nil || message == nil ) {
            return
        }
        model.getPollVotes(poll: self.message!, completion: { (records) in
            DispatchQueue.main.async(execute: {
                let pollData = PollData(pollRecords: records, message: self.message!, options: nil)
                self.data?.pollData = pollData
                self.votingTableView.reloadData()
            })
        })
    }
    
    @IBAction func submitVote(_ sender: Any) {
        if( pollRecord != nil ) {
            model.savePollVote(pollRecord: pollRecord!)
            
            if( controller != nil && controller!.data != nil ) {
                controller!.audioPlayer.play()
                
                let messageIndex = controller!.data!.messages.index(where: { (m) -> Bool in
                    m.id == message!.id
                })
                if( messageIndex != nil ) {
                    let indexPath = IndexPath(row: messageIndex!, section: 0)
                    controller!.messagesView.reloadItems(at: [indexPath])
                }
            }
        }
    }
}

// Compute the height of the message in function of the number of pollOptions.

class PollMessageCellSizeDelegate : MessageBaseCellSizeDelegate {
    func size(message: Message, collectionView: UICollectionView) -> CGSize {
        let hspacing : CGFloat = 10
        let width = collectionView.bounds.width - 2*hspacing
        
        let options = MessageOptions(options: message.options)
        let count = max(3, options.pollOptions.count+1)
        
        let attributes: [String : Any] = [NSFontAttributeName: UIFont.systemFont(ofSize: 17)]
        
        let height = max(message.text.size(attributes: attributes).height, 28)
        
        let heightFromLabels : CGFloat = 16 + height
        let vspacing : CGFloat = 5

        return CGSize(width: width, height: CGFloat(count)*height + heightFromLabels + 4*vspacing + CGFloat(count)*vspacing)
    }
}
