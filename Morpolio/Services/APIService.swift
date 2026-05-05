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
    
    // MARK: - Fund API (HangiKredi Scraping)
    func fetchFundPrice(symbol: String) async -> Double? {
        let cleanSymbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let price = await fetchFromHangikredi(symbol: cleanSymbol) {
            return price
        }
        
        return nil
    }
    
    // HangiKredi HTML Parser
    private func fetchFromHangikredi(symbol: String) async -> Double? {
        // HangiKredi URL'leri küçük harf ile çalışır (Örn: yzg)
        let urlString = "https://www.hangikredi.com/yatirim-araclari/fon/\(symbol.lowercased())"
        guard let url = URL(string: urlString) else { return nil }
        
        var request = URLRequest(url: url)
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7", forHTTPHeaderField: "Accept-Language")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 {
                if let html = String(data: data, encoding: .utf8) {
                    
                    // Regex: HTML elementleri (> ve <) arasında yer alan,
                    // formatı "12,3456" veya "1.234,56" şeklinde olan ondalıklı sayıları yakalar.
                    let pattern = ">\\s*([0-9]+(?:\\.[0-9]{3})*,[0-9]{2,6})\\s*<"
                    
                    if let regex = try? NSRegularExpression(pattern: pattern) {
                        
                        // Sadece body içeriğini tarayarak hatalı eşleşmeleri engelliyoruz
                        if let bodyRange = html.range(of: "<body") {
                            let substring = String(html[bodyRange.lowerBound...])
                            let nsSubString = substring as NSString
                            
                            let matches = regex.matches(in: substring, range: NSRange(location: 0, length: nsSubString.length))
                            
                            // Sayfadaki uygun formatlı ilk sayı genellikle ana fiyattır
                            if let match = matches.first {
                                let priceStr = nsSubString.substring(with: match.range(at: 1))
                                
                                // Swift'te ondalık sayıya çevirebilmek için binlik ayracı olan noktayı kaldır, virgülü noktaya çevir
                                let cleanPrice = priceStr.replacingOccurrences(of: ".", with: "")
                                                         .replacingOccurrences(of: ",", with: ".")
                                
                                if let price = Double(cleanPrice) {
                                    print("HangiKredi'den başarıyla çekildi: \(price)")
                                    return price
                                }
                            } else {
                                print("HangiKredi Parse Hatası: HTML içinde fiyat formatı bulunamadı.")
                            }
                        }
                    }
                }
            } else {
                if let httpRes = response as? HTTPURLResponse {
                    print("HangiKredi HTTP Hatası: \(httpRes.statusCode)")
                }
            }
        } catch { print("HangiKredi Bağlantı Hatası: \(error)") }
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
