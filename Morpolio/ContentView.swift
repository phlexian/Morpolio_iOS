import SwiftUI
import SwiftData

// MARK: - 1. YARDIMCI YAPILAR
enum DeletedItemWrapper {
    case stock(symbol: String, quantity: Double, price: Double, purchasePrice: Double)
    case crypto(symbol: String, quantity: Double, price: Double, purchasePrice: Double)
    case fund(symbol: String, quantity: Double, price: Double, purchasePrice: Double)
    case element(symbol: String, quantity: Double, price: Double, purchasePrice: Double)
    case cash(symbol: String, quantity: Double, price: Double, purchasePrice: Double)
}

// YENİ: "Kar/Zarar %" seçeneği eklendi
enum SortOption: String, CaseIterable {
    case name = "İsim"
    case unitPrice = "Varlık Değeri"
    case totalValue = "Portföy Değeri"
    case profit = "Kar/Zarar"
    case profitPercentage = "Kar/Zarar %"
}

struct SortMenuButton: View {
    @Binding var selectedOption: SortOption
    @Binding var isAscending: Bool
    let themeColor: Color

    var body: some View {
        Menu {
            Section("Sırala:") {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button {
                        if selectedOption == option {
                            isAscending.toggle()
                        } else {
                            selectedOption = option
                            isAscending = false
                        }
                    } label: {
                        if selectedOption == option {
                            Label(option.rawValue, systemImage: isAscending ? "arrow.up" : "arrow.down")
                        } else {
                            Text(option.rawValue)
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .fontWeight(.bold)
                .foregroundStyle(themeColor)
        }
    }
}

// MARK: - 2. PORTFOLIO LAYOUT
struct PortfolioLayout<Content: View, SortMenu: View>: View {
    let title: String
    let themeColor: Color
    let totalValue: Double
    
    var totalProfit: Double? = nil
    var profitPercentage: Double? = nil
    
    @Binding var selectedCurrency: Currency
    @Binding var exchangeRates: (usd: Double, eur: Double)
    @Binding var isCurrencyBusy: Bool
    let isRefreshing: Bool
    let onRefresh: () async -> Void
    let onAdd: () -> Void
    
    @ViewBuilder let sortMenu: SortMenu
    @ViewBuilder let content: Content
    
    func convert(_ value: Double) -> Double {
        switch selectedCurrency {
        case .tryCurrency: return value
        case .usd: return value / (exchangeRates.usd > 0 ? exchangeRates.usd : 1)
        case .eur: return value / (exchangeRates.eur > 0 ? exchangeRates.eur : 1)
        }
    }
    
    var displayedValue: Double { convert(totalValue) }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isCurrencyBusy { ProgressView().zIndex(1) }
                
                VStack(spacing: 0) {
                    VStack(spacing: 5) {
                        Text(title)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(themeColor)
                        
                        Button(action: cycleCurrency) {
                            HStack(spacing: 4) {
                                Text("\(displayedValue, specifier: "%.2f")")
                                    .contentTransition(.numericText())
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)
                                
                                Text(selectedCurrency.rawValue)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        if let profit = totalProfit, let percentage = profitPercentage {
                            let convertedProfit = convert(profit)
                            let isProfit = convertedProfit >= 0
                            let color: Color = isProfit ? .green : .red
                            let sign = isProfit ? "+" : ""
                            
                            Text("\(sign)\(convertedProfit, specifier: "%.2f") \(selectedCurrency.rawValue) (\(sign)\(percentage, specifier: "%.2f")%)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(color)
                        }
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 15)
                    
                    content
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { Task { await onRefresh() } }) {
                        Image(systemName: "arrow.clockwise")
                            .symbolEffect(.bounce, value: isRefreshing)
                            .foregroundStyle(themeColor)
                    }
                    .disabled(isRefreshing)
                }
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    sortMenu
                    
                    Button(action: onAdd) {
                        Image(systemName: "plus")
                            .fontWeight(.bold)
                            .foregroundStyle(themeColor)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    func cycleCurrency() {
        switch selectedCurrency {
        case .tryCurrency: selectedCurrency = .usd
        case .usd: selectedCurrency = .eur
        case .eur: selectedCurrency = .tryCurrency
        }
    }
}

// MARK: - 3. MAIN CONTENT VIEW
struct ContentView: View {
    var onClose: (() -> Void)? = nil
    @Binding var selectedTab: Int
    
    @Environment(\.modelContext) private var context
    
    @Query(sort: \Stock.symbol) var stocks: [Stock]
    @Query(sort: \Crypto.symbol) var cryptos: [Crypto]
    @Query(sort: \Fund.symbol) var funds: [Fund]
    @Query(sort: \Element.symbol) var elements: [Element]
    @Query(sort: \Cash.symbol) var cashItems: [Cash]
    
    private let apiService = APIService()
    private let currencyService = CurrencyService()
    
    @State private var isRefreshingStock = false
    @State private var isRefreshingCrypto = false
    @State private var isRefreshingFund = false
    @State private var isRefreshingElement = false
    @State private var isRefreshingCash = false
    
    @State private var showStockAdder = false
    @State private var showCryptoAdder = false
    @State private var showFundAdder = false
    @State private var showElementAdder = false
    @State private var showCashAdder = false
    
    @State private var isCurrencyBusy = false
    @State private var selectedCurrency: Currency = .tryCurrency
    @State private var exchangeRates: (usd: Double, eur: Double) = (1.0, 1.0)
    
    @State private var showToast = false
    @State private var deletedItemBackup: DeletedItemWrapper?
    @State private var toastMessage = ""
    @State private var activeCategory: CategoryType = .stock
    @State private var undoTimer: Timer?
    @State private var timeLeft: Int = 5
    
    @State private var stockSortOption: SortOption = .totalValue
    @State private var stockSortAsc: Bool = false
    
    @State private var cryptoSortOption: SortOption = .totalValue
    @State private var cryptoSortAsc: Bool = false
    
    @State private var fundSortOption: SortOption = .totalValue
    @State private var fundSortAsc: Bool = false
    
    @State private var elementSortOption: SortOption = .totalValue
    @State private var elementSortAsc: Bool = false
    
    @State private var cashSortOption: SortOption = .totalValue
    @State private var cashSortAsc: Bool = false
    
    // Genel Toplam Hesaplamaları
    var totalStockValue: Double { stocks.reduce(0) { $0 + $1.totalValue } }
    var totalCryptoValue: Double { cryptos.reduce(0) { $0 + $1.totalValue } }
    var totalFundValue: Double { funds.reduce(0) { $0 + $1.totalValue } }
    var totalElementValue: Double { elements.reduce(0) { $0 + $1.totalValue } }
    var totalCashValue: Double { cashItems.reduce(0) { $0 + $1.totalValue } }
    
    var totalStockPurchaseValue: Double { stocks.reduce(0) { $0 + ($1.purchasePrice * $1.quantity) } }
    var totalStockProfit: Double { totalStockValue - totalStockPurchaseValue }
    var totalStockProfitPercentage: Double { totalStockPurchaseValue > 0 ? (totalStockProfit / totalStockPurchaseValue) * 100 : 0.0 }
    
    var totalCryptoPurchaseValue: Double { cryptos.reduce(0) { $0 + ($1.purchasePrice * $1.quantity) } }
    var totalCryptoProfit: Double { totalCryptoValue - totalCryptoPurchaseValue }
    var totalCryptoProfitPercentage: Double { totalCryptoPurchaseValue > 0 ? (totalCryptoProfit / totalCryptoPurchaseValue) * 100 : 0.0 }
    
    var totalFundPurchaseValue: Double { funds.reduce(0) { $0 + ($1.purchasePrice * $1.quantity) } }
    var totalFundProfit: Double { totalFundValue - totalFundPurchaseValue }
    var totalFundProfitPercentage: Double { totalFundPurchaseValue > 0 ? (totalFundProfit / totalFundPurchaseValue) * 100 : 0.0 }
    
    var totalElementPurchaseValue: Double { elements.reduce(0) { $0 + ($1.purchasePrice * $1.quantity) } }
    var totalElementProfit: Double { totalElementValue - totalElementPurchaseValue }
    var totalElementProfitPercentage: Double { totalElementPurchaseValue > 0 ? (totalElementProfit / totalElementPurchaseValue) * 100 : 0.0 }
    
    var totalCashPurchaseValue: Double { cashItems.reduce(0) { $0 + ($1.purchasePrice * $1.quantity) } }
    var totalCashProfit: Double { totalCashValue - totalCashPurchaseValue }
    var totalCashProfitPercentage: Double { totalCashPurchaseValue > 0 ? (totalCashProfit / totalCashPurchaseValue) * 100 : 0.0 }
    
    // YENİ: Yüzde sıralaması için profitPct parametresi eklendi
    func sortItems<T>(items: [T], option: SortOption, asc: Bool, name: (T) -> String, price: (T) -> Double, total: (T) -> Double, profit: (T) -> Double, profitPct: (T) -> Double) -> [T] {
        items.sorted { a, b in
            switch option {
            case .name: return asc ? name(a) < name(b) : name(a) > name(b)
            case .unitPrice: return asc ? price(a) < price(b) : price(a) > price(b)
            case .totalValue: return asc ? total(a) < total(b) : total(a) > total(b)
            case .profit: return asc ? profit(a) < profit(b) : profit(a) > profit(b)
            case .profitPercentage: return asc ? profitPct(a) < profitPct(b) : profitPct(a) > profitPct(b)
            }
        }
    }
    
    // Modellerdeki profitLossPercentage özelliği üzerinden yüzdeye göre sıralama yapılıyor
    var sortedStocks: [Stock] { sortItems(items: stocks, option: stockSortOption, asc: stockSortAsc, name: { $0.symbol }, price: { $0.currentPrice }, total: { $0.totalValue }, profit: { $0.profitLossAmount }, profitPct: { $0.profitLossPercentage }) }
    var sortedCryptos: [Crypto] { sortItems(items: cryptos, option: cryptoSortOption, asc: cryptoSortAsc, name: { $0.symbol }, price: { $0.currentPrice }, total: { $0.totalValue }, profit: { $0.profitLossAmount }, profitPct: { $0.profitLossPercentage }) }
    var sortedFunds: [Fund] { sortItems(items: funds, option: fundSortOption, asc: fundSortAsc, name: { $0.symbol }, price: { $0.currentPrice }, total: { $0.totalValue }, profit: { $0.profitLossAmount }, profitPct: { $0.profitLossPercentage }) }
    var sortedElements: [Element] { sortItems(items: elements, option: elementSortOption, asc: elementSortAsc, name: { $0.displayName }, price: { $0.currentPrice }, total: { $0.totalValue }, profit: { $0.profitLossAmount }, profitPct: { $0.profitLossPercentage }) }
    var sortedCash: [Cash] { sortItems(items: cashItems, option: cashSortOption, asc: cashSortAsc, name: { $0.displayName }, price: { $0.currentPrice }, total: { $0.totalValue }, profit: { $0.profitLossAmount }, profitPct: { $0.profitLossPercentage }) }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Capsule().fill(Color.gray.opacity(0.3)).frame(width: 40, height: 6).padding(.top, 10).padding(.bottom, 5)
                        .onTapGesture { onClose?() }
                    Spacer()
                }
                .background(Color(uiColor: .systemBackground))
                
                TabView(selection: $selectedTab) {
                    PortfolioLayout(title: "Hisseler", themeColor: AppTheme.stockColor, totalValue: totalStockValue, totalProfit: totalStockProfit, profitPercentage: totalStockProfitPercentage, selectedCurrency: $selectedCurrency, exchangeRates: $exchangeRates, isCurrencyBusy: $isCurrencyBusy, isRefreshing: isRefreshingStock, onRefresh: refreshStocks, onAdd: { showStockAdder = true },
                        sortMenu: { SortMenuButton(selectedOption: $stockSortOption, isAscending: $stockSortAsc, themeColor: AppTheme.stockColor) }
                    ) {
                        StockListView(stocks: sortedStocks, currency: selectedCurrency, rates: exchangeRates, themeColor: AppTheme.stockColor, onRefresh: refreshStocks, onDeleteRequest: { item in
                            activeCategory = .stock
                            handleDelete(message: "'\(item.symbol)' silindi!", type: .stock(symbol: item.symbol, quantity: item.quantity, price: item.currentPrice, purchasePrice: item.purchasePrice), itemToDelete: item)
                        })
                    }
                    .sheet(isPresented: $showStockAdder) { StockAdderScreen(themeColor: AppTheme.stockColor).presentationDetents([.fraction(0.6), .large]) }
                    .tabItem { Label("Hisse", systemImage: "chart.bar.xaxis") }.tag(0)
                    
                    PortfolioLayout(title: "Kripto Varlıklar", themeColor: AppTheme.cryptoColor, totalValue: totalCryptoValue, totalProfit: totalCryptoProfit, profitPercentage: totalCryptoProfitPercentage, selectedCurrency: $selectedCurrency, exchangeRates: $exchangeRates, isCurrencyBusy: $isCurrencyBusy, isRefreshing: isRefreshingCrypto, onRefresh: refreshCryptos, onAdd: { showCryptoAdder = true },
                        sortMenu: { SortMenuButton(selectedOption: $cryptoSortOption, isAscending: $cryptoSortAsc, themeColor: AppTheme.cryptoColor) }
                    ) {
                        CryptoListView(cryptos: sortedCryptos, currency: selectedCurrency, rates: exchangeRates, themeColor: AppTheme.cryptoColor, onRefresh: refreshCryptos, onDeleteRequest: { item in
                            activeCategory = .crypto
                            handleDelete(message: "'\(item.symbol)' silindi!", type: .crypto(symbol: item.symbol, quantity: item.quantity, price: item.currentPrice, purchasePrice: item.purchasePrice), itemToDelete: item)
                        })
                    }
                    .sheet(isPresented: $showCryptoAdder) { CryptoAdderScreen(themeColor: AppTheme.cryptoColor).presentationDetents([.fraction(0.6), .large]) }
                    .tabItem { Label("Kripto", systemImage: "bitcoinsign.circle") }.tag(1)
                    
                    PortfolioLayout(title: "Yatırım Fonları", themeColor: AppTheme.fundColor, totalValue: totalFundValue, totalProfit: totalFundProfit, profitPercentage: totalFundProfitPercentage, selectedCurrency: $selectedCurrency, exchangeRates: $exchangeRates, isCurrencyBusy: $isCurrencyBusy, isRefreshing: isRefreshingFund, onRefresh: refreshFunds, onAdd: { showFundAdder = true },
                        sortMenu: { SortMenuButton(selectedOption: $fundSortOption, isAscending: $fundSortAsc, themeColor: AppTheme.fundColor) }
                    ) {
                        FundListView(funds: sortedFunds, currency: selectedCurrency, rates: exchangeRates, themeColor: AppTheme.fundColor, onRefresh: refreshFunds, onDeleteRequest: { item in
                            activeCategory = .fund
                            handleDelete(message: "'\(item.symbol)' silindi!", type: .fund(symbol: item.symbol, quantity: item.quantity, price: item.currentPrice, purchasePrice: item.purchasePrice), itemToDelete: item)
                        })
                    }
                    .sheet(isPresented: $showFundAdder) { FundAdderScreen(themeColor: AppTheme.fundColor).presentationDetents([.fraction(0.6), .large]) }
                    .tabItem { Label("Fon", systemImage: "building.columns.circle") }.tag(2)
                    
                    PortfolioLayout(title: "Değerli Madenler", themeColor: AppTheme.elementColor, totalValue: totalElementValue, totalProfit: totalElementProfit, profitPercentage: totalElementProfitPercentage, selectedCurrency: $selectedCurrency, exchangeRates: $exchangeRates, isCurrencyBusy: $isCurrencyBusy, isRefreshing: isRefreshingElement, onRefresh: refreshElements, onAdd: { showElementAdder = true },
                        sortMenu: { SortMenuButton(selectedOption: $elementSortOption, isAscending: $elementSortAsc, themeColor: AppTheme.elementColor) }
                    ) {
                        ElementListView(elements: sortedElements, currency: selectedCurrency, rates: exchangeRates, themeColor: AppTheme.elementColor, onRefresh: refreshElements, onDeleteRequest: { item in
                            activeCategory = .element
                            handleDelete(message: "'\(item.displayName)' silindi!", type: .element(symbol: item.symbol, quantity: item.quantity, price: item.currentPrice, purchasePrice: item.purchasePrice), itemToDelete: item)
                        })
                    }
                    .sheet(isPresented: $showElementAdder) { ElementAdderScreen(themeColor: AppTheme.elementColor).presentationDetents([.fraction(0.6), .large]) }
                    .tabItem { Label("Maden", systemImage: "circle.hexagonpath.fill") }.tag(3)
                    
                    PortfolioLayout(title: "Nakit Varlıklar", themeColor: AppTheme.cashColor, totalValue: totalCashValue, totalProfit: totalCashProfit, profitPercentage: totalCashProfitPercentage, selectedCurrency: $selectedCurrency, exchangeRates: $exchangeRates, isCurrencyBusy: $isCurrencyBusy, isRefreshing: isRefreshingCash, onRefresh: refreshCash, onAdd: { showCashAdder = true },
                        sortMenu: { SortMenuButton(selectedOption: $cashSortOption, isAscending: $cashSortAsc, themeColor: AppTheme.cashColor) }
                    ) {
                        CashListView(cashItems: sortedCash, currency: selectedCurrency, rates: exchangeRates, themeColor: AppTheme.cashColor, onRefresh: refreshCash, onDeleteRequest: { item in
                            activeCategory = .cash
                            handleDelete(message: "'\(item.displayName)' silindi!", type: .cash(symbol: item.symbol, quantity: item.quantity, price: item.currentPrice, purchasePrice: item.purchasePrice), itemToDelete: item)
                        })
                    }
                    .sheet(isPresented: $showCashAdder) { CashAdderScreen(themeColor: AppTheme.cashColor).presentationDetents([.fraction(0.6), .large]) }
                    .tabItem { Label("Nakit", systemImage: "banknote") }.tag(4)
                }
                .tint(currentTabColor)
            }
            
            if showToast {
                FancyToastView(message: toastMessage, themeColor: AppTheme.color(for: activeCategory), timeLeft: timeLeft, onUndo: undoDelete)
                .padding(.bottom, 100)
                .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
                .zIndex(100)
            }
        }
        .onChange(of: selectedCurrency) { _, n in
            if n != .tryCurrency && exchangeRates == (1.0, 1.0) {
                Task { isCurrencyBusy = true; if let r = await currencyService.fetchRates() { exchangeRates = r }; isCurrencyBusy = false }
            }
        }
    }
    
    var currentTabColor: Color {
        switch selectedTab {
        case 0: return AppTheme.stockColor
        case 1: return AppTheme.cryptoColor
        case 2: return AppTheme.fundColor
        case 3: return AppTheme.elementColor
        case 4: return AppTheme.cashColor
        default: return .blue
        }
    }
    
    func refreshStocks() async { isRefreshingStock = true; for s in stocks { if let p = await apiService.fetchStockPrice(symbol: s.symbol) { s.currentPrice = p } }; try? context.save(); isRefreshingStock = false }
    func refreshCryptos() async { isRefreshingCrypto = true; for c in cryptos { if let p = await apiService.fetchCryptoPrice(symbol: c.symbol) { c.currentPrice = p } }; try? context.save(); isRefreshingCrypto = false }
    func refreshFunds() async { isRefreshingFund = true; for f in funds { if let p = await apiService.fetchFundPrice(symbol: f.symbol) { f.currentPrice = p } }; try? context.save(); isRefreshingFund = false }
    func refreshElements() async { isRefreshingElement = true; for e in elements { if let p = await apiService.fetchElementPrice(symbol: e.symbol) { e.currentPrice = p } }; try? context.save(); isRefreshingElement = false }
    func refreshCash() async { isRefreshingCash = true; if let rates = await currencyService.fetchRates() { exchangeRates = rates; for item in cashItems { if item.symbol == "USD" { item.currentPrice = rates.usd } else if item.symbol == "EUR" { item.currentPrice = rates.eur } else { item.currentPrice = 1.0 } }; try? context.save() }; isRefreshingCash = false }
    
    func handleDelete<T: PersistentModel>(message: String, type: DeletedItemWrapper, itemToDelete: T) {
        undoTimer?.invalidate()
        deletedItemBackup = type
        context.delete(itemToDelete)
        toastMessage = message
        timeLeft = 5
        withAnimation { showToast = true }
        undoTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeLeft > 0 { withAnimation { timeLeft -= 1 } }
            else { withAnimation { showToast = false }; deletedItemBackup = nil; undoTimer?.invalidate() }
        }
    }
    
