//
//  HttpServer.swift
//  swiftrest
//
//  Created by Steffen Neubauer on 18/06/15.
//  Copyright © 2015 Steffen Neubauer. All rights reserved.
//

// I'm using foundation here but dependency should be removed later
import Foundation

struct HttpResponse {
    var statusCode: Int = 200
    var statusMessage: String = "OK"
    var headers: Dictionary<String, String> = Dictionary()
    var body: [UInt8] = Array()

    func end(body: String) {
        print("\(statusCode) \(statusMessage) - Body: \(body)")
    }
}

struct HttpRequest {
    var url: String
    var headers: Dictionary<String, String> = Dictionary()
    var body: [UInt8] = Array()
    init(url: String = "") {
        self.url = url
    }
}



typealias NextCallback = () -> (Void)
typealias HttpRequestHandler = (HttpRequest, inout HttpResponse, NextCallback) -> (Void)

enum HttpServerError : ErrorType {
    case CouldNotListen(String)
}

protocol HttpServer {
    func serve(port:Int, host:String) throws

    func addHandler(handler:HttpRequestHandler)
}

class SimpleHttpServer: HttpServer {
    private var handlerChain: [HttpRequestHandler] = Array()

    func addHandler(handler: HttpRequestHandler) {
        handlerChain.append(handler)
    }

    func handleRequest(request: HttpRequest, inout response: HttpResponse) {
        let firstHandler = nextCallbackFor(index: -1, request: request, response: &response)
        firstHandler()
    }

    func nextCallbackFor(index index: Int, request: HttpRequest, inout response: HttpResponse) -> NextCallback {
        let next = index + 1

        if next >= handlerChain.count {
            return {
                response.statusCode = 404
                response.statusMessage = "Not Found"
                
                response.end("Error: Could not find matching handler for this request")
            }
        }

        return { [unowned self] in
            let nextHandler = self.handlerChain[next]
            let nextCallback = self.nextCallbackFor(index: next, request: request, response: &response)
            nextHandler(request, &response, nextCallback)
        }
    }

    func serve(port: Int, host: String) throws {
        for ;; {
            throw HttpServerError.CouldNotListen("Not yet implemented!")
        }
    }
}
