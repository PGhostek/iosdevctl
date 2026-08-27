import XCTest
@testable import iosdevctl

/// Unit tests for AccessibilityTree.filter — the shared filter behind
/// `ui tree --query/--type` and `agent context --query/--type`.
///
/// These run in-process against a synthetic idb_companion-shaped tree
/// (no simulator, no idb_companion), and pin the contract that a filtered
/// result is a FLAT list of matching elements: each entry carries no
/// `children` subtree, so a matching descendant appears exactly once
/// rather than both nested inside its ancestor and again as its own entry.
final class AccessibilityTreeFilterTests: XCTestCase {

    // A login screen: the "Sign in" button wraps a "Sign in" static text,
    // which is exactly the shape that used to duplicate.
    private func loginTree() -> [String: Any] {
        return [
            "type": "Window",
            "AXLabel": "",
            "frame": ["x": 0.0, "y": 0.0, "width": 390.0, "height": 844.0],
            "children": [
                [
                    "type": "Button",
                    "AXLabel": "Sign in",
                    "AXUniqueId": "signInButton",
                    "frame": ["x": 20.0, "y": 400.0, "width": 350.0, "height": 44.0],
                    "children": [
                        [
                            "type": "StaticText",
                            "AXLabel": "Sign in",
                            "frame": ["x": 150.0, "y": 410.0, "width": 90.0, "height": 24.0]
                        ]
                    ]
                ],
                [
                    "type": "TextField",
                    "AXLabel": "Email",
                    "AXValue": "petr@example.com",
                    "frame": ["x": 20.0, "y": 300.0, "width": 350.0, "height": 44.0]
                ]
            ]
        ]
    }

    private func labels(_ results: [[String: Any]]) -> [String] {
        results.map { ($0["AXLabel"] as? String) ?? "" }
    }

    // MARK: - The bug: nested matches were returned twice

    func test_nestedMatches_appearExactlyOnce() {
        let results = AccessibilityTree.filter(loginTree(), query: "Sign in", type: nil)

        // Button + its StaticText child — two entries, not the button's whole
        // subtree plus a duplicate of the child.
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(labels(results), ["Sign in", "Sign in"])
        XCTAssertEqual(results.map { $0["type"] as? String }, ["Button", "StaticText"])
    }

    func test_matchedElement_doesNotCarryItsSubtree() {
        let results = AccessibilityTree.filter(loginTree(), query: "Sign in", type: nil)

        for element in results {
            XCTAssertNil(element["children"], "filtered elements must be flat, got a nested subtree")
        }
    }

    /// A container match must not smuggle the entire tree back through `children`.
    func test_containerTypeMatch_returnsContainerWithoutWholeTree() {
        let results = AccessibilityTree.filter(loginTree(), query: nil, type: "Window")

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0]["type"] as? String, "Window")
        XCTAssertNil(results[0]["children"])
    }

    // MARK: - Filtering semantics preserved

    func test_queryMatchesValueNotJustLabel() {
        let results = AccessibilityTree.filter(loginTree(), query: "petr@example.com", type: nil)
        XCTAssertEqual(labels(results), ["Email"])
    }

    func test_queryIsCaseInsensitive() {
        let results = AccessibilityTree.filter(loginTree(), query: "sIgN In", type: nil)
        XCTAssertEqual(results.count, 2)
    }

    func test_typeFilterNarrowsQueryMatches() {
        let results = AccessibilityTree.filter(loginTree(), query: "Sign in", type: "Button")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0]["AXUniqueId"] as? String, "signInButton")
    }

    func test_noMatch_returnsEmpty() {
        XCTAssertTrue(AccessibilityTree.filter(loginTree(), query: "Logout", type: nil).isEmpty)
    }

    func test_nilFilters_matchEveryNode() {
        let results = AccessibilityTree.filter(loginTree(), query: nil, type: nil)
        XCTAssertEqual(results.count, 4) // Window, Button, StaticText, TextField
    }

    func test_arrayRoot_isTraversed() {
        let tree = loginTree()
        let results = AccessibilityTree.filter([tree, tree] as [Any], query: "Email", type: nil)
        XCTAssertEqual(results.count, 2)
    }

    /// Frames must survive filtering — element-tap style consumers read them.
    func test_matchedElementKeepsItsFrame() {
        let results = AccessibilityTree.filter(loginTree(), query: "Email", type: nil)
        let frame = results.first?["frame"] as? [String: Any]
        XCTAssertEqual(frame?["y"] as? Double, 300.0)
    }
}
