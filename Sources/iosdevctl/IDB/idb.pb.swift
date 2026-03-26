// DO NOT EDIT.
// Pre-generated from idb proto definitions — HID + Accessibility subset.
// Source: https://github.com/facebook/idb/blob/main/proto/idb.proto
// Field numbers verified against the serialized FileDescriptorProto in idb_pb2.py.

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

// MARK: - HIDDirection

enum HIDDirection: SwiftProtobuf.Enum {
    typealias RawValue = Int

    case down // = 0
    case up   // = 1
    case UNRECOGNIZED(Int)

    init() { self = .down }

    init?(rawValue: Int) {
        switch rawValue {
        case 0: self = .down
        case 1: self = .up
        default: self = .UNRECOGNIZED(rawValue)
        }
    }

    var rawValue: Int {
        switch self {
        case .down:                return 0
        case .up:                  return 1
        case .UNRECOGNIZED(let v): return v
        }
    }
}

extension HIDDirection: SwiftProtobuf._ProtoNameProviding {
    static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
        0: .same(proto: "DOWN"),
        1: .same(proto: "UP")
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
//
// Real proto structure (verified from serialized descriptor in idb_pb2.py):
//
//   message HIDEvent {
//     oneof event {
//       HIDPress press = 1;
//       HIDSwipe swipe = 2;
//       HIDDelay delay = 3;
//     }
//     message HIDTouch   { Point point = 1; }
//     message HIDButton  { HIDButtonType button = 1; }
//     message HIDKey     { uint64 keycode = 1; }
//     message HIDPressAction {
//       oneof action { HIDTouch touch = 1; HIDButton button = 2; HIDKey key = 3; }
//     }
//     message HIDPress   { HIDPressAction action = 1; HIDDirection direction = 2; }
//     message HIDSwipe   { Point start = 1; Point end = 2; double delta = 5; double duration = 6; }
//     message HIDDelay   { double duration = 1; }
//   }

struct Idb_HIDEvent {

    // MARK: HIDTouch

    struct HIDTouch {
        var point: Idb_Point = Idb_Point()
        var unknownFields = SwiftProtobuf.UnknownStorage()
        init() {}
    }

    // MARK: HIDButton

    struct HIDButton {
        var button: HIDButtonType = .applePay
        var unknownFields = SwiftProtobuf.UnknownStorage()
        init() {}
    }

    // MARK: HIDKey

    struct HIDKey {
        var keycode: UInt64 = 0
        var unknownFields = SwiftProtobuf.UnknownStorage()
        init() {}
    }

    // MARK: HIDPressAction

    struct HIDPressAction {
        enum OneOf_Action: Equatable {
            case touch(HIDTouch)
            case button(HIDButton)
            case key(HIDKey)
        }
        var action: OneOf_Action? = nil
        var unknownFields = SwiftProtobuf.UnknownStorage()
        init() {}
    }

    // MARK: HIDPress

    struct HIDPress {
        var action: HIDPressAction = HIDPressAction()
        var direction: HIDDirection = .down
        var unknownFields = SwiftProtobuf.UnknownStorage()
        init() {}
    }

    // MARK: HIDSwipe

    struct HIDSwipe {
        var start: Idb_Point = Idb_Point()
        var end: Idb_Point = Idb_Point()
        var delta: Double = 0    // field 5
        var duration: Double = 0 // field 6
        var unknownFields = SwiftProtobuf.UnknownStorage()
        init() {}
    }

    // MARK: HIDDelay

    struct HIDDelay {
        var duration: Double = 0
        var unknownFields = SwiftProtobuf.UnknownStorage()
        init() {}
    }

    // MARK: OneOf_Event

    enum OneOf_Event: Equatable {
        case press(HIDPress)
        case swipe(HIDSwipe)
        case delay(HIDDelay)
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

// MARK: HIDTouch

extension Idb_HIDEvent.HIDTouch: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
    static let protoMessageName: String = "HIDEvent.HIDTouch"
    static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
        1: .same(proto: "point")
    ]

    mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
        while let fieldNum = try decoder.nextFieldNumber() {
            switch fieldNum {
            case 1:
                var v: Idb_Point? = nil
                try decoder.decodeSingularMessageField(value: &v)
                if let v { point = v }
            default: break
            }
        }
    }

    func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
        if point != Idb_Point() {
            try visitor.visitSingularMessageField(value: point, fieldNumber: 1)
        }
        try unknownFields.traverse(visitor: &visitor)
    }

    static func == (lhs: Idb_HIDEvent.HIDTouch, rhs: Idb_HIDEvent.HIDTouch) -> Bool {
        lhs.point == rhs.point
    }
}

// MARK: HIDButton

extension Idb_HIDEvent.HIDButton: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
    static let protoMessageName: String = "HIDEvent.HIDButton"
    static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
        1: .same(proto: "button")
    ]

    mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
        while let fieldNum = try decoder.nextFieldNumber() {
            switch fieldNum {
            case 1: try decoder.decodeSingularEnumField(value: &button)
            default: break
            }
        }
    }

    func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
        if button != .applePay {
            try visitor.visitSingularEnumField(value: button, fieldNumber: 1)
        }
        try unknownFields.traverse(visitor: &visitor)
    }

    static func == (lhs: Idb_HIDEvent.HIDButton, rhs: Idb_HIDEvent.HIDButton) -> Bool {
        lhs.button == rhs.button
    }
}

