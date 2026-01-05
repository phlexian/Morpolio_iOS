import Foundation

class CurrencyService {
    
    func fetchRates() async -> (usd: Double, eur: Double)? {
        async let usdRate = fetchGoogleRate(urlStr: "https://www.google.com/finance/quote/USD-TRY")
        async let eurRate = fetchGoogleRate(urlStr: "https://www.google.com/finance/quote/EUR-TRY")
        
        let rates = await (usd: usdRate, eur: eurRate)
        if let usd = rates.usd, let eur = rates.eur {
            return (usd, eur)
        }
        return nil
    }
    
    private func fetchGoogleRate(urlStr: String) async -> Double? {
        guard let url = URL(string: urlStr) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let html = String(data: data, encoding: .utf8) {
                return parseGoogleFinanceHTML(html)
            }
        } catch { return nil }
        return nil
    }
    
    private func parseGoogleFinanceHTML(_ html: String) -> Double? {
        // Class isimleri değişebileceği için daha geniş bir Regex kullanıyoruz.
        // "USD to TRY" gibi bir bağlamdan ziyade, Google Finans'taki büyük rakamı yakalayan güncel class.
        // "YMlKec fxKbKc" şu anki class, ancak değişirse diye yedeğe de bakabiliriz.
        let pattern = "class=\"YMlKec fxKbKc\">([0-9,.]+)"
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let nsString = html as NSString
            let results = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
            
            if let match = results.first {
                let priceString = nsString.substring(with: match.range(at: 1))
                // Virgülü noktaya çevir ve Double yap (Yuvarlama YAPMADAN)
                let formattedString = priceString.replacingOccurrences(of: ",", with: ".")
                return Double(formattedString)
            }
        }
        return nil
    }
}
