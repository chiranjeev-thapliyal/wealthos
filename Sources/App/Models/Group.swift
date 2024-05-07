//
//  File.swift
//  
//
//  Created by Chiranjeev Thapliyal on 07/05/24.
//

import Foundation
import Vapor
import Fluent

final class Group: Model, Content {
    static let schema = "groups"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "members")
    var members: [User.Public]?
    
    init() { }
    
    init(id: UUID?, name: String, members: [User.Public]?) {
        self.id = id
        self.name = name
        self.members = members
    }
}