    func undoDelete() {
        undoTimer?.invalidate()
        guard let b = deletedItemBackup else { return }
        switch b {
        case .stock(let s, let q, let p, let pp): context.insert(Stock(symbol: s, quantity: q, currentPrice: p, purchasePrice: pp))
        case .crypto(let s, let q, let p, let pp): context.insert(Crypto(symbol: s, quantity: q, currentPrice: p, purchasePrice: pp))
        case .fund(let s, let q, let p, let pp): context.insert(Fund(symbol: s, quantity: q, currentPrice: p, purchasePrice: pp))
        case .element(let s, let q, let p, let pp): context.insert(Element(symbol: s, quantity: q, currentPrice: p, purchasePrice: pp))
        case .cash(let s, let q, let p, let pp): context.insert(Cash(symbol: s, quantity: q, currentPrice: p, purchasePrice: pp))
        }
        withAnimation { showToast = false }
        deletedItemBackup = nil
    }
}

// MARK: - 4. LİSTE GÖRÜNÜMLERİ
struct StockListView: View {
    var stocks: [Stock]; var currency: Currency; var rates: (usd: Double, eur: Double); var themeColor: Color; var onRefresh: () async -> Void; var onDeleteRequest: (Stock) -> Void
    @Environment(\.modelContext) private var context; @State private var itemToUpdate: Stock?
    func convert(_ value: Double) -> Double { switch currency { case .tryCurrency: return value; case .usd: return value / (rates.usd > 0 ? rates.usd : 1); case .eur: return value / (rates.eur > 0 ? rates.eur : 1) } }
    var body: some View {
        List {
            ForEach(stocks) { stock in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .lastTextBaseline, spacing: 6) { Text(stock.symbol).font(.headline).bold(); Text("\(convert(stock.currentPrice), specifier: "%.2f") \(currency.rawValue)").font(.caption).foregroundStyle(.secondary) }
                        Text("\(stock.quantity, specifier: "%.0f") adet • Maliyet: \(convert(stock.purchasePrice), specifier: "%.2f")").font(.caption).foregroundStyle(.gray)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(convert(stock.totalValue), specifier: "%.2f") \(currency.rawValue)").bold()
                        let profitAmount = convert(stock.profitLossAmount); let isProfit = profitAmount >= 0; let color: Color = isProfit ? .green : .red; let sign = isProfit ? "+" : ""
                        Text("\(sign)\(profitAmount, specifier: "%.2f") \(currency.rawValue) (\(sign)\(stock.profitLossPercentage, specifier: "%.2f")%)").font(.caption).foregroundStyle(color)
                    }
                }
                .padding(.vertical, 4)
                .listRowBackground(Rectangle().fill(Color(uiColor: .secondarySystemGroupedBackground)))
                .swipeActions(edge: .trailing, allowsFullSwipe: false) { Button(role: .destructive) { onDeleteRequest(stock) } label: { Label("Sil", systemImage: "trash") }.tint(.red); Button { itemToUpdate = stock } label: { Label("Güncelle", systemImage: "pencil") }.tint(themeColor) }
            }
        }
        .listStyle(.insetGrouped).refreshable { await onRefresh() }
        .sheet(item: $itemToUpdate) { stock in QuantityUpdateSheet(symbol: stock.symbol, currentQuantity: stock.quantity, currentPurchasePrice: stock.purchasePrice) { newQty, newPrice in stock.quantity = newQty; stock.purchasePrice = newPrice; try? context.save() }.presentationDetents([.fraction(0.4)]) }
    }
}

