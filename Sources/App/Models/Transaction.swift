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

struct Share: Codable {
    let userId: UUID
    let percentage: Double
}

struct TransactionDetail: Content {
    let transaction: Transaction
    let userShare: Share?
    let friendShare: Share?
}

final class Transaction: Model, Content {
    static let schema = "transactions"
    
    @ID(custom: .id, generatedBy: .database)
    var id: UUID?
    
    @Parent(key: "created_by")
    var creator: User
    
    @Field(key: "description")
    var description: String
    
    @Field(key: "amount")
    var amount: Double
    
    @Field(key: "shares")
    var shares: [Share]
    
    init() {}
    
    init(id: UUID? = nil, creatorId: UUID, description: String, amount: Double, shares: [Share]) {
        self.id = id
        self.$creator.id = creatorId
        self.description = description
        self.amount = amount
        self.shares = shares
    }
    
}
