import Foundation

/// Filtering over the raw accessibility tree returned by idb_companion.
///
/// Shared by `ui tree` and `agent context`, which previously carried two
/// verbatim copies of this walk.
enum AccessibilityTree {

    /// Collect every node matching `query` (label or value substring) and
    /// `type` (element-type substring), both case-insensitive. A nil filter
    /// matches everything.
    ///
    /// The result is a FLAT list: each matched element is returned WITHOUT its
    /// `children`. Keeping them made the filter self-defeating — a matched node
    /// was emitted with its whole subtree attached AND every matching descendant
    /// was emitted again as its own entry, so `--query "Sign in"` returned the
    /// button and, nested inside it, the same static text it also listed next to
    /// the button. A container match (`--type Window`) dragged the entire tree
    /// back through `children`, i.e. exactly the payload the filter exists to
    /// avoid — and these are the payloads that go straight into an agent's
    /// context window.
    static func filter(_ node: Any, query: String?, type elementType: String?) -> [[String: Any]] {
        var results: [[String: Any]] = []

        func visit(_ obj: Any) {
            if let dict = obj as? [String: Any] {
                let label = (dict["AXLabel"] as? String) ?? ""
                let value = (dict["AXValue"] as? String) ?? ""
                let typeStr = (dict["type"] as? String) ?? ""

                let matchesQuery = query.map {
                    label.localizedCaseInsensitiveContains($0) || value.localizedCaseInsensitiveContains($0)
                } ?? true
                let matchesType = elementType.map { typeStr.localizedCaseInsensitiveContains($0) } ?? true

                if matchesQuery && matchesType {
                    var flat = dict
                    flat.removeValue(forKey: "children")
                    results.append(flat)
                }

                if let children = dict["children"] as? [Any] {
                    for child in children { visit(child) }
                }
            } else if let arr = obj as? [Any] {
                for item in arr { visit(item) }
            }
        }

        visit(node)
        return results
    }
}