struct CryptoListView: View {
    var cryptos: [Crypto]; var currency: Currency; var rates: (usd: Double, eur: Double); var themeColor: Color; var onRefresh: () async -> Void; var onDeleteRequest: (Crypto) -> Void
    @Environment(\.modelContext) private var context; @State private var itemToUpdate: Crypto?
    func convert(_ value: Double) -> Double { switch currency { case .tryCurrency: return value; case .usd: return value / (rates.usd > 0 ? rates.usd : 1); case .eur: return value / (rates.eur > 0 ? rates.eur : 1) } }
    var body: some View {
        List {
            ForEach(cryptos) { crypto in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .lastTextBaseline, spacing: 6) { Text(crypto.symbol).font(.headline).bold(); Text("\(convert(crypto.currentPrice), specifier: "%.4f") \(currency.rawValue)").font(.caption).foregroundStyle(.secondary) }
                        Text("\(crypto.quantity, specifier: "%.4f") adet • Maliyet: \(convert(crypto.purchasePrice), specifier: "%.4f")").font(.caption).foregroundStyle(.gray)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(convert(crypto.totalValue), specifier: "%.2f") \(currency.rawValue)").bold()
                        let profitAmount = convert(crypto.profitLossAmount); let isProfit = profitAmount >= 0; let color: Color = isProfit ? .green : .red; let sign = isProfit ? "+" : ""
                        Text("\(sign)\(profitAmount, specifier: "%.2f") \(currency.rawValue) (\(sign)\(crypto.profitLossPercentage, specifier: "%.2f")%)").font(.caption).foregroundStyle(color)
                    }
                }
                .padding(.vertical, 4).listRowBackground(Rectangle().fill(Color(uiColor: .secondarySystemGroupedBackground)))
                .swipeActions(edge: .trailing, allowsFullSwipe: false) { Button(role: .destructive) { onDeleteRequest(crypto) } label: { Label("Sil", systemImage: "trash") }.tint(.red); Button { itemToUpdate = crypto } label: { Label("Güncelle", systemImage: "pencil") }.tint(themeColor) }
            }
        }
        .listStyle(.insetGrouped).refreshable { await onRefresh() }
        .sheet(item: $itemToUpdate) { crypto in
            // YENİ: Sheet'e orijinal fiyatı ve satın alınan döviz sembolünü yolluyoruz
            QuantityUpdateSheet(symbol: crypto.symbol, currentQuantity: crypto.quantity, currentPurchasePrice: crypto.originalPurchasePrice, purchaseCurrency: crypto.purchaseCurrency) { newQty, newOriginalPrice in
                crypto.quantity = newQty
                crypto.originalPurchasePrice = newOriginalPrice
                
                // YENİ: Girilen yabancı dövizi TL karşılığına çevirip veritabanına yazıyoruz (Kar zarar hesabı için)
                let multiplier: Double
                if crypto.purchaseCurrency == "$" { multiplier = rates.usd }
                else if crypto.purchaseCurrency == "€" { multiplier = rates.eur }
                else { multiplier = 1.0 }
                
                crypto.purchasePrice = newOriginalPrice * multiplier
                try? context.save()
            }.presentationDetents([.fraction(0.4)])
        }
    }
}

