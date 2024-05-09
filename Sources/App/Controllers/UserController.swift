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
        api.post("user", "temporary", use: createTemporaryUser)
        api.get("user", use: getAll)
        api.get("user", ":userId", use: getById)
        api.post("user", "login", use: login)
        api.get("user", ":userId", "friends", use: getUserFriends)
        api.post("users", ":userId", "friends", "add", use: addUserFriend)
        api.post("groups", use: createGroup)
        api.post("user", ":userId", "groups", "add", use: addUserToGroup)
        api.get("user", ":userId", "groups", use: getUserGroups)
        api.delete("user", ":userId", use: removeUser)
        api.get("user", "phoneNumber", ":phoneNumber", use: getByPhoneNumber)
    }
    
    func getByPhoneNumber(req: Request) async throws -> User {
        guard let requestedPhoneNumber = req.parameters.get("phoneNumber") else {
            throw Abort(.notAcceptable)
        }
        
        guard let user = try await User.query(on: req.db).filter(\.$phoneNumber == requestedPhoneNumber).first() else {
            throw Abort(.notFound, reason: "User \(requestedPhoneNumber) was not found")
        }
            
        return user
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
    
    func createTemporaryUser(req: Request) async throws -> Response {
        let response = Response(status: .ok)
        
        do {
            let user = try req.content.decode(TemporaryUser.self)
            
            let foundUser = try await TemporaryUser.query(on: req.db).filter(\.$phoneNumber == user.phoneNumber).first()
            
            if let foundUser = foundUser {
                try response.content.encode(foundUser)
            } else {
                try await user.save(on: req.db)
                try response.content.encode(user)
            }
            
            return response
        } catch {
            response.status = .internalServerError
            let errorResponse = ErrorResponse(error: true, reason: "Internal Server Error: \(error.localizedDescription)")
            try response.content.encode(errorResponse)
            return response
        }
    }
    
    func createUser(req: Request) async throws -> Response {
        let response = Response(status: .ok)
        
        do {
            let user = try req.content.decode(User.self)
            
            if try await User.query(on: req.db).filter(\.$email == user.email).first() != nil {
                throw Abort(.badRequest, reason: "A user with the same email already exists.")
            }
            
            let foundUser = try await User.query(on: req.db).filter(\.$phoneNumber == user.phoneNumber).first()
            
            if foundUser != nil {
                throw Abort(.badRequest, reason: "A user with the same phone number already exists.")
            }
            
            let temporaryUser = try await TemporaryUser.query(on: req.db).filter(\.$phoneNumber == user.phoneNumber).first()
            
            if let temporaryUser = temporaryUser {
                user.id = temporaryUser.id
            }
            
            user.password = try await req.password.async.hash(user.password)
                
            try await user.save(on: req.db)
            
            if let temporaryUser = temporaryUser {
                try await temporaryUser.delete(on: req.db)
            }
            
            let payload = TestPayload(subject: "accessToken", expiration: .init(value: .distantFuture), data: PublicUserInfo(name: user.name, email: user.email))
            let token = try req.jwt.sign(payload)
            let responseData = LoginResponse(id: user.id!, name: user.name, email: user.email, token: token)
            
            try response.content.encode(responseData)
            return response
        } catch let error as DecodingError {
            response.status = .badRequest
            let errorResponse = ErrorResponse(error: true, reason: "Decoding Error: \(error.localizedDescription)")
            try response.content.encode(errorResponse)
            return response
        } catch let error as AbortError {
            response.status = error.status
            let errorResponse = ErrorResponse(error: true, reason: error.reason)
            try response.content.encode(errorResponse)
            return response
        } catch {
            response.status = .internalServerError
            let errorResponse = ErrorResponse(error: true, reason: "Internal Server Error: \(error.localizedDescription)")
            try response.content.encode(errorResponse)
            return response
        }
        
    }
    
    func removeUser(req: Request) async throws -> Response {
        let response = Response(status: .ok)
        
        guard let userId = req.parameters.get("userId", as: UUID.self) else {
            throw Abort(.notFound, reason: "User not found")
        }
        
        guard let user = try await User.find(userId, on: req.db) else {
            throw Abort(.notFound, reason: "User \(userId) not found")
        }
        
        try await user.delete(on: req.db)
        
        try response.content.encode(["message": "User deleted successfully"])
        
        return response
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
            let response = LoginResponse(id: user.id!, name: user.name, email: user.email, token: token)
            
            return response
        } else {
            throw Abort(.unauthorized, reason: "Invalid credentials")
        }
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
        
        guard friend.id != userId else {
            throw Abort(.badRequest, reason: "Invalid friend ID or friend not found.")
        }
        
        let foundRegisteredFriend = try await User.find(friend.id, on: req.db)
        let foundTemporaryFriend = try await TemporaryUser.find(friend.id, on: req.db)
        
        if !(foundRegisteredFriend != nil) && !(foundTemporaryFriend != nil) {
            throw Abort(.badRequest, reason: "Invalid friend ID or friend not found.")
        }
        
        if (user.friends?.contains(where: { $0.id == friend.id }) == true) {
            response.status = .badRequest
            response.body = "Already a friend"
            return response
        }
        
        if user.friends == nil {
            user.friends = []
        }
        
        var newFriend: Friend?
        
        if foundRegisteredFriend != nil, let foundFriendId = foundRegisteredFriend?.id {
            newFriend = Friend(id: foundFriendId, name: foundRegisteredFriend?.name, phoneNumber: foundRegisteredFriend?.phoneNumber, email: foundRegisteredFriend?.email)
        } else if foundTemporaryFriend != nil, let foundFriendId = foundTemporaryFriend?.id {
            newFriend = Friend(id: foundFriendId, name: foundTemporaryFriend?.name, phoneNumber: foundTemporaryFriend?.phoneNumber)
        }
        
        
        if let newFriend = newFriend, let friends = user.friends, !friends.contains(where: { $0.id == newFriend.id }) {
            user.friends?.append(newFriend)
            try await user.save(on: req.db)
        }
        
        return response
    }
    
    func createGroup(req: Request) async throws -> Response {
        let response = Response(status: .ok)
        
        do {
            let group = try req.content.decode(Group.self)
            
            try await group.save(on: req.db)
            
            if let members = group.members, let groupId = group.id {
                for memberPublic in members {
                    if let user = try await User.find(memberPublic.id, on: req.db) {
                        var userGroups = user.groups ?? []
                        let groupToAdd = Group(id: groupId, name: group.name, members: nil)
                        userGroups.append(groupToAdd)
                        user.groups = userGroups
                        try await user.save(on: req.db)
                    }
                }
            }
            
            try response.content.encode(group)
            
            return response
        } catch {
            response.status = .badRequest
            try response.content.encode(ErrorResponse(error: true, reason: "Internal Server Error"))
            return response
        }
    }
    
    func addUserToGroup(req: Request) async throws -> Response {
        let response = Response(status: .ok)
        
        do {
            guard let userId = req.parameters.get("userId", as: UUID.self) else {
                throw Abort(.badRequest, reason: "Invalid userId")
            }
            
            let requestGroup = try req.content.decode(Group.self)
            
            guard let user = try await User.find(userId, on: req.db) else {
                throw Abort(.notFound, reason: "User not found")
            }
            
            guard let group = try await Group.find(requestGroup.id, on: req.db) else {
                throw Abort(.notFound, reason: "Group not found")
            }
            
            if ((user.groups?.contains(where: { $0.id == group.id })) != nil) {
                response.status = .badRequest
                response.body = "Already a group member"
                return response
            }
            
            if user.groups == nil {
                user.groups = []
            }
            
            user.groups?.append(group)
            
            group.members?.append(User.Public(id: user.id!, name: user.name))
            
            try await user.save(on: req.db)
            try await group.save(on: req.db)
            
        } catch {
            response.status = .badRequest
            try response.content.encode(ErrorResponse(error: true, reason: "Internal Server Error"))
            return response
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
        let response = Response(status: .ok)
        try response.content.encode(friends)
        
        return response
    }
    
    func getUserGroups(req: Request) async throws -> Response {
        guard let userId = req.parameters.get("userId", as: UUID.self),
              let user = try await User.find(userId, on: req.db),
              let groups = user.groups, !groups.isEmpty else {
            return Response(status: .ok, body: .empty)
        }

        // Extract the UUIDs from the friends array
        let response = Response(status: .ok)
        try response.content.encode(groups)
        
        return response
    }

    
}
