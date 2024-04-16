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
    
    init() { }

    // Creates a new User with all properties set.
    init(id: UUID? = nil, name: String, email: String, password: String) {
        self.id = id
        self.name = name
        self.email = email
        self.password = password
    }
    
}
