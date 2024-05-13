//
//  File.swift
//  
//
//  Created by Chiranjeev Thapliyal on 07/05/24.
//

import Foundation
import Vapor

struct Friend: Codable, Content {
    let id: UUID
    let name: String?
    var email: String?
}
