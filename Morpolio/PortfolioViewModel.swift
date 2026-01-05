import Foundation
import Observation

@Observable
class PortfolioViewModel {
    // Hisse Listesi
    var stocks: [Stock] = []
    
    // Kripto Listesi
    var cryptos: [Crypto] = []
    
    init() {
        // Örnek Veriler
        stocks.append(Stock(symbol: "ASELS", quantity: 100.0))
        stocks.append(Stock(symbol: "THYAO", quantity: 50.0))
        
        cryptos.append(Crypto(symbol: "BTC", quantity: 0.5))
        cryptos.append(Crypto(symbol: "ETH", quantity: 4.0))
    }
    
    // Hisse Ekle
    func addStock(symbol: String, quantity: Double) {
        let newStock = Stock(symbol: symbol, quantity: quantity)
        stocks.append(newStock)
    }
    
    // Kripto Ekle
    func addCrypto(symbol: String, quantity: Double) {
        let newCrypto = Crypto(symbol: symbol, quantity: quantity)
        cryptos.append(newCrypto)
    }
}
