import SwiftUI

extension String {
    // Sayıları otomatik olarak binlik (virgül) ve ondalık (nokta) formatına çevirir
    func formatNumber() -> String {
        // 1. İşleme başlamadan önce metindeki binlik ayırıcıları (virgülleri) temizle
        var cleaned = self.replacingOccurrences(of: ",", with: "")
        
        // 2. Sadece rakamlara ve ondalık ayırıcı olan noktaya izin ver
        let validChars = Set("0123456789.")
        cleaned = cleaned.filter { validChars.contains($0) }
        
        // 3. Metni noktadan (ondalık ayırıcıdan) böl
        let parts = cleaned.components(separatedBy: ".")
        let wholePart = parts[0]
        
        // Tam sayı kısmı yoksa veya dönüştürülemiyorsa işlemi durdur
        guard let wholeNumber = Int(wholePart) else {
            if cleaned == "." { return "0." }
            return ""
        }
        
        // 4. Formatter ayarları: Binlik için virgül (,), Ondalık için nokta (.)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.decimalSeparator = "."
        formatter.locale = Locale(identifier: "en_US")
        
        // Tam sayı kısmını binlik formatına çevir
        let formattedWhole = formatter.string(from: NSNumber(value: wholeNumber)) ?? wholePart
        
        // 5. Ondalık kısım varsa formatlanmış tam sayı ile birleştir
        if parts.count > 1 {
            return formattedWhole + "." + parts[1]
        } else if cleaned.hasSuffix(".") {
            return formattedWhole + "."
        } else {
            return formattedWhole
        }
    }
    
    // Formatlanmış metni matematiksel işlemler için güvenle Double'a çevirir
    func toDouble() -> Double {
        // Sadece binlik ayırıcıları (virgül) kaldırıyoruz. Nokta (.) ondalık ayırıcı olarak kalıyor.
        let stripped = self.replacingOccurrences(of: ",", with: "")
        return Double(stripped) ?? 0.0
    }
}

extension View {
    // Klavyeyi kapatan fonksiyon
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Double Formatlama Eklentisi
extension Double {
    // Double değerleri binlik ayırıcı ile formatlar (Örn: 3,688,063.50)
    func formattedWithSeparator(fractionDigits: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.decimalSeparator = "."
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