// MARK: HIDKey

extension Idb_HIDEvent.HIDKey: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
    static let protoMessageName: String = "HIDEvent.HIDKey"
    static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
        1: .same(proto: "keycode")
    ]

    mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
        while let fieldNum = try decoder.nextFieldNumber() {
            switch fieldNum {
            case 1: try decoder.decodeSingularUInt64Field(value: &keycode)
            default: break
            }
        }
    }

    func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
        if keycode != 0 {
            try visitor.visitSingularUInt64Field(value: keycode, fieldNumber: 1)
        }
        try unknownFields.traverse(visitor: &visitor)
    }

    static func == (lhs: Idb_HIDEvent.HIDKey, rhs: Idb_HIDEvent.HIDKey) -> Bool {
        lhs.keycode == rhs.keycode
    }
}

// MARK: HIDPressAction

extension Idb_HIDEvent.HIDPressAction: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
    static let protoMessageName: String = "HIDEvent.HIDPressAction"
    static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
        1: .same(proto: "touch"),
        2: .same(proto: "button"),
        3: .same(proto: "key")
    ]

    mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
        while let fieldNum = try decoder.nextFieldNumber() {
            switch fieldNum {
            case 1:
                var v: Idb_HIDEvent.HIDTouch? = nil
                try decoder.decodeSingularMessageField(value: &v)
                if let v { action = .touch(v) }
            case 2:
                var v: Idb_HIDEvent.HIDButton? = nil
                try decoder.decodeSingularMessageField(value: &v)
                if let v { action = .button(v) }
            case 3:
                var v: Idb_HIDEvent.HIDKey? = nil
                try decoder.decodeSingularMessageField(value: &v)
                if let v { action = .key(v) }
            default: break
            }
        }
    }

    func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
        switch action {
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

    static func == (lhs: Idb_HIDEvent.HIDPressAction, rhs: Idb_HIDEvent.HIDPressAction) -> Bool {
        lhs.action == rhs.action
    }
}

// MARK: HIDPress

extension Idb_HIDEvent.HIDPress: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
    static let protoMessageName: String = "HIDEvent.HIDPress"
    static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
        1: .same(proto: "action"),
        2: .same(proto: "direction")
    ]

    mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
        while let fieldNum = try decoder.nextFieldNumber() {
            switch fieldNum {
            case 1:
                var v: Idb_HIDEvent.HIDPressAction? = nil
                try decoder.decodeSingularMessageField(value: &v)
                if let v { action = v }
            case 2: try decoder.decodeSingularEnumField(value: &direction)
            default: break
            }
        }
    }

    func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
        if action != Idb_HIDEvent.HIDPressAction() {
            try visitor.visitSingularMessageField(value: action, fieldNumber: 1)
        }
        if direction != .down {
            try visitor.visitSingularEnumField(value: direction, fieldNumber: 2)
        }
        try unknownFields.traverse(visitor: &visitor)
    }

    static func == (lhs: Idb_HIDEvent.HIDPress, rhs: Idb_HIDEvent.HIDPress) -> Bool {
        lhs.action == rhs.action && lhs.direction == rhs.direction
    }
}

// MARK: HIDSwipe

extension Idb_HIDEvent.HIDSwipe: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
    static let protoMessageName: String = "HIDEvent.HIDSwipe"
    static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
        1: .same(proto: "start"),
        2: .same(proto: "end"),
        5: .same(proto: "delta"),
        6: .same(proto: "duration")
    ]

    mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
        while let fieldNum = try decoder.nextFieldNumber() {
            switch fieldNum {
            case 1:
                var v: Idb_Point? = nil
                try decoder.decodeSingularMessageField(value: &v)
                if let v { start = v }
            case 2:
                var v: Idb_Point? = nil
                try decoder.decodeSingularMessageField(value: &v)
                if let v { end = v }
            case 5: try decoder.decodeSingularDoubleField(value: &delta)
            case 6: try decoder.decodeSingularDoubleField(value: &duration)
            default: break
            }
        }
    }

    func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
        if start != Idb_Point() {
            try visitor.visitSingularMessageField(value: start, fieldNumber: 1)
        }
        if end != Idb_Point() {
            try visitor.visitSingularMessageField(value: end, fieldNumber: 2)
        }
        if delta != 0 { try visitor.visitSingularDoubleField(value: delta, fieldNumber: 5) }
        if duration != 0 { try visitor.visitSingularDoubleField(value: duration, fieldNumber: 6) }
        try unknownFields.traverse(visitor: &visitor)
    }

    static func == (lhs: Idb_HIDEvent.HIDSwipe, rhs: Idb_HIDEvent.HIDSwipe) -> Bool {
        lhs.start == rhs.start && lhs.end == rhs.end &&
        lhs.delta == rhs.delta && lhs.duration == rhs.duration
    }
}

