//
//  File.swift
//  
//
//  Created by Chiranjeev Thapliyal on 16/04/24.
//

import Foundation
import Vapor
import Fluent

final class TemporaryUser: Model, Content {
    static let schema = "temporaryUsers"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "name")
    var name: String
    
    init() { }
    
    init(id: UUID? = nil, email: String, name: String) {
        self.id = id
        self.email = email
        self.name = name
    }
}

final class User: Model, Content {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "password")
    var password: String
    
    @OptionalField(key: "friends")
    var friends: [Friend]?
    
    @OptionalField(key: "groups")
    var groups: [Group]?
    
    init() { }
    
    init(id: UUID? = nil, name: String, email: String, password: String, friends: [Friend]? = nil, groups: [Group]? = nil) {
        self.id = id
        self.name = name
//        self.phoneNumber = phoneNumber
        self.email = email
        self.password = password
        self.friends = friends
        self.groups = groups
    }
    
    struct Public: Content, Codable {
        let id: UUID
        let name: String
    }
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
