import ApplicationServices
import AppKit

// Reports whether Cursor's Composer agent is currently generating.
// Detection: while generating, Composer shows a stop/cancel control
// and the send button is absent; when idle the input area shows the
// mic ("Start voice input") / send affordances only.
//
// Output: "busy" (exit 0) or "idle" (exit 1). Errors exit 2.
// Usage: cursor-compose-status [--wait [timeout-seconds]]
//   --wait polls every 5s until idle (or timeout, default 1800s).

func fail(_ msg: String) -> Never {
    FileHandle.standardError.write((msg + "\n").data(using: .utf8)!)
    exit(2)
}

func attr(_ el: AXUIElement, _ name: String) -> AnyObject? {
    var v: AnyObject?
    AXUIElementCopyAttributeValue(el, name as CFString, &v)
    return v
}

func findBusyMarker(_ el: AXUIElement, _ depth: Int) -> Bool {
    if depth > 50 { return false }
    let role = attr(el, kAXRoleAttribute as String) as? String ?? ""
    if role == "AXButton" {
        let d = (attr(el, kAXDescriptionAttribute as String) as? String ?? "").lowercased()
        let t = (attr(el, kAXTitleAttribute as String) as? String ?? "").lowercased()
        for needle in ["stop generation", "stop generating", "stop agent", "cancel generation"] {
            if d.contains(needle) || t.contains(needle) { return true }
        }
        // Composer's inline stop control is a bare "Stop" button.
        if d == "stop" || t == "stop" { return true }
    }
    guard let children = attr(el, kAXChildrenAttribute as String) as? [AXUIElement] else { return false }
    for c in children {
        if findBusyMarker(c, depth + 1) { return true }
    }
    return false
}

var wait = false
var timeout: Double = 1800
var args = Array(CommandLine.arguments.dropFirst())
while let a = args.first {
    args.removeFirst()
    if a == "--wait" {
        wait = true
        if let next = args.first, let t = Double(next) { timeout = t; args.removeFirst() }
    } else {
        fail("usage: cursor-compose-status [--wait [timeout-seconds]]")
    }
}

guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == "Cursor" }) else {
    fail("cursor-compose-status: Cursor is not running")
}
let axApp = AXUIElementCreateApplication(app.processIdentifier)
AXUIElementSetAttributeValue(axApp, "AXManualAccessibility" as CFString, kCFBooleanTrue)
Thread.sleep(forTimeInterval: 1.0)

func check() -> Bool { findBusyMarker(axApp, 0) }

if !wait {
    if check() { print("busy"); exit(0) } else { print("idle"); exit(1) }
}

let deadline = Date().addingTimeInterval(timeout)
// Require 2 consecutive idle reads so a brief tool-call gap between
// generation chunks is not mistaken for completion.
var idleStreak = 0
while Date() < deadline {
    if check() {
        idleStreak = 0
    } else {
        idleStreak += 1
        if idleStreak >= 2 { print("idle"); exit(1) }
    }
    Thread.sleep(forTimeInterval: 5.0)
}
print("timeout")
exit(3)
