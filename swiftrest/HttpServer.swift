//
//  HttpServer.swift
//  swiftrest
//
//  Created by Steffen Neubauer on 18/06/15.
//  Copyright © 2015 Steffen Neubauer. All rights reserved.
//

// I'm using foundation here but dependency should be removed later
//import Foundation

enum HttpStatus {
    case OK
    case NotFound
    case Other(Int, String)

    func code() -> Int {
        switch self {
        case OK:
            return 200
        case NotFound:
            return 404
        case let Other(status, _):
            return status
        }
    }

    func message() -> String {
        switch self {
        case OK:
            return "OK"
        case NotFound:
            return "Not Found"
        case let Other(_, message):
            return message
        }
    }
}

protocol HttpResponseBuilderDelegate: AnyObject {
    func httpResponseBuilderEndResponse(response: HttpResponse)
}

class HttpResponsePrinter: HttpResponseBuilderDelegate {
    func httpResponseBuilderEndResponse(response: HttpResponse) {
        if let body = response.body {
            print("\(response.statusCode) \(response.statusMessage) - Body: \(body)")
        } else {
            print("\(response.statusCode) \(response.statusMessage) - No body")
        }
    }
}

class HttpResponseBuilder {
    private var response = HttpResponse()
    private weak var delegate : HttpResponseBuilderDelegate?;

    init(delegate: HttpResponseBuilderDelegate?) {
        self.delegate = delegate
    }

    func setStatus(status: HttpStatus) {
        response.statusCode = status.code()
        response.statusMessage = status.message()
    }

    func end(body: String) {
        response.body = body
        self.delegate?.httpResponseBuilderEndResponse(response)
    }
}

struct HttpResponse {
    var statusCode: Int = 200
    var statusMessage: String = "OK"
    var headers: Dictionary<String, String> = Dictionary()
    var body: String?
}

struct HttpRequest {
    var url: String
    var headers: Dictionary<String, String> = Dictionary()

    init(url: String = "") {
        self.url = url
    }
}



typealias NextCallback = () -> (Void)
typealias HttpRequestHandler = (HttpRequest, HttpResponseBuilder, NextCallback) -> (Void)

enum HttpServerError : ErrorType {
    case CouldNotListen(String)
}

protocol HttpServer {
    func serve(port:Int, host:String) throws

    func addHandler(handler:HttpRequestHandler)
}

class SimpleHttpServer: HttpServer {
    private var handlerChain: [HttpRequestHandler] = Array()
    private var responsePrinter = HttpResponsePrinter()
    
    func addHandler(handler: HttpRequestHandler) {
        handlerChain.append(handler)
    }

    func handleRequest(request: HttpRequest) {
        let response = HttpResponseBuilder(delegate: responsePrinter)
        let firstHandler = nextCallbackFor(index: -1, request: request, response: response)
        firstHandler()
    }

    func nextCallbackFor(index index: Int, request: HttpRequest, response: HttpResponseBuilder) -> NextCallback {
        let next = index + 1

        if next >= handlerChain.count {
            return {
                response.setStatus(.NotFound)
                response.end("Error: Could not find matching handler for this request")
            }
        }

        return { [unowned self] in
            let nextHandler = self.handlerChain[next]
            let nextCallback = self.nextCallbackFor(index: next, request: request, response: response)
            nextHandler(request, response, nextCallback)
        }
    }

    func serve(port: Int, host: String) throws {
        for ;; {
            throw HttpServerError.CouldNotListen("Not yet implemented!")
        }
    }
}
