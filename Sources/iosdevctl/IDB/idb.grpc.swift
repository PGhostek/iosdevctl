// DO NOT EDIT.
// Pre-generated from idb proto definitions — CompanionService HID subset only.
// Source: https://github.com/facebook/idb/blob/main/proto/idb.proto

import Foundation
import GRPC
import NIO
import SwiftProtobuf

// MARK: - CompanionService client protocol

/// Client-facing protocol for the idb CompanionService (HID subset).
protocol Idb_CompanionServiceClientProtocol: GRPCClient {
    var serviceName: String { get }
    var interceptors: Idb_CompanionServiceClientInterceptorFactoryProtocol? { get }

    func hid(
        callOptions: CallOptions?
    ) -> ClientStreamingCall<Idb_HIDEvent, Idb_HIDResponse>
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
}

// MARK: - Interceptor factory protocol

protocol Idb_CompanionServiceClientInterceptorFactoryProtocol: Sendable {
    func makeHidInterceptors() -> [ClientInterceptor<Idb_HIDEvent, Idb_HIDResponse>]
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
