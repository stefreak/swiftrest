//
//  Stream.swift
//  swiftrest
//
//  Created by Steffen Neubauer on 20/06/15.
//  Copyright © 2015 Steffen Neubauer. All rights reserved.
//

//import Foundation

protocol EventType {
    func name() -> String
}

typealias AnyEventHandler = EventHandler<EventType>

class EventHandler<T: EventType> {
    func handleEvent(event: T) -> Void {
        assertionFailure("handleEvent must be overridden")
    }
}

class CallbackHandler<T: EventType>: EventHandler<T> {
    typealias Callback = (T) -> ()
    private let callback: Callback

    init(callback: Callback) {
        self.callback = callback
    }

    override func handleEvent(event: T) {
        self.callback(event)
    }
}

enum HadListeners {
    case Listeners
    case NoListeners
}

enum ListenerEvent {
    /// This event is emitted any time a listener is added. When this event is triggered, the listener may not yet have been added to the array of listeners for the event.
    case NewListener(AnyEventHandler)
    case NewListenerType

    /// This event is emitted any time someone removes a listener. When this event is triggered, the listener may not yet have been removed from the array of listeners for the event.
    case RemoveListener(AnyEventHandler)
    case RemoveListenerType
}

extension ListenerEvent: EventType {
    func name() -> String {
        switch self {
        case .NewListener: fallthrough
        case .NewListenerType:
            return "NewListener"
        case .RemoveListener: fallthrough
        case .RemoveListenerType:
            return "RemoveListener"
        }
    }
}

protocol EventEmitting {
    /// Execute each of the listeners in order with the supplied arguments.
    /// Returns an enum that specifies if the event had listeners
    func emit(event: EventType) -> HadListeners
}

class EventEmitter: EventEmitting {
    var lookupTable: Dictionary<String, Array> = Dictionary()

    /// Adds a listener to the end of the listeners array for the specified event. No checks are made to see if the listener has already been added. Multiple calls passing the same combination of event and listener will result in the listener being added multiple times.
    func addListener<T: EventType>(event: T, listener: EventHandler<T>) {
        prepareLookupTableForEvent(event)
        lookupTable[event.name()]!.append(listener)
    }

    /// Adds a one time listener for the event. This listener is invoked only the next time the event is fired, after which it is removed.
    func addOneTimeListener<T: EventType>(event: T, listener: EventHandler<T>) {
        addListener(event, listener: OneTimeHandler<T>(eventEmitter: self, handler: listener))
    }

    /// Remove a listener from the listener array for the specified event. Caution: changes array indices in the listener array behind the listener. removeListener will remove, at most, one instance of a listener from the listener array. If any single listener has been added multiple times to the listener array for the specified event, then removeListener must be called multiple times to remove each instance.
    func removeListener<T: EventType>(event: T, listener: EventHandler<T>) {
        prepareLookupTableForEvent(event)
        _removeListener(event.name(), listener: listener)
    }

    private func _removeListener(eventName: String, listener: AnyObject) {
        emit(ListenerEvent.RemoveListener(listener as! AnyEventHandler))
        lookupTable[eventName]!.indexOf { $0 === listener }
    }

    /// Removes all listeners of the specified event. It's not a good idea to remove listeners that were added elsewhere in the code, especially when it's on an emitter that you didn't create (e.g. sockets or file streams).
    func removeAllListeners<T: EventType>(event: T, eventType:T.Type) {
        for listener in listeners(event) {
            _removeListener(event.name(), listener:listener)
        }
    }

    /// Removes all listeners
    func removeAllListeners() {
        for (eventName, listeners) in self.lookupTable {
            for listener in listeners {
                _removeListener(eventName, listener:listener)
            }
        }
    }

    /// By default EventEmitters will print a warning if more than 10 listeners are added for a particular event. This is a useful default which helps finding memory leaks. Obviously not all Emitters should be limited to 10. This function allows that to be increased. Set to zero for unlimited.
    func setMaxListeners(n: Int) {
        // TODO: implementation
    }
    
    /// emitter.setMaxListeners(n) sets the maximum on a per-instance basis. This class property lets you set it for all EventEmitter instances, current and future, effective immediately. Use with care.
    /// Note that emitter.setMaxListeners(n) still has precedence over EventEmitter.defaultMaxListeners.
    static func setMaxListeners(n: Int) {
        // TODO: implementation
    }
    
    /// Returns an array of listeners for the specified event.
    func listeners<T: EventType>(event: T) -> [EventHandler<T>] {
        prepareLookupTableForEvent(event)
        return lookupTable[event.name()]! as! [EventHandler<T>]
    }

    /// Execute each of the listeners in order with the supplied arguments.
    /// Returns an enum that specifies if the event had listeners
    func emit<T: EventType>(event: T) -> HadListeners {
        let l = listeners(event)

        switch l.count {
        case 0:
            return .NoListeners
        default:
            for listener in l {
                listener.handleEvent(event)
            }
            return .Listeners
        }
    }
    
    func prepareLookupTableForEvent(event: EventType) {
        if lookupTable.indexForKey(event.name()) == nil {
            lookupTable[event.name()] = []
        }
    }

    /// alias for addListener
    func on<T: EventType>(event: T, listener: EventHandler<T>) {
        addListener(event, listener: listener)
    }

    /// alias for addOneTimeListener
    func once<T: EventType>(event: T, listener: EventHandler<T>) {
        addOneTimeListener(event, listener: listener)
    }
}

private class OneTimeHandler<T: EventType>: EventHandler<T> {
    weak var emitter: EventEmitter?
    let handler: EventHandler<T>

    init(eventEmitter: EventEmitter, handler:EventHandler<T>) {
        self.emitter = eventEmitter
        self.handler = handler
    }

    override func handleEvent(event: T) {
        handler.handleEvent(event)
        emitter?.removeListener(event, listener: handler)
    }
}