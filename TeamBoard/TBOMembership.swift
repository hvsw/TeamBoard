//
//  Membership.swift
//  TeamBoard
//
//  Created by Fabio Innocente on 4/4/16.
//  Copyright © 2016 MC. All rights reserved.
//


import UIKit

class TBOMembership: NSObject {
//    var id : String?
    var members = [[String : TBOMember]]()
    var admins = [[String : Bool]]()
    
    // TRELLO API : Get Boards/<id>/members
    init(dictionary: [[String : AnyObject]]){
        super.init()
        for jsonMember in dictionary {
            if let memberId = jsonMember["idMember"] as? String {
                let isAdmin = (jsonMember["memberType"] as? String) == "admin"
//                members.append([member.id! : member])
//                admins.append([member.id!: isAdmin])
            }
        }
    }
    
    init(members: [TBOMember]){
        super.init()
        for member in members {
            self.members.append([member.id!:member])
        }
    }
    
    func updateAdmins(){
        // TODO: update admins
    }
}