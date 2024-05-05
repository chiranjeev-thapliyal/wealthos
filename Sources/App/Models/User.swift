//
//  File.swift
//  
//
//  Created by Chiranjeev Thapliyal on 16/04/24.
//

import Foundation
import Vapor
import Fluent

final class User: Model, Content {
    static let schema = "users"
    
    // Unique identifier for this User.
    @ID(key: .id)
    var id: UUID?
    
    // The User's name.
    @Field(key: "name")
    var name: String
    
    // The User's email.
    @Field(key: "email")
    var email: String
    
    // The User's name.
    @Field(key: "password")
    var password: String
    
    // User Friends
    @Field(key: "friends")
    var friends: [UUID]
    
    init() { }

    // Creates a new User with all properties set.
    init(id: UUID? = nil, name: String, email: String, password: String) {
        self.id = id
        self.name = name
        self.email = email
        self.password = password
    }
    
}

struct FriendRequest: Content {
    let friendId: UUID
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

class PublicUserInfo: Codable {
    let name: String
    let email: String
    
    init(name: String, email: String) {
        self.name = name
        self.email = email
    }
}

final class LoginResponse: Codable, Content {
    let name: String
    let email: String
    let token: String
    
    init(name: String, email: String, token: String) {
        self.name = name
        self.email = email
        self.token = token
    }
    
}
