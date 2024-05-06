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

    func getTransactionsWithFriend(req: Request) async throws -> [TransactionDetail] {
        guard let userId = req.parameters.get("userId", as: UUID.self),
              let friendId = req.parameters.get("friendId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid user or friend ID.")
        }

        // Fetch all transactions involving the user
        let transactions = try await Transaction.query(on: req.db)
            .group(.or) { or in
                or.filter(\.$creator.$id == userId)
                or.filter(\.$creator.$id == friendId)
            }
            .all()
        
        // Further filter in-memory to find transactions that also involve the friend
        let relevantTransactions = transactions.filter { transaction in
            let userInvolved = transaction.shares.contains(where: { $0.userId == userId })
            let friendInvolved = transaction.shares.contains(where: { $0.userId == friendId })
            return userInvolved && friendInvolved
        }

        // Map to detailed view that includes share info
        return relevantTransactions.map { transaction in
            TransactionDetail(
                transaction: transaction,
                userShare: transaction.shares.first(where: { $0.userId == userId }),
                friendShare: transaction.shares.first(where: { $0.userId == friendId })
            )
        }
    }

    
}
