//
//  Main.swift
//  HelloSwiftWebWorld
//
//  Created by Ross Harper on 22/02/2016.
//
//

import Foundation
import Vapor

print("HelloSwiftWebWorld -- starting...")

Route.get("/") { _ in
    return "Hello Swift Web World"
}

let server = Server()
server.run(port: 80)
