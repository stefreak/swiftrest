//
//  Stream.swift
//  swiftrest
//
//  Created by Steffen Neubauer on 21/06/15.
//  Copyright © 2015 Steffen Neubauer. All rights reserved.
//

//import Foundation

enum StreamEncoding {
    case UTF8
}

enum ReadEvent {
    case Readable

    case StringData(String)
    case StringDataType

    case BufferData([UInt8])
    case BufferDataType

    case End

    case Close

    case Error(ErrorType)
    case ErrorT
}

extension ReadEvent: EventType {
    func name() -> String {
        switch self {
        case .Readable:
            return "Readable"
        case .StringData: fallthrough
        case .StringDataType:
            return "StringData"
        case .BufferData: fallthrough
        case .BufferDataType:
            return "BufferData"
        case .End:
            return "End"
        case .Close:
            return "Close"
        case .Error: fallthrough
        case .ErrorT:
            return "Error"
        }
    }
}

protocol Readable: EventEmitting {
    /// The read() method pulls some data out of the internal buffer and returns it. If there is no data available, then it will return null.
    /// It will return `len` bytes. If size bytes are not available, then it will return null.
    func readString(len: Int) -> String?

    func readString() -> String?
    
    func readBuffer(len: Int) -> [UInt8]?
    
    func readBuffer() -> [UInt8]?

    func setEncoding(encoding: StreamEncoding)

    func resume()

    func pause()

    func isPaused() -> Bool

    func pipe<T: Writable>(writable: T)

    func pipeNoEnd<T: Writable>(writable: T)

    func unpipe<T: Writable>(writable: T)

    func unpipeAll()

    func unshift(buffer: [UInt8])
}


enum WriteEvent {
    case Drain

    case Finish

    case Pipe(Readable)
    case PipeType

    case Unpipe(Readable)
    case UnpipeType
    
    case Error(ErrorType)
    case ErrorT
}

extension WriteEvent: EventType {
    func name() -> String {
        switch self {
        case .Drain:
            return "Drain"
        case .Finish:
            return "Finish"
        case .Pipe: fallthrough
        case .PipeType:
            return "Pipe"
        case .Unpipe: fallthrough
        case .UnpipeType:
            return "Pipe"
        case .Error: fallthrough
        case .ErrorT:
            return "Error"
        }
    }
}

enum ShouldContinueWriting {
    case ContinueWriting
    case StopWriting
}

protocol Writable: EventEmitting {
    typealias Callback = () -> ()

    func writeString(chunk: String, encoding: StreamEncoding) -> ShouldContinueWriting
    
    func writeString(chunk: String, encoding: StreamEncoding, callback: Callback) -> ShouldContinueWriting
    
    func writeBuffer(chunk: [UInt8]) -> ShouldContinueWriting
    
    func writeBuffer(chunk: [UInt8], callback: Callback) -> ShouldContinueWriting

    func cork()

    func uncork()

    /// Sets the default encoding for a writable stream. Returns true if the encoding is valid and is set. Otherwise returns false.
    func setDefaultEncoding(encoding: StreamEncoding) -> Bool

    func end()

    func endString(chunk: String, encoding: StreamEncoding)

    func endString(chunk: String, encoding: StreamEncoding, callback: Callback)

    func endBuffer(chunk: [UInt8])
    
    func endBuffer(chunk: [UInt8], callback: Callback)
}