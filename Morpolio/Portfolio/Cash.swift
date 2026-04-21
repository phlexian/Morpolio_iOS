import Foundation
import SwiftData

@Model
class Cash {
    var id: UUID
    var symbol: String // "TRY", "USD", "EUR"
    var quantity: Double // Miktar
    var currentPrice: Double // O anki kur (TRY için 1.0)
    var purchasePrice: Double // YENİ: Döviz alış kuru
    
    var totalValue: Double {
        return quantity * currentPrice
    }
    
    // YENİ: Döviz Kur Farkından Kar/Zarar Miktarı
    var profitLossAmount: Double {
        return (currentPrice - purchasePrice) * quantity
    }
    
    // YENİ: Döviz Kur Farkından Kar/Zarar Yüzdesi
    var profitLossPercentage: Double {
        guard purchasePrice > 0 else { return 0.0 }
        return ((currentPrice - purchasePrice) / purchasePrice) * 100
    }
    
    init(symbol: String, quantity: Double, currentPrice: Double = 1.0, purchasePrice: Double = 1.0) {
        self.id = UUID()
        self.symbol = symbol
        self.quantity = quantity
        self.currentPrice = currentPrice
        self.purchasePrice = purchasePrice
    }
    
    var displayName: String {
        switch symbol {
        case "TRY": return "Türk Lirası"
        case "USD": return "Amerikan Doları"
        case "EUR": return "Euro"
        default: return symbol
        }
    }
}
