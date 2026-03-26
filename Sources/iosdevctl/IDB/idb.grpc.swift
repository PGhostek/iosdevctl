// DO NOT EDIT.
// Pre-generated from idb proto definitions — CompanionService HID + Accessibility subset.
// Source: https://github.com/facebook/idb/blob/main/proto/idb.proto

import Foundation
import GRPC
import NIO
import SwiftProtobuf

// MARK: - CompanionService client protocol

/// Client-facing protocol for the idb CompanionService (HID + Accessibility subset).
protocol Idb_CompanionServiceClientProtocol: GRPCClient {
    var serviceName: String { get }
    var interceptors: Idb_CompanionServiceClientInterceptorFactoryProtocol? { get }

    func hid(
        callOptions: CallOptions?
    ) -> ClientStreamingCall<Idb_HIDEvent, Idb_HIDResponse>

    func accessibilityInfo(
        _ request: Idb_AccessibilityInfoRequest,
        callOptions: CallOptions?
    ) -> UnaryCall<Idb_AccessibilityInfoRequest, Idb_AccessibilityInfoResponse>
}

extension Idb_CompanionServiceClientProtocol {
    var serviceName: String { "idb.CompanionService" }

    /// Opens a client-streaming HID call.
    func hid(callOptions: CallOptions? = nil) -> ClientStreamingCall<Idb_HIDEvent, Idb_HIDResponse> {
        return makeClientStreamingCall(
            path: "/idb.CompanionService/hid",
            callOptions: callOptions ?? defaultCallOptions,
            interceptors: interceptors?.makeHidInterceptors() ?? []
        )
    }

    /// Queries the accessibility tree for the current screen (or element at a point).
    func accessibilityInfo(
        _ request: Idb_AccessibilityInfoRequest,
        callOptions: CallOptions? = nil
    ) -> UnaryCall<Idb_AccessibilityInfoRequest, Idb_AccessibilityInfoResponse> {
        return makeUnaryCall(
            path: "/idb.CompanionService/accessibility_info",
            request: request,
            callOptions: callOptions ?? defaultCallOptions,
            interceptors: interceptors?.makeAccessibilityInfoInterceptors() ?? []
        )
    }
}

// MARK: - Interceptor factory protocol

protocol Idb_CompanionServiceClientInterceptorFactoryProtocol: Sendable {
    func makeHidInterceptors() -> [ClientInterceptor<Idb_HIDEvent, Idb_HIDResponse>]
    func makeAccessibilityInfoInterceptors() -> [ClientInterceptor<Idb_AccessibilityInfoRequest, Idb_AccessibilityInfoResponse>]
}

// MARK: - Concrete client

final class Idb_CompanionServiceClient: Idb_CompanionServiceClientProtocol {
    let channel: GRPCChannel
    var defaultCallOptions: CallOptions
    var interceptors: Idb_CompanionServiceClientInterceptorFactoryProtocol?

    init(
        channel: GRPCChannel,
        defaultCallOptions: CallOptions = CallOptions(),
        interceptors: Idb_CompanionServiceClientInterceptorFactoryProtocol? = nil
    ) {
        self.channel = channel
        self.defaultCallOptions = defaultCallOptions
        self.interceptors = interceptors
    }
}
