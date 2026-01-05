import Foundation
import SwiftData

@Model
class Cash {
    var id: UUID
    var symbol: String // "TRY", "USD", "EUR"
    var quantity: Double // Miktar
    var currentPrice: Double // O anki kur (TRY için 1.0)
    
    var totalValue: Double {
        return quantity * currentPrice
    }
    
    init(symbol: String, quantity: Double, currentPrice: Double = 1.0) {
        self.id = UUID()
        self.symbol = symbol
        self.quantity = quantity
        self.currentPrice = currentPrice
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
