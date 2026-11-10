import UIKit

/// Lets the web app choose the color shown under the bottom safe area (the home indicator region), so it continues the
/// web app's own bottom bar. `null` hands the area back to the app's own appearance.
class SetBottomSafeAreaColorFunction: ModuleFunction {
    static let functionName: String = "setBottomSafeAreaColor"

    private let onColorChange: (UIColor?) -> Void

    init(module: AppModule, onColorChange: @escaping (UIColor?) -> Void) {
        self.onColorChange = onColorChange
        super.init(module: module, name: Self.functionName)
    }

    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, any Error>) -> Void) {
        switch argument {
        // The bridge sends JSON. null arrives as NSNull, and so do NaN and Infinity, which JSON turns into null.
        // undefined, a function and a symbol are left out of the message, so they arrive as nil. All of them hand the area back.
        case nil, is NSNull:
            onColorChange(nil)
        case let hexColor as String:
            guard let color = UIColor(strictHexColor: hexColor) else {
                jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
                return
            }
            onColorChange(color)
        default:
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
            return
        }
        jsCallback(Result.success("undefined"))
    }
}

extension UIColor {

    /// Reads exactly `#RRGGBB`. Anything else, including shorthand, alpha, color names and surrounding whitespace,
    /// returns nil: the app paints this color on screen, so a value it cannot read exactly must not be guessed at.
    convenience init?(strictHexColor string: String) {
        let characters = Array(string.utf8)
        guard characters.count == 7, characters[0] == UInt8(ascii: "#") else { return nil }

        var value: UInt32 = 0
        for character in characters.dropFirst() {
            guard let digit = Self.hexDigitValue(of: character) else { return nil }
            value = value << 4 | digit
        }

        self.init(red: CGFloat((value >> 16) & 0xFF) / 255,
                  green: CGFloat((value >> 8) & 0xFF) / 255,
                  blue: CGFloat(value & 0xFF) / 255,
                  alpha: 1)
    }

    private static func hexDigitValue(of character: UInt8) -> UInt32? {
        switch character {
        case UInt8(ascii: "0")...UInt8(ascii: "9"): UInt32(character - UInt8(ascii: "0"))
        case UInt8(ascii: "a")...UInt8(ascii: "f"): UInt32(character - UInt8(ascii: "a")) + 10
        case UInt8(ascii: "A")...UInt8(ascii: "F"): UInt32(character - UInt8(ascii: "A")) + 10
        default: nil
        }
    }
}
