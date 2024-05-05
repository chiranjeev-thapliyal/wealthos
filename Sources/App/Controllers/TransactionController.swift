//
//  File.swift
//  
//
//  Created by Chiranjeev Thapliyal on 05/05/24.
//

import Foundation
import Vapor
import Fluent
import FluentMongoDriver

struct TransactionController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes
        
        api.get("user", ":userId", "transactions", use: getTransactionsForUser)
        api.post("transactions", use: addTransaction)
        api.get("users", ":userId", "transactions", ":friendId", use: getTransactionsWithFriend)
    }
    
    
    func addTransaction(req: Request) async throws -> Response {
        let response = Response(status: .ok)
        
        guard let userId = req.parameters.get("userId") else {
            throw Abort(.badRequest, reason: "Invalid user id")
        }
        
        let transaction = try req.content.decode(Transaction.self)
        
        try await transaction.save(on: req.db)
        
        return response
    }
    
    func getTransactionsForUser(req: Request) async throws -> [Transaction] {
        guard let userId = req.parameters.get("userId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid user ID.")
        }
        
        return try await Transaction.query(on: req.db)
            .filter(\.$creator.$id == userId)
            .all()
    }

}
