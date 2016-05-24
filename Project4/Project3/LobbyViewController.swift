//
//  GameListViewController.swift
//  Project4
//
//  Created by JT Newsome on 3/18/16.
//  Copyright © 2016 JT Newsome. All rights reserved.

import UIKit

protocol GameViewControllerDelegate: class {
    
    func sendDataToGameView(sender: LobbyViewController, game: Game, gameIndex: Int)
}

class LobbyViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, LobbyViewControllerDelegate {
    
    weak var delegate: GameViewControllerDelegate? = nil
    
    var refreshControl: UIRefreshControl!
    var gameList: [Game] = []
    var loadedGameList: [Game] = []
    var tableView: UITableView = UITableView()
    let cellSpacingHeight: CGFloat = 1
    
    private var lobbyView: LobbyView! {
        return (view as! LobbyView)
    }
    
    override func loadView() {
        view = LobbyView(frame: CGRectZero)
        print("Loaded: LobbyViewController")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Lobby"
        
        if (gameList.count == 0) {
            let p1: Player = Player(isTurn: true)
            let p2: Player = Player(isTurn: false)
            let newGame: Game = Game(player1: p1, player2: p2, isAddTile: true, gameStatus: "NEWGAME", gameID: "", gameName: "")
            gameList.append(newGame)
        }
        
        let gameListRect = CGRectMake(10, 0, UIScreen.mainScreen().bounds.width - 20, UIScreen.mainScreen().bounds.height)
        tableView = UITableView(frame: gameListRect, style: UITableViewStyle.Grouped)
        
        tableView.backgroundColor = UIColor.darkGrayColor()
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = UIView()
        tableView.tableHeaderView = UIView()
        tableView.scrollEnabled = true
        tableView.bounces = true
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerClass(GameTableViewCell.self, forCellReuseIdentifier: NSStringFromClass(GameTableViewCell))
        
        view.addSubview(tableView)
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: #selector(LobbyViewController.loadGameListData), forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(self.refreshControl)
        
        loadGameListData()
        
        displayConfirmDialog("Hey there!", message: "Pull down to refresh the game list. Click 'New Game' to create a game. Click a game to join it or view its summary.")
    }
    
    override func viewDidAppear(animated: Bool) {
    }
    
    // Called upon receiving data from GameVC
    func sendDataToLobbyView(sender: GameViewController, game: Game, gameIndex: Int) {
        gameList[gameIndex] = game
        print("Received Update From Game")
        tableView.reloadData()
        saveData()
    }
    
    
    // MARK: Save/Load
    func saveData() {
        let data = NSKeyedArchiver.archivedDataWithRootObject(gameList)
        NSUserDefaults.standardUserDefaults().setObject(data, forKey: "gameListData")
    }
    
    func loadData() {
        if let data = NSUserDefaults.standardUserDefaults().objectForKey("gameListData") as? NSData {
            loadedGameList = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! [Game]
        }
    }
    
    func loadGameListData(){
        
        // Get data from server
        print("checking for game list updates")
        let url: NSURL = NSURL(string: "http://battleship.pixio.com/api/games")!
        let request = NSURLRequest(URL: url)
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
                self.displayConfirmDialog("Error", message: "Error \(status): Could not retrieve game list. Please try again.")
                return
            }
            
            if httpResponse.MIMEType != "application/json" {
                self.displayConfirmDialog("Error", message: "Received invalid data. Please try again.")
                return
            }
            
