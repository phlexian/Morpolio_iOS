import Foundation

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
            if let httpRes = response as? HTTPURLResponse, httpRes.statusCode != 200 { return nil }
            
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
    
    // MARK: - Stock API (Yahoo Finance)
    func fetchStockPrice(symbol: String) async -> Double? {
        var cleanSymbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if !cleanSymbol.hasSuffix(".IS") { cleanSymbol += ".IS" }
        return await fetchYahooPrice(symbol: cleanSymbol)
    }
    
    // MARK: - Fund API (Döviz.com Scraping - En Stabil Yöntem)
    func fetchFundPrice(symbol: String) async -> Double? {
        let cleanSymbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // 1. ÖNCELİK: Döviz.com (Hafta sonu dahil en hızlı ve stabil kaynak)
        if let price = await fetchFromDovizCom(symbol: cleanSymbol) {
            return price
        }
        
        // 2. YEDEK: TEFAS (Devlet sitesi, yavaş olabilir)
        if let price = await fetchFromTEFAS(symbol: cleanSymbol) {
            return price
        }
        
        return nil
    }
    
    // Döviz.com HTML Parser
    private func fetchFromDovizCom(symbol: String) async -> Double? {
        // URL Yapısı: https://borsa.doviz.com/fonlar/TTE
        let urlString = "https://borsa.doviz.com/fonlar/\(symbol)"
        guard let url = URL(string: urlString) else { return nil }
        
        var request = URLRequest(url: url)
        // Tarayıcı taklidi yapıyoruz
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let html = String(data: data, encoding: .utf8) {
                // Döviz.com'da fiyat, data-socket-key="FONKODU" olan elementin içindedir.
                // Örnek: <div class="..." data-socket-key="TTE" ...>45,1234</div>
                
                let searchKey = "data-socket-key=\"\(symbol)\""
                
                if let keyRange = html.range(of: searchKey) {
                    // Anahtarı bulduktan sonraki kısmı al
                    let substring = html[keyRange.upperBound...]
                    
                    // İlk ">" (tag kapanışı) ile ilk "<" (div kapanışı) arasını al
                    if let startTag = substring.range(of: ">"),
                       let endTag = substring.range(of: "<") {
                        
                        let priceString = String(substring[startTag.upperBound..<endTag.lowerBound])
                        // Temizle: Boşlukları at, virgülü noktaya çevir
                        let cleanPrice = priceString
                            .replacingOccurrences(of: ",", with: ".")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if let value = Double(cleanPrice) {
                            return value
                        }
                    }
                }
            }
        } catch { print("Doviz.com Hatası: \(error)") }
        return nil
    }
    
    // TEFAS HTML Parser (Yedek)
    private func fetchFromTEFAS(symbol: String) async -> Double? {
        let urlString = "https://www.tefas.gov.tr/FonAnaliz.aspx?FonKod=\(symbol)"
        guard let url = URL(string: urlString) else { return nil }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let html = String(data: data, encoding: .utf8) {
                // "Son Fiyat" kelimesini bul
                if let keywordRange = html.range(of: "Son Fiyat") {
                    let substring = html[keywordRange.upperBound...]
                    
                    // Son Fiyat'tan sonra gelen ilk rakam grubunu yakala (örn: <span>12,3456</span>)
                    // Regex: taglerin arasindaki sayi
                    let pattern = ">([0-9,.]+)<"
                    if let regex = try? NSRegularExpression(pattern: pattern) {
                        let nsString = substring as NSString
                        // İlk eşleşen muhtemelen fiyattır
                        if let match = regex.firstMatch(in: String(substring), range: NSRange(location: 0, length: min(200, substring.count))) {
                            let priceStr = nsString.substring(with: match.range(at: 1))
                            let formatted = priceStr.replacingOccurrences(of: ",", with: ".")
                            return Double(formatted)
                        }
                    }
                }
            }
        } catch { print("TEFAS Hatası: \(error)") }
        return nil
    }
    
    // MARK: - Element API (Yahoo Finance)
    func fetchElementPrice(symbol: String) async -> Double? {
        var yahooSymbol = ""
        switch symbol {
        case "GLD": yahooSymbol = "GC=F"
        case "SLV": yahooSymbol = "SI=F"
        case "PLT": yahooSymbol = "PL=F"
        default: return nil
        }
        
        guard let ouncePriceUsd = await fetchYahooPrice(symbol: yahooSymbol) else { return nil }
        guard let usdTryRate = await fetchYahooPrice(symbol: "USDTRY=X") else { return nil }
        
        return (ouncePriceUsd / 31.1034768) * usdTryRate
    }
    
    // MARK: - Helpers
    private func fetchYahooPrice(symbol: String) async -> Double? {
        let urlString = "https://query1.finance.yahoo.com/v8/finance/chart/\(symbol)?interval=1d&range=1d"
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(YahooResponse.self, from: data)
            if let result = response.chart.result?.first, let price = result.meta.regularMarketPrice {
                return price
            }
        } catch { print("Yahoo Error: \(error)") }
        return nil
    }
}

// MARK: - Modeller
struct YahooResponse: Codable { let chart: YahooChart }
struct YahooChart: Codable { let result: [YahooResult]? }
struct YahooResult: Codable { let meta: YahooMeta }
struct YahooMeta: Codable { let regularMarketPrice: Double? }