struct FundListView: View {
    var funds: [Fund]; var currency: Currency; var rates: (usd: Double, eur: Double); var themeColor: Color; var onRefresh: () async -> Void; var onDeleteRequest: (Fund) -> Void
    @Environment(\.modelContext) private var context; @State private var itemToUpdate: Fund?
    func convert(_ value: Double) -> Double { switch currency { case .tryCurrency: return value; case .usd: return value / (rates.usd > 0 ? rates.usd : 1); case .eur: return value / (rates.eur > 0 ? rates.eur : 1) } }
    var body: some View {
        List {
            ForEach(funds) { fund in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .lastTextBaseline, spacing: 6) { Text(fund.symbol).font(.headline).bold(); Text("\(convert(fund.currentPrice), specifier: "%.4f") \(currency.rawValue)").font(.caption).foregroundStyle(.secondary) }
                        Text("\(fund.quantity, specifier: "%.0f") adet • Maliyet: \(convert(fund.purchasePrice), specifier: "%.4f")").font(.caption).foregroundStyle(.gray)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(convert(fund.totalValue), specifier: "%.2f") \(currency.rawValue)").bold()
                        let profitAmount = convert(fund.profitLossAmount); let isProfit = profitAmount >= 0; let color: Color = isProfit ? .green : .red; let sign = isProfit ? "+" : ""
                        Text("\(sign)\(profitAmount, specifier: "%.2f") \(currency.rawValue) (\(sign)\(fund.profitLossPercentage, specifier: "%.2f")%)").font(.caption).foregroundStyle(color)
                    }
                }
                .padding(.vertical, 4).listRowBackground(Rectangle().fill(Color(uiColor: .secondarySystemGroupedBackground)))
                .swipeActions(edge: .trailing, allowsFullSwipe: false) { Button(role: .destructive) { onDeleteRequest(fund) } label: { Label("Sil", systemImage: "trash") }.tint(.red); Button { itemToUpdate = fund } label: { Label("Güncelle", systemImage: "pencil") }.tint(themeColor) }
            }
        }
        .listStyle(.insetGrouped).refreshable { await onRefresh() }
        .sheet(item: $itemToUpdate) { fund in QuantityUpdateSheet(symbol: fund.symbol, currentQuantity: fund.quantity, currentPurchasePrice: fund.purchasePrice) { newQty, newPrice in fund.quantity = newQty; fund.purchasePrice = newPrice; try? context.save() }.presentationDetents([.fraction(0.4)]) }
    }
}

