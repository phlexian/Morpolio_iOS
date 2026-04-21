import Foundation
import SwiftData

@Model
class Crypto {
    var id: UUID
    var symbol: String
    var quantity: Double
    var currentPrice: Double
    var purchasePrice: Double // YENİ: Alış Fiyatı
    
    var totalValue: Double {
        return quantity * currentPrice
    }
    
    // YENİ: Kar/Zarar Miktarı
    var profitLossAmount: Double {
        return (currentPrice - purchasePrice) * quantity
    }
    
    // YENİ: Kar/Zarar Yüzdesi
    var profitLossPercentage: Double {
        guard purchasePrice > 0 else { return 0.0 }
        return ((currentPrice - purchasePrice) / purchasePrice) * 100
    }
    
    init(symbol: String, quantity: Double, currentPrice: Double = 0.0, purchasePrice: Double = 0.0) {
        self.id = UUID()
        self.symbol = symbol
        self.quantity = quantity
        self.currentPrice = currentPrice
        self.purchasePrice = purchasePrice
    }
}
