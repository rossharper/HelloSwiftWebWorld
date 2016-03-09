//
//  Main.swift
//  HelloSwiftWebWorld
//
//  Created by Ross Harper on 22/02/2016.
//
//

import Foundation
//import Vapor
//import VaporStencil

import KituraRouter
import KituraNet
import KituraSys

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

//View.renderers[".stencil"] = StencilRenderer()

//let app = Application()

func parseResponse(data: NSData?, error: NSError?) -> Dictionary<String, AnyObject> {
    guard let responseData = data else {
        print("Error: did not receive data")
        return Dictionary<String, AnyObject>()
    }
    guard error == nil else {
        print("error calling GET on /posts/1")
        print(error)
        return Dictionary<String, AnyObject>()
    }
    // parse the result as JSON, since that's what the API provides
    do {
        return try NSJSONSerialization.JSONObjectWithData(responseData,
                                                             options: []) as! Dictionary<String, AnyObject>
    } catch  {
        print("error trying to convert data to JSON")
        return Dictionary<String, AnyObject>()
    }
}

struct Episode {
    var title : String
    var subtitle : String
    var imageUrl : String
}

func topTen(iblData: Dictionary<String, AnyObject>) -> String {
    let ge = iblData["group_episodes"] as! NSDictionary?

    if ge == nil {
        print("no group_episodes")
        return ""
    }

    let episodeDictArray = ge!.objectForKey(NSString(string: "elements")) as! NSArray?

    if episodeDictArray == nil {
        print("no elements")
        return ""
    }

    let allEpisodes : [Episode] = episodeDictArray!.map{ (value) -> Episode in
        let episodeDict = value as! NSDictionary
        let episodeTitle = episodeDict.objectForKey(NSString(string: "title")) as! String?
        let episodeSubtitle = episodeDict.objectForKey(NSString(string: "subtitle")) as! String?
        let episodeImageUrl = (episodeDict.objectForKey(NSString(string: "images")) as! NSDictionary?)?.objectForKey(NSString(string: "standard")) as! String?
        let title = episodeTitle ?? ""
        let subtitle = episodeSubtitle ?? ""
        let imageUrl = (episodeImageUrl ?? "").stringByReplacingOccurrencesOfString("{recipe}", withString: "240x135")
        return Episode(title: title, subtitle: subtitle, imageUrl: imageUrl)
        }

    var noEastEnders : [Episode] = allEpisodes.filter {
            !$0.title.lowercaseString.hasPrefix("eastenders")
        }

    while noEastEnders.count > 10 {
        noEastEnders.removeLast()
    }

    let tablerows : String = noEastEnders.map { (value) -> String in
            return "<tr><td><img src=\"" + value.imageUrl + "\"/></td><td>" + value.title + "<br/>" + value.subtitle + "</td></tr>"
        }.reduce("", combine:{$0 + $1})

    // constructing a string because the fucking templating framework doesnt work
    return "<table><thead><tr><th colspan=\"2\">iPlayer Top 10 Episodes that aren't EastEnders</th></tr></thead><tbody>" + tablerows + "</tbody></table>"
}

//func htmlHeader() -> String {
//    return "<html>
//    <head>
//    <link rel="stylesheet" type="text/css" href="home.css">
//    </head>
//    </head>
//    <body>
//    <h1>Hello Swift Web World</h1>
//    <p>Hello, I am a web server written in <a href="https://swift.org/" target="_blank">Swift</a>, running on a Linux virtual machine in the cloud.</p>"
//}

let router = Router()

router.get("/") {
    request, response, next in

    guard let url = NSURL(string: "http://ibl.api.bbci.co.uk/ibl/v1/groups/popular/episodes?per_page=40") else {
            print("Error: cannot create URL")
            response.status(500).send("ERROR!")
            return
        }

        let urlRequest = NSURLRequest(URL: url)

        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())

        let dataTask = session.dataTaskWithRequest(urlRequest)

        var iblData : Dictionary<String, AnyObject> = Dictionary<String, AnyObject>()

        let task = session.dataTaskWithRequest(urlRequest, completionHandler: { (data, iblResponse, error) in
            iblData = parseResponse(data, error: error)

            response.status(HttpStatusCode.OK).send(topTen(iblData))
            next()
        })
        task.resume()
}

let server = HttpServer.listen(port, delegate: router)
Server.run()
