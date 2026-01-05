import SwiftUI

struct AppTheme {
    // Renk Tanımları
    static let stockColor = Color(red: 1.0, green: 0.5, blue: 0.0) // McLaren Turuncusu
    static let cryptoColor = Color(red: 0.0, green: 0.3, blue: 0.9) // Koyu Mavi
    static let fundColor = Color(red: 0.6, green: 0.3, blue: 0.3) // Vişne Çürüğü
    static let elementColor = Color(red: 0.85, green: 0.65, blue: 0.13) // Koyu Sarı (Element)
    static let cashColor = Color(red: 0.1, green: 0.6, blue: 0.3)
    
    // Kategoriye göre renk getiren fonksiyon
    static func color(for category: CategoryType) -> Color {
        switch category {
        case .stock: return stockColor
        case .crypto: return cryptoColor
        case .fund: return fundColor
        case .element: return elementColor
        case .cash: return cashColor
        }
    }
}

// Kategorileri ayırt etmek için enum
enum CategoryType {
    case stock, crypto, fund, element, cash
}

// Para Birimleri
enum Currency: String, CaseIterable {
    case tryCurrency = "₺"
    case usd = "$"
    case eur = "€"
}


