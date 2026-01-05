import Foundation
import SwiftData

@Model
class Fund {
    var id: UUID
    var symbol: String
    var quantity: Double
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
}
