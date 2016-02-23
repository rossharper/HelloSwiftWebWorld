//
//  Package.swift
//  HelloSwiftWebWorld
//
//  Created by Ross Harper on 22/02/2016.
//
//

import PackageDescription

let package = Package(
    name: "HelloSwiftWebWorld",
    dependencies: [
        .Package(url: "https://github.com/loganwright/vapor.git", majorVersion: 0),
        .Package(url: "https://github.com/tannernelson/vapor-stencil.git", majorVersion: 0)
    ]
)
