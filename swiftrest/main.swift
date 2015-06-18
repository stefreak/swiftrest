//
//  main.swift
//  swiftrest
//
//  Created by Steffen Neubauer on 16/06/15.
//  Copyright © 2015 Steffen Neubauer. All rights reserved.
//

// hah! we don't need this.
//import Foundation


let con = HttpConnection(type: .Request)
let con2 = HttpConnection(type: .Request)

try con2.receive(return_test_data(), len: return_test_length())
try con.receive(return_test_data(), len: return_test_length())



let server = SimpleHttpServer()

server.addHandler { (request: HttpRequest, inout response: HttpResponse, next: NextCallback) -> (Void) in
    response.end("hah! it works!")
}
var response = HttpResponse()
server.handleRequest(HttpRequest(), response: &response)




// test multiple handlers in chain

let server2 = SimpleHttpServer()

server2.addHandler { (request: HttpRequest, inout response: HttpResponse, next: NextCallback) -> (Void) in
    if request.url == "/handler1" {
        response.end("I only listen on /handler1!")
    } else {
        next()
    }
}
server2.addHandler { (request: HttpRequest, inout response: HttpResponse, next: NextCallback) -> (Void) in
    if request.url == "/handler2" {
        response.end("I only listen on /handler2!")
    } else {
        next()
    }
}

var responseHandler1 = HttpResponse()
server2.handleRequest(HttpRequest(url: "/handler1"), response: &responseHandler1)

var responseHandler2 = HttpResponse()
server2.handleRequest(HttpRequest(url: "/handler2"), response: &responseHandler2)

response = HttpResponse()
server2.handleRequest(HttpRequest(url: "/doesnotexist"), response: &response)




// test empty handler chain
let server3 = SimpleHttpServer()
var response3 = HttpResponse()
server3.handleRequest(HttpRequest(), response: &response)

try server.serve(8080, host: "localhost")