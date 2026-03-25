import Foundation

enum Output {
    static func success(_ data: Any, pretty: Bool = false) -> Never {
        let jsonString = json(data, pretty: pretty)
        print(jsonString)
        exit(0)
    }

    static func error(
        code: String,
        message: String,
        suggestion: String? = nil,
        exitCode: Int32 = 1
    ) -> Never {
        var payload: [String: Any] = [
            "status": "error",
            "code": code,
            "message": message
        ]
        if let suggestion = suggestion {
            payload["suggestion"] = suggestion
        }
        let jsonString = json(payload, pretty: false)
        print(jsonString)
        exit(exitCode)
    }

    static func json(_ value: Any, pretty: Bool) -> String {
        let options: JSONSerialization.WritingOptions = pretty ? [.prettyPrinted, .sortedKeys] : []
        guard let data = try? JSONSerialization.data(withJSONObject: value, options: options),
              let string = String(data: data, encoding: .utf8) else {
            return "{\"status\":\"error\",\"code\":\"SERIALIZATION_ERROR\",\"message\":\"Failed to serialize output to JSON\"}"
        }
        return string
    }
}
