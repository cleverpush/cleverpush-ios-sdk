import Foundation
import UIKit

extension UIColor {
    convenience init?(hex: String) {
        if !hex.hasPrefix("#") {
            return nil
        }
        
        let start = hex.index(hex.startIndex, offsetBy: 1)
        let hexColor = String(hex[start...])
        let scanner = Scanner(string: hexColor)
        var hexNumber: UInt64 = 0
        
        if(![3, 6, 8].contains(hexColor.count)) {
            return nil
        }
        
        if(!scanner.scanHexInt64(&hexNumber)) {
            return nil
        }
        
        switch hexColor.count {
        case 8:
            self.init(
                red: UIColor.readColor(hexNumber, 3),
                green: UIColor.readColor(hexNumber, 2),
                blue: UIColor.readColor(hexNumber, 1),
                alpha: UIColor.readColor(hexNumber, 0)
            )
        case 6:
            self.init(
                red: UIColor.readColor(hexNumber, 2),
                green: UIColor.readColor(hexNumber, 1),
                blue: UIColor.readColor(hexNumber, 0),
                alpha: 1.0
            )
        case 3:
            self.init(
                red: UIColor.readNibleColor(hexNumber, 2),
                green: UIColor.readNibleColor(hexNumber, 1),
                blue: UIColor.readNibleColor(hexNumber, 0),
                alpha: 1.0
            )
        default:
            return nil
        }
    }
    
    private static func readColor(_ value: UInt64, _ pos: Int) -> CGFloat {
        let bits: UInt64 = (1 << 3) * UInt64(pos)
        let mask: UInt64 = 0xff << bits
        
        return CGFloat((value & mask) >> bits) / 255.0
    }
    
    private static func readNibleColor(_ value: UInt64, _ pos: Int) -> CGFloat {
        let bits = (1 << 2) * pos
        let mask: UInt64 = 0xf << bits
        
        return CGFloat((value & mask) >> bits) / 255.0
    }
}
