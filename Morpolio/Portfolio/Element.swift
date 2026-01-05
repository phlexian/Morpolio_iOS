import Foundation
import SwiftData

@Model
class Element {
    var id: UUID
    var symbol: String // "GLD", "SLV", "PLT" gibi kodlar tutacak
    var quantity: Double // Gram cinsinden
    var currentPrice: Double
    
    var totalValue: Double {
        return quantity * currentPrice
    }
    
    init(symbol: String, quantity: Double, currentPrice: Double = 0.0) {
        self.id = UUID()
        self.symbol = symbol
        self.quantity = quantity
        self.currentPrice = currentPrice
    }
    
    // Ekranda göstermek için yardımcı özellik
    var displayName: String {
        switch symbol {
        case "GLD": return "Altın (Gr)"
        case "SLV": return "Gümüş (Gr)"
        case "PLT": return "Platin (Gr)"
        default: return symbol
        }
    }
}
