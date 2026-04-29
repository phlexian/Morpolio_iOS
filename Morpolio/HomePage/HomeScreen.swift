import SwiftUI
import SwiftData

// Portföy Listesi için Yardımcı Model
struct PortfolioSummaryItem: Identifiable {
    var id: String { name }
    let name: String
    let value: Double
    let cost: Double
    let color: Color
    var percentage: Double = 0.0
    let tabIndex: Int
}

struct HomeScreen: View {
    @Query private var stocks: [Stock]
    @Query private var cryptos: [Crypto]
    @Query private var funds: [Fund]
    @Query private var elements: [Element]
    @Query private var cashItems: [Cash]
    
    @Environment(\.modelContext) private var context
    private let currencyService = CurrencyService()
    private let apiService = APIService()
    
    @Namespace private var animation
    @State private var isTextVisible = false
    @State private var isAnimationCompleted = false
    @State private var showListItems = false
    
    @Binding var activeTab: Int
    var onDragChanged: ((CGSize) -> Void)?
    var onDragEnded: ((CGSize) -> Void)?
    var onTapOpen: (() -> Void)?
    
    @State private var bounceAnimation = false
    
    @State private var selectedCurrency: Currency = .tryCurrency
    @State private var exchangeRates: (usd: Double, eur: Double) = (1.0, 1.0)
    @State private var isCurrencyBusy = false
    
    @State private var updateTrigger: Int = 0 // Arayüzü zorla yenilemek için tetikleyici
    
    var grandTotal: Double {
        _ = updateTrigger
        let s = stocks.reduce(0) { $0 + $1.totalValue }
        let c = cryptos.reduce(0) { $0 + $1.totalValue }
        let f = funds.reduce(0) { $0 + $1.totalValue }
        let e = elements.reduce(0) { $0 + $1.totalValue }
        let m = cashItems.reduce(0) { $0 + $1.totalValue }
        return s + c + f + e + m
    }
    
    var grandTotalCost: Double {
        _ = updateTrigger
        let s = stocks.reduce(0) { $0 + ($1.purchasePrice * $1.quantity) }
        let c = cryptos.reduce(0) { $0 + ($1.purchasePrice * $1.quantity) }
        let f = funds.reduce(0) { $0 + ($1.purchasePrice * $1.quantity) }
        let e = elements.reduce(0) { $0 + ($1.purchasePrice * $1.quantity) }
        let m = cashItems.reduce(0) { $0 + ($1.purchasePrice * $1.quantity) }
        return s + c + f + e + m
    }
    
    var overallProfit: Double { grandTotal - grandTotalCost }
    var overallProfitPercentage: Double { grandTotalCost > 0 ? (overallProfit / grandTotalCost) * 100 : 0.0 }
    
    func convert(_ value: Double) -> Double {
        switch selectedCurrency {
        case .tryCurrency: return value
        case .usd: return value / (rates.usd > 0 ? rates.usd : 1)
        case .eur: return value / (rates.eur > 0 ? rates.eur : 1)
        }
    }
    
    var rates: (usd: Double, eur: Double) { exchangeRates }
    
