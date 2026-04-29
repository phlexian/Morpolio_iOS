import Foundation
import SwiftData

@Model
class Crypto {
    var id: UUID
    var symbol: String
    var quantity: Double
    var currentPrice: Double
    var purchasePrice: Double // TL cinsinden maliyet (Genel kar/zarar hesabı için)
    
    // YENİ ALANLAR: Orijinal Girilen Fiyat ve Döviz Cinsi
    var originalPurchasePrice: Double
    var purchaseCurrency: String
    
    var totalValue: Double {
        return quantity * currentPrice
    }
    
    var profitLossAmount: Double {
        return (currentPrice - purchasePrice) * quantity
    }
    
    var profitLossPercentage: Double {
        guard purchasePrice > 0 else { return 0.0 }
        return ((currentPrice - purchasePrice) / purchasePrice) * 100
    }
    
    init(symbol: String, quantity: Double, currentPrice: Double = 0.0, purchasePrice: Double = 0.0, originalPurchasePrice: Double = 0.0, purchaseCurrency: String = "₺") {
        self.id = UUID()
        self.symbol = symbol
        self.quantity = quantity
        self.currentPrice = currentPrice
        self.purchasePrice = purchasePrice
        // Orijinal fiyat girilmediyse, standart fiyatı baz al
        self.originalPurchasePrice = originalPurchasePrice == 0.0 ? purchasePrice : originalPurchasePrice
        self.purchaseCurrency = purchaseCurrency
    }
}
