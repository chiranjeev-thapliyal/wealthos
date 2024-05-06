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
    
    @ID(custom: .id, generatedBy: .database)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "password")
    var password: String
    
    // Ensure no default value is set here that Fluent might misinterpret
    @Field(key: "friends")
    var friends: [Friend]?
    
    init() { }
}

struct Friend: Codable {
    let id: UUID
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

