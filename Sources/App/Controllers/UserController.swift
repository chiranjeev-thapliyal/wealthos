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
        api.post("user", "login", use: login)
        api.get("transactions", ":userId", use: getUserTransactions)
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
        let hashedPassword = try await req.password.async.hash(user.password)
        
        user.password = hashedPassword
            
        try await user.save(on: req.db)
        
        return user
    }
    
    func login(req: Request) async throws -> LoginResponse {
        let requestedUser = try req.content.decode(LoginRequest.self)
        
        guard let user = try await User.query(on: req.db).filter(\.$email == requestedUser.email).first() else {
            throw Abort(.notFound, reason: "User not found")
        }
        
        let verify = try await req.password.async.verify(requestedUser.password, created: user.password)
        
        if verify {
            let payload = TestPayload(subject: "accessToken", expiration: .init(value: .distantFuture), data: PublicUserInfo(name: user.name, email: user.email))
            let token = try req.jwt.sign(payload)
            let response = LoginResponse(name: user.name, email: user.email, token: token)
            
            return response
        } else {
            throw Abort(.unauthorized, reason: "Invalid credentials")
        }
    }
    
    func getUserTransactions(req: Request) async throws -> Response {
        let response = Response(status: .ok)
        return response
    }
    
}
