struct NativeNotify: Codable {
    let id: Int
    let text: String
    let title: String?
    let icon: String?
    let smallIcon: String?
    let priority: Int?
    let actions: [NativeNotifyAction]?
}