// MARK: HIDDelay

extension Idb_HIDEvent.HIDDelay: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
    static let protoMessageName: String = "HIDEvent.HIDDelay"
    static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
        1: .same(proto: "duration")
    ]

    mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
        while let fieldNum = try decoder.nextFieldNumber() {
            switch fieldNum {
            case 1: try decoder.decodeSingularDoubleField(value: &duration)
            default: break
            }
        }
    }

    func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
        if duration != 0 { try visitor.visitSingularDoubleField(value: duration, fieldNumber: 1) }
        try unknownFields.traverse(visitor: &visitor)
    }

    static func == (lhs: Idb_HIDEvent.HIDDelay, rhs: Idb_HIDEvent.HIDDelay) -> Bool {
        lhs.duration == rhs.duration
    }
}

// MARK: HIDEvent

extension Idb_HIDEvent: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
    static let protoMessageName: String = "HIDEvent"
    static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
        1: .same(proto: "press"),
        2: .same(proto: "swipe"),
        3: .same(proto: "delay")
    ]

    mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
        while let fieldNum = try decoder.nextFieldNumber() {
            switch fieldNum {
            case 1:
                var v: HIDPress? = nil
                try decoder.decodeSingularMessageField(value: &v)
                if let v { event = .press(v) }
            case 2:
                var v: HIDSwipe? = nil
                try decoder.decodeSingularMessageField(value: &v)
                if let v { event = .swipe(v) }
            case 3:
                var v: HIDDelay? = nil
                try decoder.decodeSingularMessageField(value: &v)
                if let v { event = .delay(v) }
            default: break
            }
        }
    }

    func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
        switch event {
        case .press(let v)?:
            try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
        case .swipe(let v)?:
            try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
        case .delay(let v)?:
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

// MARK: - AccessibilityInfoRequest
//
// Real proto structure (verified from serialized descriptor in idb_pb2.py):
//
//   message AccessibilityInfoRequest {
//     Point point = 2;                          // query element at a point
//     Format format = 3;                        // LEGACY=0, NESTED=1
//     enum Format { LEGACY = 0; NESTED = 1; }
//   }

struct Idb_AccessibilityInfoRequest {
    enum Format: SwiftProtobuf.Enum {
        typealias RawValue = Int
        case legacy // = 0
        case nested // = 1
        case UNRECOGNIZED(Int)

        init() { self = .legacy }
        init?(rawValue: Int) {
            switch rawValue {
            case 0: self = .legacy
            case 1: self = .nested
            default: self = .UNRECOGNIZED(rawValue)
            }
        }
        var rawValue: Int {
            switch self {
            case .legacy:              return 0
            case .nested:              return 1
            case .UNRECOGNIZED(let v): return v
            }
        }
    }

    var point: Idb_Point? = nil  // field 2
    var format: Format = .legacy  // field 3
    var unknownFields = SwiftProtobuf.UnknownStorage()

    init() {}
}

extension Idb_AccessibilityInfoRequest.Format: SwiftProtobuf._ProtoNameProviding {
    static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
        0: .same(proto: "LEGACY"),
        1: .same(proto: "NESTED")
    ]
}

extension Idb_AccessibilityInfoRequest: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
    static let protoMessageName: String = "AccessibilityInfoRequest"
    static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
        2: .same(proto: "point"),
        3: .same(proto: "format")
    ]

    mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
        while let fieldNum = try decoder.nextFieldNumber() {
            switch fieldNum {
            case 2:
                var v: Idb_Point? = nil
                try decoder.decodeSingularMessageField(value: &v)
                point = v
            case 3: try decoder.decodeSingularEnumField(value: &format)
            default: break
            }
        }
    }

    func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
        if let point { try visitor.visitSingularMessageField(value: point, fieldNumber: 2) }
        if format != .legacy { try visitor.visitSingularEnumField(value: format, fieldNumber: 3) }
        try unknownFields.traverse(visitor: &visitor)
    }

    static func == (lhs: Idb_AccessibilityInfoRequest, rhs: Idb_AccessibilityInfoRequest) -> Bool {
        lhs.point == rhs.point && lhs.format == rhs.format
    }
}

// MARK: - AccessibilityInfoResponse

struct Idb_AccessibilityInfoResponse {
    var json: String = ""
    var unknownFields = SwiftProtobuf.UnknownStorage()

    init() {}
}

extension Idb_AccessibilityInfoResponse: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
    static let protoMessageName: String = "AccessibilityInfoResponse"
    static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
        1: .same(proto: "json")
    ]

    mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
        while let fieldNum = try decoder.nextFieldNumber() {
            switch fieldNum {
            case 1: try decoder.decodeSingularStringField(value: &json)
            default: break
            }
        }
    }

    func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
        if !json.isEmpty { try visitor.visitSingularStringField(value: json, fieldNumber: 1) }
        try unknownFields.traverse(visitor: &visitor)
    }

    static func == (lhs: Idb_AccessibilityInfoResponse, rhs: Idb_AccessibilityInfoResponse) -> Bool {
        lhs.json == rhs.json
    }
}
