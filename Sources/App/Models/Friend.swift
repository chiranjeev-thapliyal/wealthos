//
//  File.swift
//  
//
//  Created by Chiranjeev Thapliyal on 06/05/24.
//

import Foundation
import Vapor
import Fluent

final class Friendship: Model, Content {
    static let schema = "friendships"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User
    
    @Parent(key: "friend_id")
    var friend: User
    
    init() {}
    
    init(id: UUID? = nil, userId: UUID, friendId: UUID) {
        self.id = id
        self.$user.id = userId
        self.$friend.id = friendId
    }
}
