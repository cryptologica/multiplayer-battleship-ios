//
//  GameViewController.swift
//  Project3
//
//  Created by JT Newsome on 3/18/16.
//  Copyright © 2016 JT Newsome. All rights reserved.
//

import UIKit

protocol LobbyViewControllerDelegate: class {
    
    func sendDataToLobbyView(sender: GameViewController, game: Game, gameIndex: Int)
}

class GameViewController: UIViewController, GameViewControllerDelegate {
    
    weak var delegate: LobbyViewControllerDelegate? = nil
    
    var parent: LobbyViewController?
    
    private var gameView: GameView! {
        return (view as! GameView)
    }
    
    override func loadView() {
        view = GameView(frame: CGRectZero)
        print("Loaded: GameViewController")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Game"
        
        gameView.toggleAttackBoardBtn?.addTarget(self, action: #selector(GameViewController.toggleAttackBoardBtnClicked), forControlEvents: .TouchDown)
    }
    
    override func viewDidAppear(anim: Bool) {
        
        if (gameView.currentGame.gameStatus == "DONE") {
            displaySummary()
        }
        else if (gameView.currentGame.gameStatus == "WAITING") {
            if gameView.currPlayer.isTurn == false {
                
            }
            NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector:  #selector(GameViewController.checkGameStatus), userInfo: nil, repeats: true)
            gameView.shipBeingPlaced!.text = "Waiting for another player..."
        }
        else if (gameView.currentGame.gameStatus == "PLAYING") {
            
            // Check if this game isn't ours
            if gameView.currentGame.player1?.playerID == "" && gameView.currentGame.player2?.playerID == "" {
                displaySummary()
                return
            }
            
            populateSitRepBoard()
            
            // It's ours, is it our turn?
            if gameView.currPlayer.isTurn == false {
                NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector:  #selector(GameViewController.checkGameStatus), userInfo: nil, repeats: true)
                gameView.shipBeingPlaced!.text = "Waiting for opponent..."
            }
            else {
                gameView.shipBeingPlaced!.text = "Choose A Cell to Attack"
                gameView.toggleAttackBoardBtn?.setTitle("Open SitRep Board", forState: .Normal)
            }
        }
        
        // Make sure it's saved to file
        print("Sending Update to Lobby")
        self.delegate = self.parent
        delegate?.sendDataToLobbyView(self, game: gameView.currentGame, gameIndex: gameView.gameIndex!)
    }
    
    // Gets called when Lobby sends us selected Game
    func sendDataToGameView(sender: LobbyViewController, game: Game, gameIndex: Int) {
        print("Game View: Received Data From Lobby")
        parent = sender
        gameView.currentGame = game
        gameView.gameIndex = gameIndex
        gameView.currentGame.placementIndex = game.placementIndex
    }
    
    func displaySummary() {
        let theGameId = gameView.currentGame.gameID
        let str = "http://battleship.pixio.com/api/games/\(theGameId!)"
        let url: NSURL = NSURL(string: str)!
        let request = NSMutableURLRequest(URL: url)
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)
        
        let task = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) in
            
            if data == nil {
                self.displayConfirmDialog("Error", message: "No data was receieved from the server. Please try again.")
                return
            }
            
            guard let httpResponse = response as? NSHTTPURLResponse else {
                self.displayConfirmDialog("Error", message: "Received invalid response")
                return
            }
            
            let status = httpResponse.statusCode
            if status < 200 || status >= 300 {
                self.displayConfirmDialog("Error", message: "Server returned error status code \(status). Please try again.")
                return
            }
            
            if httpResponse.MIMEType != "application/json" {
                self.displayConfirmDialog("Error", message: "Received invalid data. Please try again.")
                return
            }
            
