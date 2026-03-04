import Foundation

func randomString(length: Int) -> String {
  let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  return String((0..<length).map { _ in letters.randomElement()! })
}

func fileNameFromCurrentDate() -> String {
    let dateFormatter = DateFormatter()
    let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
    dateFormatter.locale = enUSPosixLocale
    dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss-SSS-z"
    dateFormatter.calendar = Calendar(identifier: .gregorian)
    return dateFormatter.string(from: Date())
}

func isValidDomainName(_ name: String) -> Bool {
    // trim slaces, spaces, tabs, new lines
    let range = NSRange(location: 0, length: name.utf16.count)
    let regex = try! NSRegularExpression(pattern: "^((?!-)[A-Za-z0-9-]{1,63}(?<!-)\\.)+[A-Za-z]{2,6}$")
    return regex.firstMatch(in: name, options: [], range: range) != nil
}
