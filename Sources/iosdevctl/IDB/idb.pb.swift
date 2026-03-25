// DO NOT EDIT.
// Pre-generated from idb proto definitions — HID subset only.
// Source: https://github.com/facebook/idb/blob/main/proto/idb.proto

import Foundation
import SwiftProtobuf

// MARK: - HIDButtonType

enum HIDButtonType: SwiftProtobuf.Enum {
    typealias RawValue = Int

    case applePay   // = 0
    case home       // = 1
    case lock       // = 2
    case sideButton // = 3
    case siri       // = 4
    case UNRECOGNIZED(Int)

    init() { self = .applePay }

    init?(rawValue: Int) {
        switch rawValue {
        case 0: self = .applePay
        case 1: self = .home
        case 2: self = .lock
        case 3: self = .sideButton
        case 4: self = .siri
        default: self = .UNRECOGNIZED(rawValue)
        }
    }

    var rawValue: Int {
        switch self {
        case .applePay:            return 0
        case .home:                return 1
        case .lock:                return 2
        case .sideButton:          return 3
        case .siri:                return 4
        case .UNRECOGNIZED(let v): return v
        }
    }
}

extension HIDButtonType: SwiftProtobuf._ProtoNameProviding {
    static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
        0: .same(proto: "APPLE_PAY"),
        1: .same(proto: "HOME"),
        2: .same(proto: "LOCK"),
        3: .same(proto: "SIDE_BUTTON"),
        4: .same(proto: "SIRI")
    ]
}

// MARK: - Point

struct Idb_Point {
    var x: Double = 0
    var y: Double = 0
    var unknownFields = SwiftProtobuf.UnknownStorage()

    init() {}
}

extension Idb_Point: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
    static let protoMessageName: String = "Point"
    static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
        1: .same(proto: "x"),
        2: .same(proto: "y")
    ]

    mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
        while let fieldNum = try decoder.nextFieldNumber() {
            switch fieldNum {
            case 1: try decoder.decodeSingularDoubleField(value: &x)
            case 2: try decoder.decodeSingularDoubleField(value: &y)
            default: break
            }
        }
    }

    func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
        if x != 0 { try visitor.visitSingularDoubleField(value: x, fieldNumber: 1) }
        if y != 0 { try visitor.visitSingularDoubleField(value: y, fieldNumber: 2) }
        try unknownFields.traverse(visitor: &visitor)
    }

    static func == (lhs: Idb_Point, rhs: Idb_Point) -> Bool {
        lhs.x == rhs.x && lhs.y == rhs.y
    }
}

// MARK: - HIDEvent

struct Idb_HIDEvent {

    // MARK: HIDPressAction

    struct HIDPressAction {

        struct HIDPress {
            var unknownFields = SwiftProtobuf.UnknownStorage()
            init() {}
        }

        struct HIDLift {
            var unknownFields = SwiftProtobuf.UnknownStorage()
            init() {}
        }

        enum OneOf_Action: Equatable {
            case press(HIDPress)
            case lift(HIDLift)
        }

        var action: OneOf_Action? = nil
        var unknownFields = SwiftProtobuf.UnknownStorage()

        init() {}
    }

    // MARK: HIDTouch

    struct HIDTouch {
        var action: HIDPressAction = HIDPressAction()
        var point: Idb_Point = Idb_Point()
        var unknownFields = SwiftProtobuf.UnknownStorage()
        init() {}
    }

    // MARK: HIDButton

    struct HIDButton {
        var action: HIDPressAction = HIDPressAction()
        var button: HIDButtonType = .applePay
        var unknownFields = SwiftProtobuf.UnknownStorage()
        init() {}
    }

    // MARK: HIDKey

    struct HIDKey {
        var action: HIDPressAction = HIDPressAction()
        var keycode: UInt64 = 0
        var unknownFields = SwiftProtobuf.UnknownStorage()
        init() {}
    }

    // MARK: OneOf_Event

    enum OneOf_Event: Equatable {
        case touch(HIDTouch)
        case button(HIDButton)
        case key(HIDKey)
    }

