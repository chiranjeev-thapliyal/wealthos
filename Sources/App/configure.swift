import Vapor
import Fluent
import FluentMongoDriver
import JWT

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    // register routes
    
    guard let MONGO_URI = Environment.get("MONGO_URI") else {
        throw Abort(.internalServerError)
    }
    
    try app.databases.use(.mongo(connectionString: MONGO_URI), as: .mongo)
    
    try app.register(collection: UserController())
    try app.register(collection: TransactionController())
    
    app.passwords.use(.bcrypt(cost: 8))
    app.jwt.signers.use(.hs256(key: "secret"))
    
    try routes(app)
}
