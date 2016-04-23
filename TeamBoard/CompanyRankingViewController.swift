//
//  CompanyRankingViewController.swift
//  TeamBoard
//
//  Created by Henrique Valcanaia on 4/1/16.
//  Copyright © 2016 MC. All rights reserved.
//

import UIKit

func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}

class CompanyRankingViewController: UIViewController {
    
    @IBOutlet weak var companyName: UILabel!
    @IBOutlet weak var tableView: TBOTableView!
    
    // MARK: - THE GAMBI, THE MAGIC, THE DARKNESS, THE POWER, THE UNKNOWN, THE ~DO NOT TOUCH~ PIECE OF SHIT
    var expandedIndexPath = NSIndexPath(forRow: -1, inSection: 0) {
        willSet {
            self.retractExpandedCell()
        }
        
        didSet {
            self.expandCell()
        }
    }
    var boards = [TBOBoard]()
    var count = 0
    var changeFocus = false
    var organization:TBOOrganization!
    var interactionController = TBOInteractionController()
    var interactionCheckTimer: NSTimer?
    var isFirstAction = true
    
    enum InteractionState {
        case Active
        case WaitingForInteraction
        case Inactive
    }
    
    private let expandedCellTime:UInt32 = 1
    private let interactionCheckTime:NSTimeInterval = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        companyName.text = organization.name
        
        //        tableViewConfiguration()
        createGestureRecognizers()
        loadData {
            self.tableView.reloadData()
            self.resetTimer()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "gotoMembers") {
            let membersView = (segue.destinationViewController) as! MembersViewController
            membersView.board = boards[expandedIndexPath.row]
        }
    }
    
    // MARK: Private helpers
    private func loadData(completionBlock:(()->())?) {
        tableView.showLoader()
        TrelloManager.sharedInstance.getBoards(organization!.id!) { (boards, error) in
            guard let boards = boards where error == nil else {
                self.showUnknownError()
                return
            }
            for board in boards {
                TrelloManager.sharedInstance.getBoard(board.id!, completionHandler: { (board, error) in
                    guard let board = board where error == nil else {
                        // self.showUnknownError()
                        return
                    }
                    self.boards += [board]
                    
                    TrelloManager.sharedInstance.getCardsFromBoard(board.id!) { (cards, error) in
                        guard let cards = cards where error == nil else {
                            // self.showUnknownError()
                            return
                        }
                        self.count += 1
                        board.cards = cards
                        board.matchPointsWithMembers(cards)
                        if(self.count == boards.count) {
                            let orderedArray = self.boards.sort {
                                ($0).totalPoints > ($1).totalPoints
                            }
                            board.members?.sortInPlace { $0.points > $1.points }
                            
                            self.boards.removeAll()
                            self.boards = orderedArray
                            self.tableView.hideLoader()
                            completionBlock?()
                        }
                    }
                })
            }
        }
    }
    
    private func createGestureRecognizers() {
        let swipeUp:UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipedUp))
        swipeUp.direction = .Up
        view.addGestureRecognizer(swipeUp)
        
        let swipeDown:UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipedDown))
        swipeDown.direction = .Down
        view.addGestureRecognizer(swipeDown)
    }
    
    private func expandCell() {
        tableView.beginUpdates()
//        cell.teamName.hidden = false
//        cell.view.hidden = false
        let board = boards[expandedIndexPath.row]
        let cell = tableView.cellForRowAtIndexPath(expandedIndexPath) as! TBOCell
        cell.expandCellWithMembers(board.members!, andPoints: board.totalPoints)
        tableView.endUpdates()
        
        // MARK: - THE GAMBI, THE MAGIC, THE DARKNESS, THE POWER, THE UNKNOWN, THE ~DO NOT TOUCH~ PIECE OF SHIT
        let delayTime = Double(board.members!.count) * 0.1
        delay(delayTime) {
            cell.showViewWithCompletionBlock({ (suc) in
                // do nothing
            })
        }
    }
    
    private func retractExpandedCell() {
        // MARK: - THE GAMBI, THE MAGIC, THE DARKNESS, THE POWER, THE UNKNOWN, THE ~DO NOT TOUCH~ PIECE OF SHIT
        if let cell = tableView.cellForRowAtIndexPath(expandedIndexPath) as? TBOCell {
            cell.hideViewWithCompletionBlock({ (suc) in
                cell.retract()
            })
        }
    }
    
    @objc private func updateExpandIndexPathToNextCell() {
        let row = (expandedIndexPath.row == boards.count-1) ? 0 : expandedIndexPath.row + 1
        let section = expandedIndexPath.section
        expandedIndexPath = NSIndexPath(forRow: row, inSection: section)
    }
    
    private func resetTimer() {
        interactionCheckTimer?.invalidate()
        interactionCheckTimer = NSTimer.scheduledTimerWithTimeInterval(interactionCheckTime, target: self, selector: #selector(updateExpandIndexPathToNextCell), userInfo: nil, repeats: true)
    }
    
    func swipedUp(sender: UISwipeGestureRecognizer){
        print("swiped up")
        let row = (expandedIndexPath.row == 0) ? boards.count-1 : expandedIndexPath.row - 1
        let section = expandedIndexPath.section
        expandedIndexPath = NSIndexPath(forRow: row, inSection: section)
        resetTimer()
    }
    
    func swipedDown(sender:UISwipeGestureRecognizer){
        print("swiped down")
        let row = (expandedIndexPath.row == boards.count-1) ? 0 : expandedIndexPath.row + 1
        let section = expandedIndexPath.section
        expandedIndexPath = NSIndexPath(forRow: row, inSection: section)
        resetTimer()
    }
    
    func showUnknownError(){
        let errorRequest = UIAlertController(title: "Ops..", message: "Check your connection.", preferredStyle: .Alert)
        let errorRequestReloadAction = UIAlertAction(title: "Reload", style: .Default) { (reloadAction) in
            self.loadData {
                self.tableView.reloadData()
                self.resetTimer()
            }
        }
        
        errorRequest.addAction(errorRequestReloadAction)
        self.presentViewController(errorRequest, animated: true, completion: nil)
    }
}