            var gameList = [Game]()
            let games = try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions())
            guard let gamesArray = games as? [[String: AnyObject]] else {
                self.displayConfirmDialog("Error", message: "Retrieved data was invalid. Please try again.")
                return
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                
                for game in gamesArray {
                    guard let tempId = game["id"] as? String else {
                        self.displayConfirmDialog("Error", message: "Retrieved data was invalid. Please try again.")
                        return
                    }
                    
                    guard let tempName = game["name"] as? String else {
                        self.displayConfirmDialog("Error", message: "Retrieved data was invalid. Please try again.")
                        return
                    }
                    
                    guard let tempStatus = game["status"] as? String else {
                        self.displayConfirmDialog("Error", message: "Retrieved data was invalid. Please try again.")
                        return
                    }
                    
                    let p1: Player = Player(isTurn: true)
                    let p2: Player = Player(isTurn: false)
                    let tempGame: Game = Game(player1: p1, player2: p2, isAddTile: false, gameStatus: tempStatus, gameID: tempId, gameName: tempName)
                    gameList.append(tempGame)
                }
            
                gameList = gameList.reverse()
                self.gameList.removeAll()
                let p1: Player = Player(isTurn: true)
                let p2: Player = Player(isTurn: false)
                let newGame: Game = Game(player1: p1, player2: p2, isAddTile: true, gameStatus: "NEWGAME", gameID: "", gameName: "")
                self.gameList.append(newGame)
                self.gameList.appendContentsOf(gameList)
                
                self.loadData()
                for game in self.loadedGameList {
                    
                    // Game was played on this device
                    if game.player1?.playerID != nil || game.player2?.playerID != nil {
                        if game.player1?.playerID != "" || game.player2?.playerID != "" {
                            // Find that game
                            for (index, g) in gameList.enumerate() {
                                if g.gameID == game.gameID {
                                    gameList[index].player1!.playerID = game.player1?.playerID
                                    gameList[index].player2!.playerID = game.player2?.playerID
                                }
                            }
                        }
                    }
                }
                
                self.tableView.reloadData()
                self.refreshControl.endRefreshing()
            })
            
        });
        
        task.resume()
    }
    
    // Display a prompt with the given title and message
    func displayConfirmDialog(title: String, message: String) {
        dispatch_async(dispatch_get_main_queue(), {
            let refreshAlert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            refreshAlert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction!) in
                self.lobbyView.setNeedsDisplay()
            }))
            let subview = refreshAlert.view.subviews.first! as UIView
            let alertContentView = subview.subviews.first! as UIView
            alertContentView.backgroundColor = UIColor.whiteColor()
            alertContentView.tintColor = UIColor.darkGrayColor()
            self.presentViewController(refreshAlert, animated: true, completion: nil)
        })
    }
    
    // MARK: Table: Game List
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(GameTableViewCell), forIndexPath: indexPath) as! GameTableViewCell
        
        cell.game = gameList[indexPath.section]
        
        if cell.game?.isAddTile == true {
            cell.gameStatusLabel.text = "New Game"
        }
        else {
            cell.gameStatusLabel.text = gameList[indexPath.section].gameStatus
            cell.gameNameLabel.text = gameList[indexPath.section].gameName
        }
        
        if cell.game?.gameStatus == "PLAYING" {
            cell.gameStatusLabel.textColor = UIColor.greenColor()
        }
        else if cell.game?.gameStatus == "WAITING" {
            cell.gameStatusLabel.textColor = UIColor.yellowColor()
        }
        else if cell.game?.gameStatus == "DONE" {
            cell.gameStatusLabel.textColor = UIColor.redColor()
        }
        else {
            cell.gameStatusLabel.textColor = UIColor.whiteColor()
        }
        
        cell.selectionStyle = .None
        cell.backgroundColor = UIColor.whiteColor()
        
        cell.layer.borderWidth = 1
        cell.layer.cornerRadius = 8
        cell.clipsToBounds = true
        
        return cell
        
    }
    
    // When user clicks on a Game Tile...
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        print("Clicked \(indexPath.section)")
        
        var gameNameField: UITextField!
        var playerNameField: UITextField!
        
        var gameAtIndex = gameList[indexPath.section]
        
        // CREATE GAME
        if gameAtIndex.isAddTile == true {
            let refreshAlert = UIAlertController(title: "Create Game", message: "", preferredStyle: UIAlertControllerStyle.Alert)
            refreshAlert.addTextFieldWithConfigurationHandler({ (textField: UITextField!) in
                gameNameField = textField
                gameNameField.placeholder = "Game Name"
                gameNameField.keyboardType = UIKeyboardType.Default
            })
            refreshAlert.addTextFieldWithConfigurationHandler({ (textField: UITextField!) in
                playerNameField = textField
                playerNameField.placeholder = "Player Name"
            })
            refreshAlert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction!) in
                print("Creating Game...")
                print("Game Name = \(gameNameField.text)")
                print("Player Name = \(playerNameField.text)")
                if gameNameField.text == "" || playerNameField == "" {
                    self.displayConfirmDialog("Error", message: "One or more fields were empty. Could not create game, please try again.")
                }
                else {
                    let url: NSURL = NSURL(string: "http://battleship.pixio.com/api/games")!
                    let request = NSMutableURLRequest(URL: url)
                    request.HTTPMethod = "POST"
                    let config = NSURLSessionConfiguration.defaultSessionConfiguration()
                    let session = NSURLSession(configuration: config)
                    
                    let params = ["gameName":gameNameField.text!, "playerName":playerNameField.text!] as Dictionary<String, String>
                    
                    request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(params, options: NSJSONWritingOptions())
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.addValue("application/json", forHTTPHeaderField: "Accept")
                    
                    let task = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) in
                        
                        if data == nil {
                            self.displayConfirmDialog("Error", message: "No data was receieved from the server. Please try again.")
                            return
                        }
                        
                        let data = try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions())
                        guard let gameDetails = data as? [String: String] else {
                            self.displayConfirmDialog("Error", message: "Retrieved data was invalid. Please try again.")
                            return
                        }
                        
                        guard let httpResponse = response as? NSHTTPURLResponse else {
                            self.displayConfirmDialog("Error", message: "Received invalid response")
                            return
                        }
                        
                        let status = httpResponse.statusCode
                        if status < 200 || status >= 300 {
                            self.displayConfirmDialog("Error", message: "Error \(status): \(data["message"] as! String). Please try again.")
                            return
                        }
                        
                        if httpResponse.MIMEType != "application/json" {
                            self.displayConfirmDialog("Error", message: "Received invalid data. Please try again.")
                            return
                        }
                        
                        let playerId = gameDetails["playerId"]
                        let gameId = gameDetails["gameId"]
                        
                        gameAtIndex = Game(player1: Player(isTurn: true), player2: Player(isTurn: false), isAddTile: false, gameStatus: "WAITING", gameID: gameId!, gameName: gameNameField.text!)
                        
                        gameAtIndex.player1?.playerID = playerId
                        
                        print("playerId = \(gameDetails["playerId"])")
                        print("gameId = \(gameDetails["gameId"])")
                        
                        dispatch_async(dispatch_get_main_queue(), {
                            let nextVC = GameViewController(nibName: "GameViewController", bundle: nil)
                            self.gameList.append(gameAtIndex)
                            self.tableView.reloadData()
                            self.delegate = nextVC
                            self.delegate?.sendDataToGameView(self, game: gameAtIndex, gameIndex: self.gameList.count - 1)
                            self.navigationController?.pushViewController(nextVC, animated: false)
                        })

                    });
                    
                    task.resume()
                }
            }))
            dispatch_async(dispatch_get_main_queue(), {
                self.presentViewController(refreshAlert, animated: true, completion: {
                    print("refresh alert completed")
                })
            })
        }
        // JOIN WAITING GAME
        else if gameAtIndex.gameStatus == "WAITING" {
            // Joining our own game
            if gameAtIndex.player1?.playerID != "" || gameAtIndex.player1?.playerID != "" {
                let nextVC = GameViewController(nibName: "GameViewController", bundle: nil)
                self.delegate = nextVC
                self.delegate?.sendDataToGameView(self, game: gameAtIndex, gameIndex: indexPath.section)
                self.navigationController?.pushViewController(nextVC, animated: false)
            }
            // Join someone else's game
            else {
                let refreshAlert = UIAlertController(title: "Join Game", message: "", preferredStyle: UIAlertControllerStyle.Alert)
                refreshAlert.addTextFieldWithConfigurationHandler({ (textField: UITextField!) in
                    playerNameField = textField
                    playerNameField.placeholder = "Player Name"
                })
                refreshAlert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction!) in
                    print("Joining Game...")
                    print("Player Name = \(playerNameField.text)")
                    if playerNameField.text == "" {
                        dispatch_async(dispatch_get_main_queue(), {
                            self.displayConfirmDialog("Error", message: "Player name field was empty. Could not join game, please try again.")
                        })
                    }
                    else {
                        let url: NSURL = NSURL(string: "http://battleship.pixio.com/api/games/\(gameAtIndex.gameID!)/join")!
                        let request = NSMutableURLRequest(URL: url)
                        request.HTTPMethod = "POST"
                        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
                        let session = NSURLSession(configuration: config)
                        
                        let params = ["playerName":playerNameField.text!] as Dictionary<String, String>
                        
                        request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(params, options: NSJSONWritingOptions())
                        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                        request.addValue("application/json", forHTTPHeaderField: "Accept")
                        
                        let task = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) in
                            
                            if data == nil {
                                self.displayConfirmDialog("Error", message: "No data was receieved from the server. Please try again.")
                                return
                            }
                            
                            let data = try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions())
                            guard let gameDetails = data as? [String: String] else {
                                self.displayConfirmDialog("Error", message: "Retrieved data was invalid. Please try again.")
                                return
                            }
                            
                            guard let httpResponse = response as? NSHTTPURLResponse else {
                                self.displayConfirmDialog("Error", message: "Received invalid response")
                                return
                            }
                            
                            let status = httpResponse.statusCode
                            if status < 200 || status >= 300 {
                                self.displayConfirmDialog("Error", message: "Error \(status): \(data["message"] as! String). Please try again.")
                                return
                            }
                            
                            if httpResponse.MIMEType != "application/json" {
                                self.displayConfirmDialog("Error", message: "Received invalid data. Please try again.")
                                return
                            }
                            
                            let playerId = gameDetails["playerId"]
                            
                            gameAtIndex.player2?.playerID = playerId
                            gameAtIndex.gameStatus = "PLAYING"
                            gameAtIndex.player1?.isTurn = true
                            gameAtIndex.player2?.isTurn = false
                            
                            print("playerId = \(gameDetails["playerId"])")
                            print("gameId = \(gameDetails["gameId"])")
                            
                            dispatch_async(dispatch_get_main_queue(), {
                                self.gameList[indexPath.section] = gameAtIndex
                                self.tableView.reloadData()
                                let nextVC = GameViewController(nibName: "GameViewController", bundle: nil)
                                self.delegate = nextVC
                                self.delegate?.sendDataToGameView(self, game: gameAtIndex, gameIndex: indexPath.section)
                                self.navigationController?.pushViewController(nextVC, animated: false)
                            })
                            
                        });
                        
                        task.resume()
                    }
                }))
                dispatch_async(dispatch_get_main_queue(), {
                    self.presentViewController(refreshAlert, animated: false, completion: nil)
                })
            }
        }
        else {
            let nextVC = GameViewController(nibName: "GameViewController", bundle: nil)
            self.delegate = nextVC
            self.delegate?.sendDataToGameView(self, game: gameAtIndex, gameIndex: indexPath.section)
            self.navigationController?.pushViewController(nextVC, animated: false)
        }
    }
    
    // Num Rows
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    // Num Sections
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return gameList.count
    }
    
    // Row Height
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if (indexPath.section == 0) {
            return 30
        }
        return 60
    }
    
    // Set the spacing between sections
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return cellSpacingHeight
    }
    
    // Make the background color show through
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clearColor()
        return headerView
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