    var event: OneOf_Event? = nil
    var unknownFields = SwiftProtobuf.UnknownStorage()

    init() {}
}

// MARK: - HIDResponse

struct Idb_HIDResponse {
    var unknownFields = SwiftProtobuf.UnknownStorage()
    init() {}
}

// MARK: - SwiftProtobuf.Message conformances

// MARK: HIDPressAction.HIDPress

extension Idb_HIDEvent.HIDPressAction.HIDPress: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
    static let protoMessageName: String = "HIDEvent.HIDPressAction.HIDPress"
    static let _protobuf_nameMap: SwiftProtobuf._NameMap = [:]

    mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
        while let _ = try decoder.nextFieldNumber() {}
    }

    func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
        try unknownFields.traverse(visitor: &visitor)
    }

    static func == (lhs: Idb_HIDEvent.HIDPressAction.HIDPress, rhs: Idb_HIDEvent.HIDPressAction.HIDPress) -> Bool {
        lhs.unknownFields == rhs.unknownFields
    }
}

// MARK: HIDPressAction.HIDLift

extension Idb_HIDEvent.HIDPressAction.HIDLift: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
    static let protoMessageName: String = "HIDEvent.HIDPressAction.HIDLift"
    static let _protobuf_nameMap: SwiftProtobuf._NameMap = [:]

    mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
        while let _ = try decoder.nextFieldNumber() {}
    }

    func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
        try unknownFields.traverse(visitor: &visitor)
    }

    static func == (lhs: Idb_HIDEvent.HIDPressAction.HIDLift, rhs: Idb_HIDEvent.HIDPressAction.HIDLift) -> Bool {
        lhs.unknownFields == rhs.unknownFields
    }
}

// MARK: HIDPressAction

extension Idb_HIDEvent.HIDPressAction: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
    static let protoMessageName: String = "HIDEvent.HIDPressAction"
    static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
        1: .same(proto: "press"),
        2: .same(proto: "lift")
    ]

    mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
        while let fieldNum = try decoder.nextFieldNumber() {
            switch fieldNum {
            case 1:
                var v: HIDPress? = nil
                try decoder.decodeSingularMessageField(value: &v)
                if let v { action = .press(v) }
            case 2:
                var v: HIDLift? = nil
                try decoder.decodeSingularMessageField(value: &v)
                if let v { action = .lift(v) }
            default: break
            }
        }
    }

    func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
        switch action {
        case .press(let v)?:
            try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
        case .lift(let v)?:
            try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
        case nil: break
        }
        try unknownFields.traverse(visitor: &visitor)
    }

    static func == (lhs: Idb_HIDEvent.HIDPressAction, rhs: Idb_HIDEvent.HIDPressAction) -> Bool {
        lhs.action == rhs.action
    }
}

// MARK: HIDTouch

extension Idb_HIDEvent.HIDTouch: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
    static let protoMessageName: String = "HIDEvent.HIDTouch"
    static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
        1: .same(proto: "action"),
        2: .same(proto: "point")
    ]

    mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
        while let fieldNum = try decoder.nextFieldNumber() {
            switch fieldNum {
            case 1:
                var v: Idb_HIDEvent.HIDPressAction? = nil
                try decoder.decodeSingularMessageField(value: &v)
                if let v { action = v }
            case 2:
                var v: Idb_Point? = nil
                try decoder.decodeSingularMessageField(value: &v)
                if let v { point = v }
            default: break
            }
        }
    }

    func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
        if action != Idb_HIDEvent.HIDPressAction() {
            try visitor.visitSingularMessageField(value: action, fieldNumber: 1)
        }
        if point != Idb_Point() {
            try visitor.visitSingularMessageField(value: point, fieldNumber: 2)
        }
        try unknownFields.traverse(visitor: &visitor)
    }

    static func == (lhs: Idb_HIDEvent.HIDTouch, rhs: Idb_HIDEvent.HIDTouch) -> Bool {
        lhs.action == rhs.action && lhs.point == rhs.point
    }
}

// MARK: HIDButton

