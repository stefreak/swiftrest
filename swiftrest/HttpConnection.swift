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
    typealias RawType = Int32
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

    typealias HttpParserRef = UnsafeMutablePointer<http_parser>
    typealias RawData = UnsafePointer<Int8>

    private static var mapHack = Dictionary<HttpParserRef, HttpConnection>();
    
    private enum Event {
        case MessageBegin
        case URL(RawData, Int)
        case Status(RawData, Int)
        case HeaderField(RawData, Int)
        case HeaderValue(RawData, Int)
        case HeadersComplete
        case Body(RawData, Int)
        case MessageComplete
        case ChunkHeader
        case ChunkComplete
        
        func stringValue() -> String? {
            if let bytes = self.rawBytesPointer(), len = self.rawBytesLength() {
                return String.fromCString(bytes, withLength: len)
            }

            return nil
        }

        func rawBytesPointer() -> RawData? {
            switch self {
            case let .URL(bytes, _):
                return bytes
            case let .Status(bytes, _):
                return bytes
            case let .HeaderField(bytes, _):
                return bytes
            case let .HeaderValue(bytes, _):
                return bytes
            case let .Body(bytes, _):
                return bytes
            default:
                return nil;
            }
        }

        func rawBytesLength() -> Int? {
            switch self {
            case let .URL(_, len):
                return len
            case let .Status(_, len):
                return len
            case let .HeaderField(_, len):
                return len
            case let .HeaderValue(_, len):
                return len
            case let .Body(_, len):
                return len
            default:
                return nil;
            }
        }
    }

    
    init(type: HttpConnectionType) {
        self.parser = http_parser()
        self.type = type
        self.settings = http_parser_settings(
            on_message_begin: { (parser: HttpParserRef) -> Int32 in
                return HttpConnection.handleEvent(parser, event: .MessageBegin)
            },

            on_url: { (parser:HttpParserRef, chunk: RawData, len: Int) -> Int32 in
                return HttpConnection.handleEvent(parser, event: .URL(chunk, len))
            },

            on_status: { (parser:HttpParserRef, chunk: RawData, len: Int) -> Int32 in
                return HttpConnection.handleEvent(parser, event: .Status(chunk, len))
            },
            
            on_header_field: { (parser:HttpParserRef, chunk: RawData, len: Int) -> Int32 in
                return HttpConnection.handleEvent(parser, event: .HeaderField(chunk, len))
            },
            
            on_header_value: { (parser:HttpParserRef, chunk: RawData, len: Int) -> Int32 in
                return HttpConnection.handleEvent(parser, event: .HeaderValue(chunk, len))
            },
            
            on_headers_complete: { (parser: HttpParserRef) -> Int32 in
                return HttpConnection.handleEvent(parser, event: .HeadersComplete)
            },
            
            on_body: { (parser:HttpParserRef, chunk: RawData, len: Int) -> Int32 in
                return HttpConnection.handleEvent(parser, event: .Body(chunk, len))
            },
            
            on_message_complete: { (parser: HttpParserRef) -> Int32 in
                return HttpConnection.handleEvent(parser, event: .MessageComplete)
            },
            
            on_chunk_header: { (parser: HttpParserRef) -> Int32 in
                return HttpConnection.handleEvent(parser, event: .ChunkHeader)
            },
        
            on_chunk_complete: { (parser: HttpParserRef) -> Int32 in
                return HttpConnection.handleEvent(parser, event: .ChunkComplete)
            }
        )

        http_parser_init(&parser, type.httpParserType())
        
        HttpConnection.mapHack[&parser] = self
    }

    deinit {
        HttpConnection.mapHack.removeValueForKey(&parser)
    }
    

    func receive(data: RawData, len: Int) throws {
        let nparsed = http_parser_execute(&parser, &self.settings, data, len)
        
        if (nparsed != len) {
            throw ParseError.Unknown
        }
    }
    
    private static func handleEvent(parser: HttpParserRef, event: Event) -> ShouldContinueParsing.RawType {
        return HttpConnection.mapHack[parser]!.handleEvent(event).rawValue
    }
    
    private func handleEvent(event: Event) -> ShouldContinueParsing {
        switch event {
        case .MessageBegin:
            print("message begin")
        case .URL:
            print("url: \(event.stringValue())")
        case .Status:
            print("status: \(event.stringValue())")
        case .HeaderField:
            print("header field: \(event.stringValue())")
        case .HeaderValue:
            print("header value: \(event.stringValue())")
        case .HeadersComplete:
            print("header complete")
        case .Body:
            print("body: \(event.stringValue())")
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