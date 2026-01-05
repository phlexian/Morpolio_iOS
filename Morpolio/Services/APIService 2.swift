/*import Foundation

class APIService {
    
    // MARK: - Crypto API (CoinMarketCap)
    private let cryptoApiKey = "6076ba17-5122-44da-aa2c-52f4847d2df7"
    
    func fetchCryptoPrice(symbol: String) async -> Double? {
        let cleanSymbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        let urlString = "https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest?symbol=\(cleanSymbol)&convert=TRY"
        
        guard let url = URL(string: urlString) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(cryptoApiKey, forHTTPHeaderField: "X-CMC_PRO_API_KEY")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return nil }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let dataDict = json["data"] as? [String: Any],
               let symbolDict = dataDict[cleanSymbol] as? [String: Any],
               let quoteDict = symbolDict["quote"] as? [String: Any],
               let tryDict = quoteDict["TRY"] as? [String: Any],
               let price = tryDict["price"] as? Double {
                return price
            }
        } catch { print("Crypto Error: \(error)") }
        return nil
    }
    
    // MARK: - Stock API
    func fetchStockPrice(symbol: String) async -> Double? {
        var formattedSymbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if !formattedSymbol.hasSuffix(".IS") { formattedSymbol += ".IS" }
        return await fetchPriceFromBackend(symbol: formattedSymbol)
    }
    
    // MARK: - Fund API
    func fetchFundPrice(symbol: String) async -> Double? {
        let cleanSymbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return await fetchPriceFromBackend(symbol: cleanSymbol)
    }
    
    // MARK: - Element API (Fiyat Düzeltmesi)
    func fetchElementPrice(symbol: String) async -> Double? {
        // Backend'e sorarken doğru sembolü kullanmamız lazım.
        // GLD (ETF) yerine GC=F (Ons Altın) sormalıyız.
        var searchSymbol = symbol
        
        switch symbol {
        case "GLD": searchSymbol = "GC=F" // Ons Altın Sembolü
        case "SLV": searchSymbol = "SI=F" // Ons Gümüş Sembolü
        case "PLT": searchSymbol = "PL=F" // Ons Platin Sembolü
        default: searchSymbol = symbol
        }
        
        // 1. Backend'den Gerçek ONS ($) fiyatını çek
        guard let ouncePriceUsd = await fetchPriceFromBackend(symbol: searchSymbol) else { return nil }
        
        // 2. Dolar/TL kurunu çek
        guard let usdTryRate = await fetchUSDRate() else { return nil }
        
        // 3. Hesaplama: (Ons Fiyatı / 31.1035) * Dolar Kuru
        let gramPriceTL = (ouncePriceUsd / 31.1034768) * usdTryRate
        
        return gramPriceTL
    }
    
    // --- Yardımcılar ---
    
    private func fetchPriceFromBackend(symbol: String) async -> Double? {
        // Backend URL'niz (Sembolü URL encode ediyoruz çünkü = gibi karakterler olabilir)
        let encodedSymbol = symbol.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? symbol
        let urlString = "https://morpolio-backend-317318908068.europe-west1.run.app/price-direct?symbol=\(encodedSymbol)"
        
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, response) = try await URLSession.shared.data(for: URLRequest(url: url))
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return nil }
            struct APIResp: Codable { let price: Double }
            let decoded = try JSONDecoder().decode(APIResp.self, from: data)
            return decoded.price
        } catch { return nil }
    }
    
    private func fetchUSDRate() async -> Double? {
        guard let url = URL(string: "https://www.google.com/finance/quote/USD-TRY") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let html = String(data: data, encoding: .utf8) {
                let pattern = "class=\"YMlKec fxKbKc\">([0-9,.]+)"
                if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                    let nsString = html as NSString
                    let results = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
                    if let match = results.first {
                        let priceString = nsString.substring(with: match.range(at: 1))
                        let formattedString = priceString.replacingOccurrences(of: ",", with: ".")
                        return Double(formattedString)
                    }
                }
            }
        } catch { return nil }
        return nil
    }
 }*/
