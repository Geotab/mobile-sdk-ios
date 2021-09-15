

struct NativeNotifyAction: Codable {
    let id: String
    let title: String
    let type: String? // button or input
    let launch: Bool?
    let ui: String? // decline
}