struct ElementListView: View {
    var elements: [Element]; var currency: Currency; var rates: (usd: Double, eur: Double); var themeColor: Color; var onRefresh: () async -> Void; var onDeleteRequest: (Element) -> Void
    @Environment(\.modelContext) private var context; @State private var itemToUpdate: Element?
    func convert(_ value: Double) -> Double { switch currency { case .tryCurrency: return value; case .usd: return value / (rates.usd > 0 ? rates.usd : 1); case .eur: return value / (rates.eur > 0 ? rates.eur : 1) } }
    var body: some View {
        List {
            ForEach(elements) { element in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .lastTextBaseline, spacing: 6) { Text(element.displayName).font(.headline).bold(); Text("\(convert(element.currentPrice), specifier: "%.2f") \(currency.rawValue)").font(.caption).foregroundStyle(.secondary) }
                        Text("\(element.quantity, specifier: "%.2f") Gr • Maliyet: \(convert(element.purchasePrice), specifier: "%.2f")").font(.caption).foregroundStyle(.gray)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(convert(element.totalValue), specifier: "%.2f") \(currency.rawValue)").bold()
                        let profitAmount = convert(element.profitLossAmount); let isProfit = profitAmount >= 0; let color: Color = isProfit ? .green : .red; let sign = isProfit ? "+" : ""
                        Text("\(sign)\(profitAmount, specifier: "%.2f") \(currency.rawValue) (\(sign)\(element.profitLossPercentage, specifier: "%.2f")%)").font(.caption).foregroundStyle(color)
                    }
                }
                .padding(.vertical, 4).listRowBackground(Rectangle().fill(Color(uiColor: .secondarySystemGroupedBackground)))
                .swipeActions(edge: .trailing, allowsFullSwipe: false) { Button(role: .destructive) { onDeleteRequest(element) } label: { Label("Sil", systemImage: "trash") }.tint(.red); Button { itemToUpdate = element } label: { Label("Güncelle", systemImage: "pencil") }.tint(themeColor) }
            }
        }
        .listStyle(.insetGrouped).refreshable { await onRefresh() }
        .sheet(item: $itemToUpdate) { element in QuantityUpdateSheet(symbol: element.displayName, currentQuantity: element.quantity, currentPurchasePrice: element.purchasePrice) { newQty, newPrice in element.quantity = newQty; element.purchasePrice = newPrice; try? context.save() }.presentationDetents([.fraction(0.4)]) }
    }
}

