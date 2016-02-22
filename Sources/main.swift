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
    return "<h1>Hello Swift Web World</h1><p>Hello, I am a web server written in <a href=\"https://swift.org/\" target=\"_blank\">Swift</a>, running on a Linux virtual machine in the cloud.</p>"
}

let server = Server()
server.run(port: 4242)
