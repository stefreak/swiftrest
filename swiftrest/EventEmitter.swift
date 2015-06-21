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

class RemoveToken {
    private init() {
        
    }
}

private class EventListenerContainer<T: EventType>: RemoveToken {
    let listener: (T) -> ()
    var once: Bool

    init(l: (T) -> ()) {
        once = false
        listener = l
    }
}

enum HadListeners {
    case Listeners
    case NoListeners
}

protocol EventEmitting {
    typealias EventType
    typealias RemoveToken
    typealias EventListener = (EventType) -> ()

    /// Adds a listener to the end of the listeners array for the specified event. No checks are made to see if the listener has already been added. Multiple calls passing the same combination of event and listener will result in the listener being added multiple times.
    func addListener(event: EventType, listener: EventListener) -> RemoveToken
    
    /// Adds a one time listener for the event. This listener is invoked only the next time the event is fired, after which it is removed.
    func addOneTimeListener(event: EventType, listener: EventListener) -> RemoveToken
    
    /// Remove a listener from the listener array for the specified event. Caution: changes array indices in the listener array behind the listener. removeListener will remove, at most, one instance of a listener from the listener array. If any single listener has been added multiple times to the listener array for the specified event, then removeListener must be called multiple times to remove each instance.
    func removeListener(event: EventType, token: RemoveToken)
    
    /// Removes all listeners of the specified event. It's not a good idea to remove listeners that were added elsewhere in the code, especially when it's on an emitter that you didn't create (e.g. sockets or file streams).
    func removeAllListeners(event: EventType)
    
    /// Removes all listeners
    func removeAllListeners()
    
    /// By default EventEmitters will print a warning if more than 10 listeners are added for a particular event. This is a useful default which helps finding memory leaks. Obviously not all Emitters should be limited to 10. This function allows that to be increased. Set to zero for unlimited.
    func setMaxListeners(n: Int)
    
    /// emitter.setMaxListeners(n) sets the maximum on a per-instance basis. This class property lets you set it for all EventEmitter instances, current and future, effective immediately. Use with care.
    /// Note that emitter.setMaxListeners(n) still has precedence over EventEmitter.defaultMaxListeners.
    static func setMaxListeners(n: Int)
        
    /// Execute each of the listeners in order with the supplied arguments.
    /// Returns an enum that specifies if the event had listeners
    func emit(event: EventType) -> HadListeners
}

enum ListenerEvent {
    /// This event is emitted any time a listener is added. When this event is triggered, the listener may not yet have been added to the array of listeners for the event.
    case NewListener(RemoveToken)
    case NewListenerType

    /// This event is emitted any time someone removes a listener. When this event is triggered, the listener may not yet have been removed from the array of listeners for the event.
    case RemoveListener(RemoveToken)
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

// compiler crashes when EventEmitter
// inherits from protocol EventEmitting
class EventEmitter/*: EventEmitting*/ {
    private var lookupTable: Dictionary<String, Array<AnyObject>> = Dictionary()
    
    func addListener<T: EventType>(event: T, listener: (T) -> ()) -> RemoveToken {
        return _addListener(event, listener: listener, once: false)
    }

    func addOneTimeListener<T: EventType>(event: T, listener: (T) -> ()) -> RemoveToken {
        return _addListener(event, listener: listener, once: true)
    }

    private func _addListener<T: EventType>(event: T, listener: (T) -> (), once: Bool) -> RemoveToken {
        prepareLookupTableForEvent(event)

        let removeToken = EventListenerContainer<T>(l: listener)
        removeToken.once = once
        emit(ListenerEvent.NewListener(removeToken))

        lookupTable[event.name()]!.append(removeToken)
        return removeToken
    }

    func removeListener<T: EventType>(event: T, token: RemoveToken) {
        prepareLookupTableForEvent(event)
        _removeListener(event.name(), token: token)
    }

    private func _removeListener(eventName: String, token: RemoveToken) {
        emit(ListenerEvent.RemoveListener(token))
        let optional = lookupTable[eventName]!.indexOf { $0 === token }
        if let index = optional {
            lookupTable[eventName]!.removeAtIndex(index)
        }
    }

    func removeAllListeners(event: EventType) {
        prepareLookupTableForEvent(event)
        for removeToken in self.lookupTable[event.name()]! {
            _removeListener(event.name(), token:removeToken as! RemoveToken)
        }
    }

    func removeAllListeners() {
        for (eventName, listeners) in self.lookupTable {
            for removeToken in listeners {
                _removeListener(eventName, token:removeToken as! RemoveToken)
            }
        }
    }

    func setMaxListeners(n: Int) {
        // TODO: implementation
    }
    
    static func setMaxListeners(n: Int) {
        // TODO: implementation
    }
    
    private func listeners<T: EventType>(event: T) -> [EventListenerContainer<T>] {
        prepareLookupTableForEvent(event)

        // TODO: generator may be much more efficient than this implementation.
        var listeners: [EventListenerContainer<T>] = Array()
        for removeToken in lookupTable[event.name()]! {
            if let container = removeToken as? EventListenerContainer<T> {
                listeners.append(container)
            }
        }

        return listeners
    }
    
    func emit<T: EventType>(event: T) -> HadListeners {
        let containers = listeners(event)

        switch containers.count {
        case 0:
            return .NoListeners
        default:
            for container in containers {
                container.listener(event)
                if (container.once) {
                    removeListener(event, token: container)
                }
            }
            return .Listeners
        }
    }
    
    private func prepareLookupTableForEvent(event: EventType) {
        if lookupTable.indexForKey(event.name()) == nil {
            lookupTable[event.name()] = []
        }
    }
}

extension EventEmitter {
    func on<T: EventType>(event: T, listener: (T) -> ()) {
        addListener(event, listener: listener)
    }
    
    func once<T: EventType>(event: T, listener: (T) -> ()) {
        addOneTimeListener(event, listener: listener)
    }
}