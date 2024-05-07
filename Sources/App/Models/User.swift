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
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "phoneNumber")
    var phoneNumber: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "password")
    var password: String
    
    @OptionalField(key: "friends")
    var friends: [Friend]?
    
    init() { }
    
    init(id: UUID? = nil, name: String, phoneNumber: String, email: String, password: String, friends: [Friend]? = nil) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.email = email
        self.password = password
        self.friends = friends
    }
}


struct Friend: Codable {
    let id: UUID
    let name: String?
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
    let id: UUID
    let name: String
    let email: String
    let token: String
    
    init(id: UUID, name: String, email: String, token: String) {
        self.id = id
        self.name = name
        self.email = email
        self.token = token
    }
}