extension CompanyRankingViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return boards.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! TBOCell
        cell.configCell(boards[indexPath.row], index: indexPath.row)
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("gotoMembers", sender: nil)
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if(indexPath.compare(expandedIndexPath) == NSComparisonResult.OrderedSame){
           if let members = boards[indexPath.row].members {
                return 100 + CGFloat(members.count * 90);
            }
        }
        return 89
    }
    
//    func tableView(tableView: UITableView, shouldUpdateFocusInContext context: UITableViewFocusUpdateContext) -> Bool {
//        if isFirstAction {
//            setAllNormalCells()
//        }
//        
//        if let focusedIndexPath = context.nextFocusedIndexPath,
//            let focusedCell = tableView.cellForRowAtIndexPath(focusedIndexPath) as? TBOCell {
//            var cellsToReload = [focusedIndexPath]
//            if let lastFocusedIndexPath = context.previouslyFocusedIndexPath,
//                let lastFocusedCell = tableView.cellForRowAtIndexPath(lastFocusedIndexPath) as? TBOCell {
//                normalCellBoard(lastFocusedCell)
//                //                lastFocusedCell.backgroundColor = UIColor.blueColor() // DEBUG UTIL
//                cellsToReload.append(lastFocusedIndexPath)
//                lastFocusedCell.layoutIfNeeded()
//                lastFocusedCell.setNeedsDisplay()
//                
//            }
//            expandedIndexPath = focusedIndexPath
//            expandCellBoard(focusedCell)
//            //            focusedCell.backgroundColor = UIColor.redColor() // DEBUG UTIL
//            focusedCell.layoutIfNeeded()
//            focusedCell.setNeedsDisplay()
//        }
//        return true
//    }
}

