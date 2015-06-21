//
//  main.swift
//  swiftrest
//
//  Created by Steffen Neubauer on 16/06/15.
//  Copyright © 2015 Steffen Neubauer. All rights reserved.
//

import Foundation


let emitter = EventEmitter()

emitter.on(ListenerEvent.RemoveListenerType, listener: CallbackHandler(callback: { (event: ListenerEvent) -> Void in
    switch event {
    case let .RemoveListener(listener):
        print("removed", listener)
    default:
        print("did not match")
    }
}))

emitter.removeAllListeners()



/*
let con = HttpConnection(type: .Request)
let con2 = HttpConnection(type: .Request)

try con2.receive(return_test_data(), len: return_test_length())
try con.receive(return_test_data(), len: return_test_length())













let server = SimpleHttpServer()

server.addHandler { (request: HttpRequest, response: HttpResponseBuilder, next: NextCallback) -> (Void) in
    response.end("hah! it works!")
}

server.handleRequest(HttpRequest())




// test multiple handlers in chain

let server2 = SimpleHttpServer()

server2.addHandler { (request: HttpRequest, response: HttpResponseBuilder, next: NextCallback) -> (Void) in
    if request.url == "/handler1" {
        response.end("I only lixsten on /handler1!")
    } else {
        next()
    }
}

server2.addHandler { (request: HttpRequest, response: HttpResponseBuilder, next: NextCallback) -> (Void) in
    if request.url == "/handler2" {
        response.end("I only listen on /handler2!")
    } else {
        next()
    }
}

server2.handleRequest(HttpRequest(url: "/handler1"))
server2.handleRequest(HttpRequest(url: "/handler2"))
server2.handleRequest(HttpRequest(url: "/doesnotexist"))




// test empty handler chain
let server3 = SimpleHttpServer()

for var i: Int = 0; i < 1000; i++ {
    server3.addHandler { (request: HttpRequest, response: HttpResponseBuilder, next: NextCallback) -> (Void) in
        next()
    }
}

server3.addHandler { (request: HttpRequest, response: HttpResponseBuilder, next: NextCallback) -> (Void) in
    response.end("hah! it works! \(request.url)")
}


server3.handleRequest(HttpRequest(url: "/asd"))





// TODO Implement in the future
try server.serve(8080, host: "localhost")
*/