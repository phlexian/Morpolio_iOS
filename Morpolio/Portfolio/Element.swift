import Foundation
import SwiftData

@Model
class Element {
    var id: UUID
    var symbol: String // "GLD", "SLV", "PLT" gibi kodlar tutacak
    var quantity: Double // Gram cinsinden
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
    
    var displayName: String {
        switch symbol {
        case "GLD": return "Altın (Gr)"
        case "SLV": return "Gümüş (Gr)"
        case "PLT": return "Platin (Gr)"
        default: return symbol
        }
    }
}
