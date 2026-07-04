import ApplicationServices
import AppKit

// Focus-free prompt injection into Cursor's Composer via the macOS
// Accessibility API. Unlike keystroke injection, this never steals
// focus or the clipboard: it writes AXValue on the Composer textarea
// and performs AXPress on the Send button, all scoped to the Cursor
// process.
//
// Usage: cursor-compose-ax [--new] <prompt-file>

func fail(_ msg: String) -> Never {
    FileHandle.standardError.write((msg + "\n").data(using: .utf8)!)
    exit(1)
}

var newChat = false
var promptPath: String? = nil
for arg in CommandLine.arguments.dropFirst() {
    if arg == "--new" { newChat = true } else { promptPath = arg }
}
guard let path = promptPath,
      let prompt = try? String(contentsOfFile: path, encoding: .utf8),
      !prompt.isEmpty else {
    fail("usage: cursor-compose-ax [--new] <prompt-file>")
}

guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == "Cursor" }) else {
    fail("cursor-compose-ax: Cursor is not running")
}
let axApp = AXUIElementCreateApplication(app.processIdentifier)
// Electron exposes its AX tree lazily; this forces it on.
AXUIElementSetAttributeValue(axApp, "AXManualAccessibility" as CFString, kCFBooleanTrue)
Thread.sleep(forTimeInterval: 1.0)

func attr(_ el: AXUIElement, _ name: String) -> AnyObject? {
    var v: AnyObject?
    AXUIElementCopyAttributeValue(el, name as CFString, &v)
    return v
}

func find(_ el: AXUIElement, _ depth: Int, _ pred: (AXUIElement, String) -> Bool) -> AXUIElement? {
    if depth > 50 { return nil }
    let role = attr(el, kAXRoleAttribute as String) as? String ?? ""
    if pred(el, role) { return el }
    guard let children = attr(el, kAXChildrenAttribute as String) as? [AXUIElement] else { return nil }
    for c in children {
        if let hit = find(c, depth + 1, pred) { return hit }
    }
    return nil
}

func findButton(_ desc: String) -> AXUIElement? {
    find(axApp, 0) { el, role in
        guard role == "AXButton" else { return false }
        let d = attr(el, kAXDescriptionAttribute as String) as? String ?? ""
        let t = attr(el, kAXTitleAttribute as String) as? String ?? ""
        return d.contains(desc) || t.contains(desc)
    }
}

if newChat {
    guard let btn = findButton("New Agent") else {
        fail("cursor-compose-ax: 'New Agent' button not found (is the Composer pane open?)")
    }
    guard AXUIElementPerformAction(btn, kAXPressAction as CFString) == .success else {
        fail("cursor-compose-ax: failed to press 'New Agent'")
    }
    Thread.sleep(forTimeInterval: 1.0)
}

guard let ta = find(axApp, 0, { _, role in role == "AXTextArea" }) else {
    fail("cursor-compose-ax: Composer textarea not found (is the Composer pane open?)")
}
guard AXUIElementSetAttributeValue(ta, kAXValueAttribute as CFString, prompt as CFString) == .success else {
    fail("cursor-compose-ax: failed to set prompt text")
}
Thread.sleep(forTimeInterval: 0.5)

// The Send button only materializes once the textarea has content.
guard let send = findButton("Send message") else {
    fail("cursor-compose-ax: 'Send message' button not found after setting text")
}
guard AXUIElementPerformAction(send, kAXPressAction as CFString) == .success else {
    fail("cursor-compose-ax: failed to press 'Send message'")
}
print("cursor-compose-ax: prompt sent")
