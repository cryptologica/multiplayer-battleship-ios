//
//  Player.swift
//  Project3
//
//  Created by JT Newsome on 3/19/16.
//  Copyright © 2016 JT Newsome. All rights reserved.
//

import UIKit

class Player: NSObject, NSCoding {
    
    var numShipsAlive: Int
    var isTurn: Bool
    var shipList: [Ship]?
    var missedCoordinates: [Coordinate]?
    var hitCoordinates: [Coordinate]?
    var playerID: String?
    
    var hasPlaced: Bool {
        // There are 5 ships total
        if (shipList?.count == 5){
            return true
        }
        else {
            return false
        }
    }

    init(isTurn: Bool) {
        self.numShipsAlive = 5
        self.isTurn = isTurn
        self.shipList = [Ship]()
        self.missedCoordinates = [Coordinate]()
        self.hitCoordinates = [Coordinate]()
        self.playerID = ""
    }
    
    required init(coder decoder: NSCoder) {
        self.numShipsAlive = decoder.decodeIntegerForKey("numShipsAlive")
        self.isTurn = decoder.decodeBoolForKey("isTurn")
        self.shipList = decoder.decodeObjectForKey("shipList") as? [Ship]
        self.missedCoordinates = decoder.decodeObjectForKey("missedCoordinates") as? [Coordinate]
        self.hitCoordinates = decoder.decodeObjectForKey("hitCoordinates") as? [Coordinate]
        self.playerID = decoder.decodeObjectForKey("playerID") as? String
    }
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeInteger(self.numShipsAlive, forKey: "numShipsAlive")
        coder.encodeBool(self.isTurn, forKey: "isTurn")
        coder.encodeObject(shipList, forKey: "shipList")
        coder.encodeObject(missedCoordinates, forKey: "missedCoordinates")
        coder.encodeObject(hitCoordinates, forKey: "hitCoordinates")
        coder.encodeObject(playerID, forKey: "playerID")
    }
    
}
