//
//  Main.swift
//  HelloSwiftWebWorld
//
//  Created by Ross Harper on 22/02/2016.
//
//

import Foundation

import KituraRouter
import KituraNet
import KituraSys
import Stencil

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

func topTen(iblData: Dictionary<String, AnyObject>) -> [Episode] {
    let ge = iblData["group_episodes"] as! NSDictionary?

    if ge == nil {
        print("no group_episodes")
        return []
    }

    let episodeDictArray = ge!.objectForKey(NSString(string: "elements")) as! NSArray?

    if episodeDictArray == nil {
        print("no elements")
        return []
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

    // TODO: better way to sub array?
    while noEastEnders.count > 10 {
        noEastEnders.removeLast()
    }
    
    return noEastEnders
}

let router = Router()

router.use("/static/*", middleware: StaticFileServer())

router.get("/") {
    request, response, next in

    guard let url = NSURL(string: "http://ibl.api.bbci.co.uk/ibl/v1/groups/popular/episodes?per_page=40") else {
            print("Error: cannot create URL")
            response.status(500).send("ERROR creating url!")
            return
        }

        let urlRequest = NSURLRequest(URL: url)

        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())

        let dataTask = session.dataTaskWithRequest(urlRequest)

        var iblData : Dictionary<String, AnyObject> = Dictionary<String, AnyObject>()

        let task = session.dataTaskWithRequest(urlRequest, completionHandler: { (data, iblResponse, error) in
            iblData = parseResponse(data, error: error)

            let topTenData = topTen(iblData)
            let mapped : [Dictionary<String, String>] = topTenData.map{ (value) -> Dictionary<String, String> in
                return ["imageUrl": value.imageUrl, "title": value.title, "subtitle": value.subtitle]
            }
            
            do {
                let context = Context(dictionary: ["episodes": mapped])
                
                let template = try Template(path: "./Resources/index.stencil")
                
                let rendered = try template.render(context)
                response.status(HttpStatusCode.OK).send(rendered)
            } catch let error as NSError {
                response.status(500).send("ERROR rendering template! \(error.code)")
            }
            
            next()
        })
        task.resume()
}

let server = HttpServer.listen(port, delegate: router)
Server.run()