    var portfolioList: [PortfolioSummaryItem] {
        let total = grandTotal
        guard total > 0 else { return [] }
        
        var items = [
            PortfolioSummaryItem(name: "Hisseler", value: stocks.reduce(0) { $0 + $1.totalValue }, cost: stocks.reduce(0) { $0 + ($1.purchasePrice * $1.quantity) }, color: AppTheme.stockColor, tabIndex: 0),
            PortfolioSummaryItem(name: "Kripto", value: cryptos.reduce(0) { $0 + $1.totalValue }, cost: cryptos.reduce(0) { $0 + ($1.purchasePrice * $1.quantity) }, color: AppTheme.cryptoColor, tabIndex: 1),
            PortfolioSummaryItem(name: "Fonlar", value: funds.reduce(0) { $0 + $1.totalValue }, cost: funds.reduce(0) { $0 + ($1.purchasePrice * $1.quantity) }, color: AppTheme.fundColor, tabIndex: 2),
            PortfolioSummaryItem(name: "Madenler", value: elements.reduce(0) { $0 + $1.totalValue }, cost: elements.reduce(0) { $0 + ($1.purchasePrice * $1.quantity) }, color: AppTheme.elementColor, tabIndex: 3),
            PortfolioSummaryItem(name: "Nakit", value: cashItems.reduce(0) { $0 + $1.totalValue }, cost: cashItems.reduce(0) { $0 + ($1.purchasePrice * $1.quantity) }, color: AppTheme.cashColor, tabIndex: 4)
        ]
        
        items = items.filter { $0.value > 0 }
        for i in 0..<items.count { items[i].percentage = (items[i].value / total) * 100 }
        return items.sorted { $0.percentage > $1.percentage }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(uiColor: .systemBackground).ignoresSafeArea()
                VStack {
                    Spacer().frame(height: isAnimationCompleted ? 20 : geometry.size.height / 2.5)
                    Text("MORPOLIO")
                        .font(.system(size: 70, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.mainAppColor)
                        .scaleEffect(isAnimationCompleted ? 0.8 : 1.0)
                        .opacity(isTextVisible ? 1.0 : 0.0)
                    
                    if isAnimationCompleted {
                        Spacer().frame(height: 30)
                        
                        VStack(spacing: 30) {
                            
                            // A. TOPLAM VARLIK VE KAR/ZARAR
                            VStack(spacing: 5) {
                                Text("Varlıklar Toplamı").font(.title3).bold().foregroundStyle(.secondary)
                                Button(action: cycleCurrency) {
                                    HStack(spacing: 4) {
                                        Text("\(convert(grandTotal), specifier: "%.2f")").contentTransition(.numericText())
                                        Text(selectedCurrency.rawValue)
                                    }
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)
                                    .opacity(isCurrencyBusy ? 0.5 : 1.0)
                                }
                                .buttonStyle(.plain).disabled(isCurrencyBusy)
                                
                                if grandTotalCost > 0 {
                                    let convertedProfit = convert(overallProfit)
                                    let isProfit = convertedProfit >= 0
                                    let color: Color = isProfit ? .green : .red
                                    let sign = isProfit ? "+" : ""
                                    Text("\(sign)\(convertedProfit, specifier: "%.2f") \(selectedCurrency.rawValue) (\(sign)\(overallProfitPercentage, specifier: "%.2f")%)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(color)
                                }
                            }
                            
                            // B. AKORDİYON LİSTE (KARTLAR)
                            ScrollView(showsIndicators: false) {
                                VStack(spacing: 15) {
                                    ForEach(Array(portfolioList.enumerated()), id: \.element.id) { index, item in
                                        Button(action: { activeTab = item.tabIndex; onTapOpen?() }) {
                                            HStack {
                                                Capsule().fill(item.color).frame(width: 6, height: 45)
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(item.name).font(.title3).fontWeight(.semibold).foregroundStyle(.primary)
                                                    if item.cost > 0 {
                                                        let profitAmount = item.value - item.cost
                                                        let profitPct = (profitAmount / item.cost) * 100
                                                        let isProfit = profitAmount >= 0
                                                        let color: Color = isProfit ? .green : .red
                                                        let sign = isProfit ? "+" : ""
                                                        Text("\(sign)\(convert(profitAmount), specifier: "%.2f") \(selectedCurrency.rawValue) (\(sign)\(profitPct, specifier: "%.2f")%)")
                                                            .font(.caption)
                                                            .foregroundStyle(color)
                                                    }
                                                }
                                                .padding(.leading, 4)
                                                
                                                Spacer()
                                                VStack(alignment: .trailing, spacing: 2) {
                                                    Text("\(convert(item.value), specifier: "%.2f") \(selectedCurrency.rawValue)").font(.headline).bold().foregroundStyle(.primary)
                                                    Text("%\(item.percentage, specifier: "%.1f")").font(.subheadline).foregroundStyle(.secondary)
                                                }
                                            }
                                            .padding(.vertical, 16).padding(.horizontal, 20)
                                            .background(Color(uiColor: .secondarySystemBackground).opacity(0.6)).clipShape(RoundedRectangle(cornerRadius: 16))
                                        }
                                        .buttonStyle(.plain).padding(.horizontal, 20)
                                        .offset(x: showListItems ? 0 : -geometry.size.width * 1.5).opacity(showListItems ? 1 : 0)
                                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(index) * 0.1), value: showListItems)
                                    }
                                }
                                .padding(.top, 10)
                                .padding(.bottom, 20)
                            }
                            .scrollBounceBehavior(.always, axes: .vertical)
                            .refreshable {
                                await refreshAllData()
                            }
                        }
                        .transition(.opacity)
                    }
                    Spacer()
                    bottomInteractiveArea.padding(.bottom, 0)
                }
            }
        }
        .onAppear { startAnimation() }
    }
    
    var bottomInteractiveArea: some View {
        VStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "chevron.compact.up").font(.system(size: 30, weight: .medium)).foregroundStyle(Color.mainAppColor).offset(y: bounceAnimation ? -5 : 5)
                Text("VARLIKLAR").font(.system(size: 14, weight: .bold, design: .rounded)).tracking(2).foregroundStyle(.secondary)
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity).frame(height: 100).background(Color.clear).contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .global).onChanged { value in onDragChanged?(value.translation) }.onEnded { value in onDragEnded?(value.translation) })
        .simultaneousGesture(TapGesture().onEnded { onTapOpen?() })
        .onAppear { withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) { bounceAnimation = true } }
    }
    
    func startAnimation() {
        withAnimation(.easeIn(duration: 1.0)) { isTextVisible = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { withAnimation(.easeInOut(duration: 1.0)) { isAnimationCompleted = true } }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { showListItems = true }
    }
    
    func cycleCurrency() {
        switch selectedCurrency { case .tryCurrency: selectedCurrency = .usd; case .usd: selectedCurrency = .eur; case .eur: selectedCurrency = .tryCurrency }
        if selectedCurrency != .tryCurrency && exchangeRates == (1.0, 1.0) { Task { isCurrencyBusy = true; if let rates = await currencyService.fetchRates() { exchangeRates = rates }; isCurrencyBusy = false } }
    }
    
    // MARK: - EŞZAMANLI (PARALEL) VE GÜVENLİ API İSTEKLERİ
    @MainActor
    func refreshAllData() async {
        
        // Önce sadece sembolleri topluyoruz (State'i veya objeleri bozmamak için)
        let stockSymbols = stocks.map { $0.symbol }
        let cryptoSymbols = cryptos.map { $0.symbol }
        let fundSymbols = funds.map { $0.symbol }
        let elementSymbols = elements.map { $0.symbol }
        
        // API bağlantılarını birer değişkene atıyoruz (Görevlerin içinde kullanabilmek için)
        let api = apiService
        let curApi = currencyService
        
        // 1. Döviz Kurlarını arka planda çek (Değişkene ata, State'e DEĞİL)
        async let fetchedRates = curApi.fetchRates()
        
        // 2. Diğer tüm fiyatları paralel (aynı anda) çek
        let fetchedPrices = await withTaskGroup(of: (String, String, Double).self) { group in
            
            for sym in stockSymbols {
                group.addTask { if let p = await api.fetchStockPrice(symbol: sym) { return ("stock", sym, p) } else { return ("stock", sym, -1) } }
            }
            for sym in cryptoSymbols {
                group.addTask { if let p = await api.fetchCryptoPrice(symbol: sym) { return ("crypto", sym, p) } else { return ("crypto", sym, -1) } }
            }
            for sym in fundSymbols {
                group.addTask { if let p = await api.fetchFundPrice(symbol: sym) { return ("fund", sym, p) } else { return ("fund", sym, -1) } }
            }
            for sym in elementSymbols {
                group.addTask { if let p = await api.fetchElementPrice(symbol: sym) { return ("element", sym, p) } else { return ("element", sym, -1) } }
            }
            
            var results: [(String, String, Double)] = []
            for await result in group {
                if result.2 != -1 { results.append(result) }
            }
            return results
        }
        
        let newRates = await fetchedRates
        
        // ==========================================
        // İNDİRME İŞLEMLERİ BİTTİ. ŞİMDİ EKRANI GÜNCELLEYEBİLİRİZ!
        // ==========================================
        
        if let rates = newRates {
            exchangeRates = rates // Döviz kuru ekrana yansır
            for item in cashItems {
                if item.symbol == "USD" { item.currentPrice = rates.usd }
                else if item.symbol == "EUR" { item.currentPrice = rates.eur }
                else { item.currentPrice = 1.0 }
            }
        }
        
        // Hisseleri, kriptoları veritabanına yazıyoruz
        for result in fetchedPrices {
            let (type, sym, price) = result
            if type == "stock" { if let s = stocks.first(where: { $0.symbol == sym }) { s.currentPrice = price } }
            else if type == "crypto" { if let c = cryptos.first(where: { $0.symbol == sym }) { c.currentPrice = price } }
            else if type == "fund" { if let f = funds.first(where: { $0.symbol == sym }) { f.currentPrice = price } }
            else if type == "element" { if let e = elements.first(where: { $0.symbol == sym }) { e.currentPrice = price } }
        }
        
        // Kaydedip ekranı zorla yeniden çizdiriyoruz
        try? context.save()
        updateTrigger += 1
    }
}
