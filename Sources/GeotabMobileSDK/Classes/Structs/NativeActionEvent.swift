

struct NativeActionEvent: Codable {
    let event: String
    let foreground: Bool
    let notification: Int
    let queued: Bool
}
