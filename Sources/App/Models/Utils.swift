//
//  File.swift
//  
//
//  Created by Chiranjeev Thapliyal on 07/05/24.
//

import Foundation
import Vapor

struct ErrorResponse: Content {
    var error: Bool
    var reason: String
}
