//
//  GameListTableView.swift
//  Project3
//
//  Created by JT Newsome on 3/18/16.
//  Copyright © 2016 JT Newsome. All rights reserved.
//

import UIKit

class GameTableViewCell: UITableViewCell {
    
    var gameStatusLabel: UILabel!

    var gameNameLabel: UILabel!
    
    var game: Game?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = UIColor.clearColor()
        
        let width = self.frame.width
        let height = self.frame.height + 15
        gameStatusLabel = UILabel(frame: CGRectMake(0, 0, width, height * 0.5))
        gameStatusLabel.backgroundColor = UIColor.lightGrayColor()
        gameStatusLabel.text = "New Game"
        gameStatusLabel.textAlignment = .Center
        gameStatusLabel.textColor = UIColor.whiteColor()
        contentView.addSubview(gameStatusLabel)
        
        gameNameLabel = UILabel(frame: CGRectMake(0, height * 0.5, width, height * 0.5))
        gameNameLabel.textColor = UIColor.blackColor()
        gameNameLabel.textAlignment = .Center
        contentView.addSubview(gameNameLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
