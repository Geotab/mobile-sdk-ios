

/**
 Geotab User Session Data.
 */
public struct GeotabCredentials: Codable {
    
    /**
     User name
     */
    public let userName: String
    /**
     Database name
     */
    public let database: String
    /**
     Sesssion ID.
     */
    public let sessionId: String
    
    public init(userName: String, database: String, sessionId: String){
        self.userName = userName
        self.database = database
        self.sessionId = sessionId
    }
}