extension Idb_HIDEvent.HIDButton: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
    static let protoMessageName: String = "HIDEvent.HIDButton"
    static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
        1: .same(proto: "action"),
        2: .same(proto: "button")
    ]

    mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
        while let fieldNum = try decoder.nextFieldNumber() {
            switch fieldNum {
            case 1:
                var v: Idb_HIDEvent.HIDPressAction? = nil
                try decoder.decodeSingularMessageField(value: &v)
                if let v { action = v }
            case 2: try decoder.decodeSingularEnumField(value: &button)
            default: break
            }
        }
    }

    func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
        if action != Idb_HIDEvent.HIDPressAction() {
            try visitor.visitSingularMessageField(value: action, fieldNumber: 1)
        }
        if button != .applePay {
            try visitor.visitSingularEnumField(value: button, fieldNumber: 2)
        }
        try unknownFields.traverse(visitor: &visitor)
    }

    static func == (lhs: Idb_HIDEvent.HIDButton, rhs: Idb_HIDEvent.HIDButton) -> Bool {
        lhs.action == rhs.action && lhs.button == rhs.button
    }
}

// MARK: HIDKey

extension Idb_HIDEvent.HIDKey: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
    static let protoMessageName: String = "HIDEvent.HIDKey"
    static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
        1: .same(proto: "action"),
        2: .same(proto: "keycode")
    ]

    mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
        while let fieldNum = try decoder.nextFieldNumber() {
            switch fieldNum {
            case 1:
                var v: Idb_HIDEvent.HIDPressAction? = nil
                try decoder.decodeSingularMessageField(value: &v)
                if let v { action = v }
            case 2: try decoder.decodeSingularUInt64Field(value: &keycode)
            default: break
            }
        }
    }

    func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
        if action != Idb_HIDEvent.HIDPressAction() {
            try visitor.visitSingularMessageField(value: action, fieldNumber: 1)
        }
        if keycode != 0 {
            try visitor.visitSingularUInt64Field(value: keycode, fieldNumber: 2)
        }
        try unknownFields.traverse(visitor: &visitor)
    }

    static func == (lhs: Idb_HIDEvent.HIDKey, rhs: Idb_HIDEvent.HIDKey) -> Bool {
        lhs.action == rhs.action && lhs.keycode == rhs.keycode
    }
}

// MARK: HIDEvent

extension Idb_HIDEvent: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
    static let protoMessageName: String = "HIDEvent"
    static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
        1: .same(proto: "touch"),
        2: .same(proto: "button"),
        3: .same(proto: "key")
    ]

    mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
        while let fieldNum = try decoder.nextFieldNumber() {
            switch fieldNum {
            case 1:
                var v: HIDTouch? = nil
                try decoder.decodeSingularMessageField(value: &v)
                if let v { event = .touch(v) }
            case 2:
                var v: HIDButton? = nil
                try decoder.decodeSingularMessageField(value: &v)
                if let v { event = .button(v) }
            case 3:
                var v: HIDKey? = nil
                try decoder.decodeSingularMessageField(value: &v)
                if let v { event = .key(v) }
            default: break
            }
        }
    }

    func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
        switch event {
        case .touch(let v)?:
            try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
        case .button(let v)?:
            try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
        case .key(let v)?:
            try visitor.visitSingularMessageField(value: v, fieldNumber: 3)
        case nil: break
        }
        try unknownFields.traverse(visitor: &visitor)
    }

    static func == (lhs: Idb_HIDEvent, rhs: Idb_HIDEvent) -> Bool {
        lhs.event == rhs.event
    }
}

// MARK: HIDResponse

extension Idb_HIDResponse: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
    static let protoMessageName: String = "HIDResponse"
    static let _protobuf_nameMap: SwiftProtobuf._NameMap = [:]

    mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
        while let _ = try decoder.nextFieldNumber() {}
    }

    func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
        try unknownFields.traverse(visitor: &visitor)
    }

    static func == (lhs: Idb_HIDResponse, rhs: Idb_HIDResponse) -> Bool {
        lhs.unknownFields == rhs.unknownFields
    }
}
