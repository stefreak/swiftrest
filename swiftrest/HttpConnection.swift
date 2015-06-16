//
//  ConnectionStream.swift
//  swiftrest
//
//  Created by Steffen Neubauer on 16/06/15.
//  Copyright © 2015 Steffen Neubauer. All rights reserved.
//

//import Foundation

extension String {
    static func fromCString(cs: UnsafePointer<CChar>, withLength len: Int) -> String? {
        // TODO: find more efficient algorithm (i think this is real bullshit :D)
        if var str = String.fromCString(cs) {
            str.removeRange(advance(str.startIndex, len)..<str.endIndex)
            return str
        }
        
        return nil;
    }
}

enum ShouldContinueParsing: Int32 {
    case Continue = 0
    case Stop = 1
}

enum HttpConnectionType {
    case Request
    case Response
    case Both

    func httpParserType() -> http_parser_type {
        switch self {
        case .Both:
            return HTTP_BOTH
        case .Request:
            return HTTP_REQUEST
        case .Response:
            return HTTP_RESPONSE
        }
    }
}

enum ParseError : ErrorType {
    case Unknown
}

class HttpConnection {
    let type : HttpConnectionType;

    private var parser : http_parser;
    private var settings : http_parser_settings;

    private static var mapHack = Dictionary<UnsafeMutablePointer<http_parser>, HttpConnection>();
    
    enum Event {
        case MessageBegin
        case URL(String)
        case Status(String)
        case HeaderField(String)
        case HeaderValue(String)
        case HeadersComplete
        case Body(String)
        case MessageComplete
        case ChunkHeader
        case ChunkComplete
    }
    
    private enum RawEvent {
        case MessageBegin
        case URL(UnsafePointer<Int8>, Int)
        case Status(UnsafePointer<Int8>, Int)
        case HeaderField(UnsafePointer<Int8>, Int)
        case HeaderValue(UnsafePointer<Int8>, Int)
        case HeadersComplete
        case Body(UnsafePointer<Int8>, Int)
        case MessageComplete
        case ChunkHeader
        case ChunkComplete
    }

    init(type: HttpConnectionType) {
        self.parser = http_parser()
        self.type = type
        self.settings = http_parser_settings(on_message_begin: { (parser: UnsafeMutablePointer<http_parser>) -> Int32 in
                return HttpConnection.handleRawEvent(parser, rawEvent: .MessageBegin).rawValue
            }, on_url: { (parser:UnsafeMutablePointer<http_parser>, chunk: UnsafePointer<Int8>, len: Int) -> Int32 in
                return HttpConnection.handleRawEvent(parser, rawEvent: .URL(chunk, len)).rawValue
            }, on_status: { (parser:UnsafeMutablePointer<http_parser>, chunk: UnsafePointer<Int8>, len: Int) -> Int32 in
                return HttpConnection.handleRawEvent(parser, rawEvent: .Status(chunk, len)).rawValue
            }, on_header_field: { (parser:UnsafeMutablePointer<http_parser>, chunk: UnsafePointer<Int8>, len: Int) -> Int32 in
                return HttpConnection.handleRawEvent(parser, rawEvent: .HeaderField(chunk, len)).rawValue
            }, on_header_value: { (parser:UnsafeMutablePointer<http_parser>, chunk: UnsafePointer<Int8>, len: Int) -> Int32 in
                return HttpConnection.handleRawEvent(parser, rawEvent: .HeaderValue(chunk, len)).rawValue
            }, on_headers_complete: { (parser: UnsafeMutablePointer<http_parser>) -> Int32 in
                return HttpConnection.handleRawEvent(parser, rawEvent: .HeadersComplete).rawValue
            }, on_body: { (parser:UnsafeMutablePointer<http_parser>, chunk: UnsafePointer<Int8>, len: Int) -> Int32 in
                return HttpConnection.handleRawEvent(parser, rawEvent: .Body(chunk, len)).rawValue
            }, on_message_complete: { (parser: UnsafeMutablePointer<http_parser>) -> Int32 in
                return HttpConnection.handleRawEvent(parser, rawEvent: .MessageComplete).rawValue
            }, on_chunk_header: { (parser: UnsafeMutablePointer<http_parser>) -> Int32 in
                return HttpConnection.handleRawEvent(parser, rawEvent: .ChunkHeader).rawValue
            }) { (parser: UnsafeMutablePointer<http_parser>) -> Int32 in
                return HttpConnection.handleRawEvent(parser, rawEvent: .ChunkComplete).rawValue
        }

        http_parser_init(&parser, type.httpParserType())
        
        HttpConnection.mapHack[&parser] = self
    }

    deinit {
        HttpConnection.mapHack.removeValueForKey(&parser)
    }
    

    func receive(data: UnsafePointer<Int8>, len: Int) throws {
        let nparsed = http_parser_execute(&parser, &self.settings, data, len)
        
        if (nparsed != len) {
            throw ParseError.Unknown
        }
    }
    
    private static func handleRawEvent(parser: UnsafeMutablePointer<http_parser>, rawEvent: RawEvent) -> ShouldContinueParsing {
        
        var event : Event
        
        switch rawEvent {
        case .MessageBegin:
            event = .MessageBegin
        case let .URL(str, len):
            event = .URL(String.fromCString(str, withLength:len)!)
        case let .Status(str, len):
            event = .Status(String.fromCString(str, withLength:len)!)
        case let .HeaderField(str, len):
            event = .HeaderField(String.fromCString(str, withLength:len)!)
        case let .HeaderValue(str, len):
            event = .HeaderValue(String.fromCString(str, withLength:len)!)
        case .HeadersComplete:
            event = .HeadersComplete
        case let .Body(str, len):
            event = .Body(String.fromCString(str, withLength:len)!)
        case .MessageComplete:
            event = .MessageComplete
        case .ChunkHeader:
            event = .ChunkHeader
        case .ChunkComplete:
            event = .ChunkComplete
        }
        
        return HttpConnection.mapHack[parser]!.handleEvent(event)
    }
    
    private func handleEvent(event: Event) -> ShouldContinueParsing {
        switch event {
        case .MessageBegin:
            print("message begin")
        case let .URL(str):
            print("url: \(str)")
        case let .Status(str):
            print("status: \(str)")
        case let .HeaderField(str):
            print("header field: \(str)")
        case let .HeaderValue(str):
            print("header value: \(str)")
        case .HeadersComplete:
            print("header complete")
        case let .Body(str):
            print("body: \(str)")
        case .MessageComplete:
            print("message complete")
        case .ChunkHeader:
            print("chunk header")
        case .ChunkComplete:
            print("chunk complete")
        }
        return .Continue
    }
}