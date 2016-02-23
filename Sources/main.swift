//
//  Main.swift
//  HelloSwiftWebWorld
//
//  Created by Ross Harper on 22/02/2016.
//
//

import Foundation
import Vapor
import VaporStencil

print("HelloSwiftWebWorld -- starting...")

var port : Int = 4242

for arg in Process.arguments {
    if arg.hasPrefix("port=") {
        let portArg : Int? = Int(arg.substringFromIndex(arg.startIndex.advancedBy(5)))
        if portArg != nil {
            port = portArg!
        }
    }
}

View.renderers[".stencil"] = StencilRenderer()

let app = Application()

app.get("/") { request in
    return try View(path: "index.stencil")
}

app.start(port: port)
