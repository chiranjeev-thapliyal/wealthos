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
        let api = routes
        
        api.post("user", use: createUser)
        api.get("user", use: getAll)
        api.get("user", ":userId", use: getById)
        api.post("user", "login", use: login)
        api.get("transactions", ":userId", use: getUserTransactions)
        api.get("user", ":userId", "friends", use: getUserFriends)
        api.post("users", ":userId", "friends", "add", use: addUserFriend)
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
        
        user.password = try await req.password.async.hash(user.password)
            
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
    
    func addUserFriend(req: Request) async throws -> Response {
        let response = Response(status: .ok)
        
        guard let userId = req.parameters.get("userId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid userId")
        }
        
        let friend = try req.content.decode(Friend.self)
        
        guard let user = try await User.find(userId, on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }
        
        guard friend.id != userId,
                let foundFriend = try await User.find(friend.id, on: req.db) else {
            throw Abort(.badRequest, reason: "Invalid friend ID or friend not found.")
        }
        
        if ((user.friends?.contains(where: { $0.id == friend.id })) != nil) {
            response.status = .badRequest
            response.body = "Already a friend"
            return response
        }
        
        if user.friends == nil {
            user.friends = []
        }
        
        let newFriend = Friend(id: friend.id, name: foundFriend.name)
        
        if let friends = user.friends, !friends.contains(where: { $0.id == newFriend.id }) {
            user.friends?.append(newFriend)
            try await user.save(on: req.db)
        }
        
        return response
    }
    
    
    func getUserFriends(req: Request) async throws -> Response {
        guard let userId = req.parameters.get("userId", as: UUID.self),
              let user = try await User.find(userId, on: req.db),
              let friends = user.friends, !friends.isEmpty else {
            return Response(status: .ok, body: .empty)
        }

        // Extract the UUIDs from the friends array
        let friendUUIDs = friends.map { $0.id }

        // Filter users based on extracted UUIDs
        let friendUsers = try await User.query(on: req.db).filter(\.$id ~~ friendUUIDs).all()
        let response = Response(status: .ok)
        try response.content.encode(friendUsers)
        return response
    }

    
}