struct CashListView: View {
    var cashItems: [Cash]; var currency: Currency; var rates: (usd: Double, eur: Double); var themeColor: Color; var onRefresh: () async -> Void; var onDeleteRequest: (Cash) -> Void
    @Environment(\.modelContext) private var context; @State private var itemToUpdate: Cash?
    func convert(_ value: Double) -> Double { switch currency { case .tryCurrency: return value; case .usd: return value / (rates.usd > 0 ? rates.usd : 1); case .eur: return value / (rates.eur > 0 ? rates.eur : 1) } }
    var body: some View {
        List {
            ForEach(cashItems) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .lastTextBaseline, spacing: 6) { Text(item.displayName).font(.headline).bold(); if item.symbol != "TRY" { Text("\(convert(item.currentPrice), specifier: "%.2f") \(currency.rawValue)").font(.caption).foregroundStyle(.secondary) } }
                        if item.symbol != "TRY" { Text("\(item.quantity, specifier: "%.2f") • Alış Kuru: \(convert(item.purchasePrice), specifier: "%.2f")").font(.caption).foregroundStyle(.gray) } else { Text("\(item.quantity, specifier: "%.2f")").font(.caption).foregroundStyle(.gray) }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(convert(item.totalValue), specifier: "%.2f") \(currency.rawValue)").bold()
                        if item.symbol != "TRY" {
                            let profitAmount = convert(item.profitLossAmount); let isProfit = profitAmount >= 0; let color: Color = isProfit ? .green : .red; let sign = isProfit ? "+" : ""
                            Text("\(sign)\(profitAmount, specifier: "%.2f") \(currency.rawValue) (\(sign)\(item.profitLossPercentage, specifier: "%.2f")%)").font(.caption).foregroundStyle(color)
                        }
                    }
                }
                .padding(.vertical, 4).listRowBackground(Rectangle().fill(Color(uiColor: .secondarySystemGroupedBackground)))
                .swipeActions(edge: .trailing, allowsFullSwipe: false) { Button(role: .destructive) { onDeleteRequest(item) } label: { Label("Sil", systemImage: "trash") }.tint(.red); Button { itemToUpdate = item } label: { Label("Güncelle", systemImage: "pencil") }.tint(themeColor) }
            }
        }
        .listStyle(.insetGrouped).refreshable { await onRefresh() }
        .sheet(item: $itemToUpdate) { item in QuantityUpdateSheet(symbol: item.displayName, currentQuantity: item.quantity, currentPurchasePrice: item.purchasePrice) { newQty, newPrice in item.quantity = newQty; item.purchasePrice = newPrice; try? context.save() }.presentationDetents([.fraction(0.4)]) }
    }
}