            let data = try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions())
            guard let gameDetails = data as? [String: AnyObject] else {
                self.displayConfirmDialog("Error", message: "Retrieved data was invalid. Please try again.")
                return
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                let winner = gameDetails["winner"] as? String
                let numAttacks = gameDetails["missilesLaunched"] as? Int
                let title = "Summary"
                var message = ""
                if winner == "IN PROGRESS" {
                    message = "Game is in progress. There have been \(numAttacks!) missile launches."
                }
                else {
                    message = "\(winner!) has won! There were \(numAttacks!) missile launches."
                }
                self.displayConfirmDialog(title, message: message)
                self.gameView.shipBeingPlaced?.hidden = true
                self.gameView.toggleAttackBoardBtn?.hidden = true
            })
        });
        
        task.resume()
    }
    
    func checkGameStatus(timer: NSTimer) {
        let theGameId = gameView.currentGame.gameID
        let str = "http://battleship.pixio.com/api/games/\(theGameId!)/status"
        let url: NSURL = NSURL(string: str)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)
        
        let params = ["playerId":gameView.currPlayer.playerID!] as Dictionary<String, String>
        
        request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(params, options: NSJSONWritingOptions())
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) in
            
            if data == nil {
                self.displayConfirmDialog("Error", message: "No data was receieved from the server. Please try again.")
                return
            }
            
            guard let httpResponse = response as? NSHTTPURLResponse else {
                self.displayConfirmDialog("Error", message: "Received invalid response")
                return
            }
            
            let status = httpResponse.statusCode
            if status < 200 || status >= 300 {
                self.displayConfirmDialog("Error", message: "Server returned error status code \(status). Please try again.")
                return
            }
            
            if httpResponse.MIMEType != "application/json" {
                self.displayConfirmDialog("Error", message: "Received invalid data. Please try again.")
                return
            }
            
            let data = try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions())
            guard let gameDetails = data as? [String: AnyObject] else {
                self.displayConfirmDialog("Error", message: "Retrieved data was invalid. Please try again.")
                return
            }
            
            let isYourTurn: Bool = gameDetails["isYourTurn"] as! Bool
            let winner: String = gameDetails["winner"] as! String
            
            if winner != "IN PROGRESS" {
                print("Game has finished.")
                timer.invalidate()
                dispatch_async(dispatch_get_main_queue(), {
                    self.gameView.currentGame.gameStatus = "DONE"
                    self.displayConfirmDialog("Game Over", message: "\(winner) has won!")
                    self.gameView.showAttackBoard = false
                    self.gameView.toggleAttackBoardBtn?.hidden = true
                    self.gameView.shipBeingPlaced!.text = "GAME OVER"
                    self.gameView.currPlayer.isTurn = false
                    self.gameView.myOpponent.isTurn = false
                })
            }
            else if isYourTurn {
                print("It's our turn now!")
                timer.invalidate()
                dispatch_async(dispatch_get_main_queue(), {
                    self.populateSitRepBoard()
                    self.gameView.currentGame.gameStatus = "PLAYING"
                    self.gameView.currPlayer.isTurn = true
                    self.gameView.myOpponent.isTurn = false
                    self.displayConfirmDialog("Your Turn", message: "")
                    self.gameView.showAttackBoard = true
                    self.gameView.toggleAttackBoardBtn?.hidden = false
                    self.gameView.shipBeingPlaced!.text = "Choose A Cell to Attack"
                    self.gameView.toggleAttackBoardBtn?.setTitle("Open SitRep Board", forState: .Normal)
                })
            }
        });
        
        task.resume()
    }
    
    func wasHit(coor: Coordinate) -> (wasHit: Bool, didSink: Int) {
        var isHit: Bool = false
        var didSink: Int = 0
        
        let theGameId = gameView.currentGame.gameID
        let str = "http://battleship.pixio.com/api/games/\(theGameId!)/guess"
        let url: NSURL = NSURL(string: str)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)
        
        let params = ["playerId":gameView.currPlayer.playerID!, "xPos":coor.x, "yPos":coor.y] as Dictionary<String, AnyObject>
        
        request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(params, options: NSJSONWritingOptions())
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) in
            
            if data == nil {
                self.displayConfirmDialog("Error", message: "No data was receieved from the server. Please try again.")
                return
            }
            
            guard let httpResponse = response as? NSHTTPURLResponse else {
                self.displayConfirmDialog("Error", message: "Received invalid response")
                return
            }
            
            let status = httpResponse.statusCode
            if status < 200 || status >= 300 {
                self.displayConfirmDialog("Error", message: "Server returned error status code \(status). Please try again.")
                return
            }
            
            if httpResponse.MIMEType != "application/json" {
                self.displayConfirmDialog("Error", message: "Received invalid data. Please try again.")
                return
            }
            
            let data = try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions())
            guard let gameDetails = data as? [String: AnyObject] else {
                self.displayConfirmDialog("Error", message: "Retrieved data was invalid. Please try again.")
                return
            }
            
            isHit = gameDetails["hit"] as! Bool
            didSink = gameDetails["shipSunk"] as! Int
            
            });
        
        task.resume()
        return (isHit, didSink)
    }
    
    func populateSitRepBoard() {
        let theGameId = gameView.currentGame.gameID
        let str = "http://battleship.pixio.com/api/games/\(theGameId!)/board"
        let url: NSURL = NSURL(string: str)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)
        
        let params = ["playerId":gameView.currPlayer.playerID!] as Dictionary<String, AnyObject>
        
        request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(params, options: NSJSONWritingOptions())
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) in
            
            if data == nil {
                self.displayConfirmDialog("Error", message: "No data was receieved from the server. Please try again.")
                return
            }
            
            guard let httpResponse = response as? NSHTTPURLResponse else {
                self.displayConfirmDialog("Error", message: "Received invalid response")
                return
            }
            
            let status = httpResponse.statusCode
            if status < 200 || status >= 300 {
                self.displayConfirmDialog("Error", message: "Server returned error status code \(status). Please try again.")
                return
            }
            
            if httpResponse.MIMEType != "application/json" {
                self.displayConfirmDialog("Error", message: "Received invalid data. Please try again.")
                return
            }
            
            let data = try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions())
            guard let gameDetails = data as? [String: AnyObject] else {
                self.displayConfirmDialog("Error", message: "Retrieved data was invalid. Please try again.")
                return
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                let playerBoard = gameDetails["playerBoard"] as? [[String: AnyObject]]
                let opponentBoard = gameDetails["opponentBoard"] as? [[String: AnyObject]]
                
                // Update Our Board
                var shipCoors = [Coordinate]()
                self.gameView.currPlayer.missedCoordinates?.removeAll()
                self.gameView.currPlayer.hitCoordinates?.removeAll()
                self.gameView.currPlayer.shipList?.removeAll()
                for coor in playerBoard! {
                    let xPos = coor["xPos"] as? Int
                    let yPos = coor["yPos"] as? Int
                    let newCoor = Coordinate(x: xPos!, y: yPos!)
                    let status = coor["status"] as? String
                    
                    if status == "MISS" {
                        self.gameView.currPlayer.missedCoordinates?.append(newCoor)
                    }
                    else if status == "HIT" {
                        self.gameView.currPlayer.hitCoordinates?.append(newCoor)
                    }
                    else if status == "SHIP" {
                        shipCoors.append(newCoor)
                    }
                }
                self.gameView.currPlayer.shipList? = [Ship(shipCoors: shipCoors)]
                
                // Update Opponent Board
                self.gameView.myOpponent.missedCoordinates?.removeAll()
                self.gameView.myOpponent.hitCoordinates?.removeAll()
                self.gameView.myOpponent.shipList?.removeAll()
                for coor in opponentBoard! {
                    let xPos = coor["xPos"] as? Int
                    let yPos = coor["yPos"] as? Int
                    let newCoor = Coordinate(x: xPos!, y: yPos!)
                    let status = coor["status"] as? String

                    if status == "MISS" {
                        self.gameView.myOpponent.missedCoordinates?.append(newCoor)
                    }
                    else if status == "HIT" {
                        self.gameView.myOpponent.hitCoordinates?.append(newCoor)
                    }
                }
                
                self.gameView.setNeedsDisplay()
            })
        });
        
        task.resume()
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)
        
        let touch: UITouch = touches.first!
        let touchPoint: CGPoint = touch.locationInView(gameView)
        let cellCoordinate: Coordinate = getCellCoordinate(touchPoint)
        
        print("Cell Touched: (\(touchPoint.x), \(touchPoint.y))")
        print("Activate Cell: (\(cellCoordinate.x), \(cellCoordinate.y))")
        
        // Game over?
        if (gameView.currentGame.gameStatus == "DONE") {
            displaySummary()
            return
        }
        
        // Game not started yet
        if (gameView.currentGame.gameStatus == "WAITING") {
            return
        }
        
        // Not our turn
        if (gameView.currPlayer.isTurn == false) {
            return
        }
        
        // Don't do anything unless click was inside grid
        if (isValidTouch(touchPoint) == true) {
            print("Valid Cell Touched")

            // Play Phase
            if (gameView.currentGame.gameStatus == "PLAYING") {
                
                // Must be on Attack Board to attack
                if (gameView.showAttackBoard == true) {
                    
                    // Must be empty
                    if (checkCellIsEmpty(cellCoordinate)) {

                        var isHit: Bool = false
                        var didSink: Int = 0
                        
                        let theGameId = gameView.currentGame.gameID
                        let str = "http://battleship.pixio.com/api/games/\(theGameId!)/guess"
                        let url: NSURL = NSURL(string: str)!
                        let request = NSMutableURLRequest(URL: url)
                        request.HTTPMethod = "POST"
                        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
                        let session = NSURLSession(configuration: config)
                        
                        let params = ["playerId":gameView.currPlayer.playerID!, "xPos":cellCoordinate.x, "yPos":cellCoordinate.y] as Dictionary<String, AnyObject>
                        
                        request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(params, options: NSJSONWritingOptions())
                        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                        request.addValue("application/json", forHTTPHeaderField: "Accept")
                        
                        let task = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) in
                            
                            if data == nil {
                                self.displayConfirmDialog("Error", message: "No data was receieved from the server. Please try again.")
                                return
                            }
                            
                            guard let httpResponse = response as? NSHTTPURLResponse else {
                                self.displayConfirmDialog("Error", message: "Received invalid response")
                                return
                            }
                            
                            let status = httpResponse.statusCode
                            if status < 200 || status >= 300 {
                                self.displayConfirmDialog("Error", message: "Server returned error status code \(status). Please try again.")
                                return
                            }
                            
                            if httpResponse.MIMEType != "application/json" {
                                self.displayConfirmDialog("Error", message: "Received invalid data. Please try again.")
                                return
                            }
                            
                            let data = try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions())
                            guard let gameDetails = data as? [String: AnyObject] else {
                                self.displayConfirmDialog("Error", message: "Retrieved data was invalid. Please try again.")
                                return
                            }
                            
                            isHit = gameDetails["hit"] as! Bool
                            didSink = gameDetails["shipSunk"] as! Int
                            
                            dispatch_async(dispatch_get_main_queue(), {
                                // HIT
                                if isHit {
                                    if didSink > 0 {
                                        self.displayConfirmDialog("Hit", message: "A ship of length \(didSink) was hit and sunk!")
                                    }
                                    else {
                                        self.displayConfirmDialog("Hit", message: "A ship was hit but not sunk!")
                                    }
                                    
                                    self.gameView.myOpponent.hitCoordinates?.append(cellCoordinate)
                                    self.gameView.shipBeingPlaced!.text = "Waiting for opponent..."
                                }
                                // MISS
                                else {
                                    self.displayConfirmDialog("Miss", message: "")
                                    self.gameView.myOpponent.missedCoordinates?.append(cellCoordinate)
                                }
                                
                                // Update and save
                                self.gameView.shipBeingPlaced!.text = "Waiting for opponent..."
                                self.gameView.currPlayer.isTurn = false
                                self.gameView.myOpponent.isTurn = true
                                self.delegate?.sendDataToLobbyView(self, game: self.gameView.currentGame, gameIndex: self.gameView.gameIndex!)
                                self.gameView.setNeedsDisplay()
                                NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector:  #selector(GameViewController.checkGameStatus), userInfo: nil, repeats: true)
                            })
                        });
                        
                        task.resume()
                     }
                }
            }
            
        }
    }
    
    // MARK: Helper Methods
    
    // Display a prompt with the given title and message
    func displayConfirmDialog(title: String, message: String) {
        dispatch_async(dispatch_get_main_queue(), {
            self.delegate?.sendDataToLobbyView(self, game: self.gameView.currentGame, gameIndex: self.gameView.gameIndex!)
            let refreshAlert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            refreshAlert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction!) in
                self.gameView.setNeedsDisplay()
            }))
            let subview = refreshAlert.view.subviews.first! as UIView
            let alertContentView = subview.subviews.first! as UIView
            alertContentView.backgroundColor = UIColor.whiteColor()
            alertContentView.tintColor = UIColor.darkGrayColor()
            self.presentViewController(refreshAlert, animated: true, completion: nil)
        })
    }
    
    func toggleAttackBoardBtnClicked() {
        if (gameView.showAttackBoard == true) {
            gameView.toggleAttackBoardBtn?.setTitle("Open Attack Board", forState: .Normal)
            gameView.showAttackBoard = false
            gameView.shipBeingPlaced?.hidden = true
            gameView.setNeedsDisplay()
        }
        else {
            gameView.toggleAttackBoardBtn?.setTitle("Open SitRep Board", forState: .Normal)
            gameView.showAttackBoard = true
            gameView.setNeedsDisplay()
            gameView.shipBeingPlaced?.hidden = false
        }
    }
    
    func didWin() -> Bool {
        if (gameView.myOpponent.numShipsAlive == 0) {
            return true
        }
        else {
            return false
        }
    }
    
    func willSinkShip(cell: Coordinate) -> Bool {
        // Find the ship that coordinate is in
        let arr = gameView.myOpponent.shipList
        var shipIndex: Int
        for (shipIndex = 0; shipIndex < arr!.count; shipIndex += 1) {
            let ship: Ship = arr![shipIndex]
            for var index = 0; index < ship.count; index += 1 {
                let coor: Coordinate = ship.getAtIndex(index)
                // Found which ship
                if (coor.x == cell.x && coor.y == cell.y) {
                    // Calculate how many cells aren't already hit on that ship
                    var count = 0
                    let ship = gameView.myOpponent.shipList![shipIndex]
                    for var index=0; index < ship.count; index += 1 {
                        if ((containsTempCoordinate(gameView.myOpponent.hitCoordinates!, c: ship[index]) >= 0) == true) {
                            count += 1
                        }
                    }
                    count = gameView.myOpponent.shipList![shipIndex].count - count
                    // If there's only 1 un-hit cell on that ship then it will sink
                    if (count == 1) {
                        return true
                    }
                    else {
                        return false
                    }
                }
            }
        }
        return false
    }
    
    // Checks that ships are placed vert/horiz only
    // Pass in the last cell that was placed and the to-be-placed cell
    func isPlacementAddValid(addedCells: [Coordinate], currCell: Coordinate) -> Bool {
        var validCells: [Coordinate] = [Coordinate]()
        
        // Ambiguous If Vert or Horiz
        if (addedCells.count == 1) {
            let lastCell: Coordinate = addedCells[0]
            validCells.append(Coordinate(x: lastCell.x + 1, y: lastCell.y))
            validCells.append(Coordinate(x: lastCell.x - 1, y: lastCell.y))
            validCells.append(Coordinate(x: lastCell.x, y: lastCell.y + 1))
            validCells.append(Coordinate(x: lastCell.x, y: lastCell.y - 1))
        }
        else if (addedCells.count > 1) {
            let firstCell: Coordinate = addedCells[0]
            let nextCell: Coordinate = addedCells[1]
            
            // Is Horizontal
            if (firstCell.x - nextCell.x != 0) {
                var minXCell: Coordinate = firstCell
                var maxXCell: Coordinate = firstCell
                for cell in addedCells {
                    if (cell.x < minXCell.x) {
                        minXCell = cell
                    }
                    if (cell.x > maxXCell.x) {
                        maxXCell = cell
                    }
                }
                validCells.append(Coordinate(x: minXCell.x - 1, y: minXCell.y))
                validCells.append(Coordinate(x: maxXCell.x + 1, y: maxXCell.y))
            }
            // Is Vertical
            else {
                var minYCell: Coordinate = firstCell
                var maxYCell: Coordinate = firstCell
                for cell in addedCells {
                    if (cell.y < minYCell.y) {
                        minYCell = cell
                    }
                    if (cell.y > maxYCell.y) {
                        maxYCell = cell
                    }
                }
                validCells.append(Coordinate(x: minYCell.x, y: minYCell.y - 1))
                validCells.append(Coordinate(x: maxYCell.x, y: maxYCell.y + 1))
            }
        }
        
        if (containsTempCoordinate(validCells, c: currCell) >= 0) {
            return true
        }
        else {
            return false
        }
    }
    
    func checkCellIsEmpty(cell: Coordinate) -> Bool {
        let isMiss = (containsTempCoordinate(gameView.myOpponent.missedCoordinates!, c: cell) >= 0)
        let isHit = (containsTempCoordinate(gameView.myOpponent.hitCoordinates!, c: cell) >= 0)
        if (isMiss == false && isHit == false) {
            return true
        }
        return false
    }
    
    // Returns index if the array contains given coordinate
    // Returns -1 if it does not contain it
    func containsCoordinate(arr: [Ship], c: Coordinate) -> Int {
        
        for var shipIndex = 0; shipIndex < arr.count; shipIndex += 1 {
            let ship: Ship = arr[shipIndex] as Ship
            for var index = 0; index < ship.count; index += 1 {
                let coor: Coordinate = ship.getAtIndex(index)
                if (coor.x == c.x && coor.y == c.y) {
                    return index
                }
            }
        }
        return -1
    }
    
    func containsTempCoordinate(coors: [Coordinate], c: Coordinate) -> Int {
        for var index = 0; index < coors.count; index += 1 {
            let coor: Coordinate = coors[index]
            if (coor.x == c.x && coor.y == c.y) {
                return index
            }
        }
        return -1
    }
    
    func getCellCoordinate(point: CGPoint) -> Coordinate {
        
        let coordinate: Coordinate = Coordinate(x: 0, y: 0)
        var x1 = point.x
        var y1 = point.y - 115
        
        var count: Int = -1
        repeat {
            x1 = x1 - gameView.cellEdgeLength
            count += 1
        }
        while x1 > 0
        coordinate.x = count
        
        count = 10
        repeat {
            y1 = y1 + gameView.cellEdgeLength
            count -= 1
        }
        while y1 < (gameView.cellEdgeLength * 10)
        coordinate.y = count
        
        return coordinate
    }
    
    func isValidTouch(point: CGPoint) -> Bool {
        if (point.x < 0 || point.x > 320) {
            return false
        }
        else if (point.y < 115 || point.y > 435) {
            return false
        }
        else {
            return true
        }
    }

}
