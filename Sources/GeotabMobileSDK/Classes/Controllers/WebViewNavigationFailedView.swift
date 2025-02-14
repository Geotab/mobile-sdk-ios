import UIKit
import WebKit

class WebViewNavigationFailedView: UIView {
    
    weak var webView: WKWebView?
    var reloadURL: URL?
    
    @IBOutlet public weak var imageLogo: UIImageView!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var tryAgainLabel: UILabel!
    @IBOutlet weak var noNetworkLabel: UILabel!
    @IBOutlet weak var errorInfoLabel: UILabel!

    func configureXib() {
        
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist") else { return }
        let url = URL(fileURLWithPath: path)
        
        do {
            let data = try Data(contentsOf: url)
            let plist = try PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) as? [String: Any]
                        
            if let imageName = plist?["NetworkErrorScreenIcon"] as? String {
                if let image = UIImage(named: imageName, in: Bundle.main, compatibleWith: nil) {
                    imageLogo.image = image
                }
            }
            if let fontColor =  plist?["NetworkErrorScreenFontColor"] as? String {
                if let validFontColor = UIColor(hexColor: fontColor) {
                    noNetworkLabel.textColor = validFontColor
                    tryAgainLabel.textColor = validFontColor
                    errorInfoLabel.textColor = validFontColor
                    refreshButton.setTitleColor(validFontColor, for: .normal)
                }
            }
            if let bckColor =  plist?["NetworkErrorScreenBckColor"] as? String {
                if let validBckColor = UIColor(hexColor: bckColor) {
                    backgroundColor = validBckColor
                    refreshButton.backgroundColor = validBckColor
                }
            }
            
        } catch {
            print("failed to decode parameters from Info.plist with error: \(error)")
        }

    }
    
    @IBAction func onRefresh(_ sender: Any) {
        
        if webView?.url != nil {
            webView?.reload()
            self.isHidden = true
        } else if let url = reloadURL {
            webView?.load(URLRequest(url: url))
            self.isHidden = true
        } else {
            self.isHidden = false
        }
    }
    
}

extension UIColor {

    convenience init?(hexColor: String) {
        var hexString = hexColor

        if hexString.hasPrefix("#") { // Remove the '#' prefix if added.
            let start = hexString.index(hexString.startIndex, offsetBy: 1)
            hexString = String(hexString[start...])
        }

        if hexString.lowercased().hasPrefix("0x") { // Remove the '0x' prefix if added.
            let start = hexString.index(hexString.startIndex, offsetBy: 2)
            hexString = String(hexString[start...])
        }

        let r, g, b, a: CGFloat
        let scanner = Scanner(string: hexString)
        var hexNumber: UInt64 = 0
        guard scanner.scanHexInt64(&hexNumber) else { return nil } // Make sure the strinng is a hex code.

        switch hexString.count {
        case 3, 4: // Color is in short hex format
            var updatedHexString = ""
            hexString.forEach { updatedHexString.append(String(repeating: String($0), count: 2)) }
            hexString = updatedHexString
            self.init(hexColor: hexString)

        case 6: // Color is in hex format without alpha.
            r = CGFloat((hexNumber & 0xFF0000) >> 16) / 255.0
            g = CGFloat((hexNumber & 0x00FF00) >> 8) / 255.0
            b = CGFloat(hexNumber & 0x0000FF) / 255.0
            a = 1.0
            self.init(red: r, green: g, blue: b, alpha: a)

        case 8: // Color is in hex format with alpha.
            r = CGFloat((hexNumber & 0xFF000000) >> 24) / 255.0
            g = CGFloat((hexNumber & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((hexNumber & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(hexNumber & 0x000000FF) / 255.0
            self.init(red: r, green: g, blue: b, alpha: a)

        default: // Invalid format.
            return nil
        }
    }

}
