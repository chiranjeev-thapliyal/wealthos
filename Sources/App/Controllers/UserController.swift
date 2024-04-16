//
//  File.swift
//  
//
//  Created by Chiranjeev Thapliyal on 16/04/24.
//

import Foundation
import Vapor
import Fluent
import FluentMongoDriver


class UserController: RouteCollection {
    
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "v1")
        
        api.post("user", use: createUser)
        api.get("user", use: getAll)
        api.get("user", ":userId", use: getById)
    }
    
    func getById(req: Request) async throws -> User {
        guard let id = req.parameters.get("userId", as: UUID.self) else {
            throw Abort(.notAcceptable)
        }
        
        guard let user = try await User.find(id, on: req.db) else {
            throw Abort(.notFound, reason: "User \(id) was not found")
        }
            
        return user
    }
    
    func getAll(req: Request) async throws -> [User] {
        return try await User.query(on: req.db).all()
    }
    
    func createUser(req: Request) async throws -> User {
        let user = try req.content.decode(User.self)
            
        try await user.save(on: req.db)
        
        return user
    }
    
}
