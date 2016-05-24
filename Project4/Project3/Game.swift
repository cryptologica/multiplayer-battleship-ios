//
//  Game.swift
//  Project3
//
//  Created by JT Newsome on 3/19/16.
//  Copyright © 2016 JT Newsome. All rights reserved.
//

import Foundation

class Game: NSObject, NSCoding {
    
    var player1: Player?
    var player2: Player?
    var isAddTile: Bool
    var placementIndex: Int
    var placeShips: [Int] = [5, 4, 3, 2, 1]
    var gameID: String?
    var gameStatus: String?
    var gameName: String?

    
    init(player1: Player, player2: Player, isAddTile: Bool, gameStatus: String, gameID: String, gameName: String) {
        self.player1 = player1
        self.player2 = player2
        self.isAddTile = isAddTile
        self.placementIndex = 0
        self.gameStatus = gameStatus
        self.gameID = gameID
        self.gameName = gameName
    }

    required init(coder decoder: NSCoder) {
        self.player1 = decoder.decodeObjectForKey("player1") as? Player
        self.player2 = decoder.decodeObjectForKey("player2") as? Player
        self.isAddTile = decoder.decodeBoolForKey("isAddTile")
        self.placementIndex = decoder.decodeIntegerForKey("placementIndex")
        self.gameStatus = decoder.decodeObjectForKey("gameStatus") as? String
        self.gameID = decoder.decodeObjectForKey("gameID") as? String
        self.gameName = decoder.decodeObjectForKey("gameName") as? String
    }
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(self.player1, forKey: "player1")
        coder.encodeObject(self.player2, forKey: "player2")
        coder.encodeBool(self.isAddTile, forKey: "isAddTile")
        coder.encodeInteger(self.placementIndex, forKey: "placementIndex")
        coder.encodeObject(self.gameStatus, forKey: "gameStatus")
        coder.encodeObject(self.gameID, forKey: "gameID")
        coder.encodeObject(self.gameName, forKey: "gameName")
    }
    
}