import SwiftUI
import SwiftData

// MARK: - 1. YARDIMCI YAPILAR (Undo İşlemi İçin)
enum DeletedItemWrapper {
    case stock(symbol: String, quantity: Double, price: Double)
    case crypto(symbol: String, quantity: Double, price: Double)
    case fund(symbol: String, quantity: Double, price: Double)
    case element(symbol: String, quantity: Double, price: Double)
    case cash(symbol: String, quantity: Double, price: Double)
}

// MARK: - 2. PORTFOLIO LAYOUT (Standart Tasarım İskeleti)
struct PortfolioLayout<Content: View>: View {
    let title: String
    let themeColor: Color
    let totalValue: Double
    @Binding var selectedCurrency: Currency
    @Binding var exchangeRates: (usd: Double, eur: Double)
    @Binding var isCurrencyBusy: Bool
    let isRefreshing: Bool
    let onRefresh: () async -> Void
    let onAdd: () -> Void
    @ViewBuilder let content: Content
    
    var displayedValue: Double {
        switch selectedCurrency {
        case .tryCurrency: return totalValue
        case .usd: return totalValue / (exchangeRates.usd > 0 ? exchangeRates.usd : 1)
        case .eur: return totalValue / (exchangeRates.eur > 0 ? exchangeRates.eur : 1)
        }
    }
    
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
                
                ToolbarItem(placement: .topBarTrailing) {
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
    // DÜZELTME: RootView'un beklediği onClose parametresi eklendi
    var onClose: (() -> Void)? = nil
    
    @Binding var selectedTab: Int
    
    // Veritabanı Bağlantısı
    @Environment(\.modelContext) private var context
    
    @Query(sort: \Stock.symbol) var stocks: [Stock]
    @Query(sort: \Crypto.symbol) var cryptos: [Crypto]
    @Query(sort: \Fund.symbol) var funds: [Fund]
    @Query(sort: \Element.symbol) var elements: [Element]
    @Query(sort: \Cash.symbol) var cashItems: [Cash]
    
    // Servisler
    private let apiService = APIService()
    private let currencyService = CurrencyService()
    
    // Refresh Durumları
    @State private var isRefreshingStock = false
    @State private var isRefreshingCrypto = false
    @State private var isRefreshingFund = false
    @State private var isRefreshingElement = false
    @State private var isRefreshingCash = false
    
    // Sheet (Ekleme Ekranı) Durumları
    @State private var showStockAdder = false
    @State private var showCryptoAdder = false
    @State private var showFundAdder = false
    @State private var showElementAdder = false
    @State private var showCashAdder = false
    
    // Döviz Durumları
    @State private var isCurrencyBusy = false
    @State private var selectedCurrency: Currency = .tryCurrency
    @State private var exchangeRates: (usd: Double, eur: Double) = (1.0, 1.0)
    
    // Toast & Silme Durumları
    @State private var showToast = false
    @State private var deletedItemBackup: DeletedItemWrapper?
    @State private var toastMessage = ""
    @State private var activeCategory: CategoryType = .stock
    @State private var undoTimer: Timer?
    @State private var timeLeft: Int = 5
    
    // Toplam Değer Hesaplamaları
    var totalStockValue: Double { stocks.reduce(0) { $0 + $1.totalValue } }
    var totalCryptoValue: Double { cryptos.reduce(0) { $0 + $1.totalValue } }
    var totalFundValue: Double { funds.reduce(0) { $0 + $1.totalValue } }
    var totalElementValue: Double { elements.reduce(0) { $0 + $1.totalValue } }
    var totalCashValue: Double { cashItems.reduce(0) { $0 + $1.totalValue } }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Üst Tutamaç Çizgisi (Interactive Dismiss İçin)
                HStack {
                    Spacer()
                    Capsule()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 6)
                        .padding(.top, 10)
                        .padding(.bottom, 5)
                        // Tutamaça basılınca kapatma opsiyonu
                        .onTapGesture {
                            onClose?()
                        }
                    Spacer()
                }
                .background(Color(uiColor: .systemBackground))
                
                // Ana TabView
                TabView(selection: $selectedTab) {
                    
                    // 1. HİSSELER
                    PortfolioLayout(title: "Hisseler", themeColor: AppTheme.stockColor, totalValue: totalStockValue, selectedCurrency: $selectedCurrency, exchangeRates: $exchangeRates, isCurrencyBusy: $isCurrencyBusy, isRefreshing: isRefreshingStock, onRefresh: refreshStocks, onAdd: { showStockAdder = true }) {
                        StockListView(stocks: stocks, currency: selectedCurrency, rates: exchangeRates, themeColor: AppTheme.stockColor, onRefresh: refreshStocks, onDeleteRequest: { item in
                            activeCategory = .stock
                            handleDelete(message: "'\(item.symbol)' silindi!", type: .stock(symbol: item.symbol, quantity: item.quantity, price: item.currentPrice), itemToDelete: item)
                        })
                    }
                    .sheet(isPresented: $showStockAdder) {
                        StockAdderScreen(themeColor: AppTheme.stockColor)
                            .presentationDetents([.fraction(0.6), .large])
                    }
                    .tabItem { Label("Hisse", systemImage: "chart.bar.xaxis") }.tag(0)
                    
                    // 2. KRİPTOLAR
                    PortfolioLayout(title: "Kripto Varlıklar", themeColor: AppTheme.cryptoColor, totalValue: totalCryptoValue, selectedCurrency: $selectedCurrency, exchangeRates: $exchangeRates, isCurrencyBusy: $isCurrencyBusy, isRefreshing: isRefreshingCrypto, onRefresh: refreshCryptos, onAdd: { showCryptoAdder = true }) {
                        CryptoListView(cryptos: cryptos, currency: selectedCurrency, rates: exchangeRates, themeColor: AppTheme.cryptoColor, onRefresh: refreshCryptos, onDeleteRequest: { item in
                            activeCategory = .crypto
                            handleDelete(message: "'\(item.symbol)' silindi!", type: .crypto(symbol: item.symbol, quantity: item.quantity, price: item.currentPrice), itemToDelete: item)
                        })
                    }
                    .sheet(isPresented: $showCryptoAdder) {
                        CryptoAdderScreen(themeColor: AppTheme.cryptoColor)
                            .presentationDetents([.fraction(0.6), .large])
                    }
                    .tabItem { Label("Kripto", systemImage: "bitcoinsign.circle") }.tag(1)
                    
                    // 3. FONLAR
                    PortfolioLayout(title: "Yatırım Fonları", themeColor: AppTheme.fundColor, totalValue: totalFundValue, selectedCurrency: $selectedCurrency, exchangeRates: $exchangeRates, isCurrencyBusy: $isCurrencyBusy, isRefreshing: isRefreshingFund, onRefresh: refreshFunds, onAdd: { showFundAdder = true }) {
                        FundListView(funds: funds, currency: selectedCurrency, rates: exchangeRates, themeColor: AppTheme.fundColor, onRefresh: refreshFunds, onDeleteRequest: { item in
                            activeCategory = .fund
                            handleDelete(message: "'\(item.symbol)' silindi!", type: .fund(symbol: item.symbol, quantity: item.quantity, price: item.currentPrice), itemToDelete: item)
                        })
                    }
                    .sheet(isPresented: $showFundAdder) {
                        FundAdderScreen(themeColor: AppTheme.fundColor)
                            .presentationDetents([.fraction(0.6), .large])
                    }
                    .tabItem { Label("Fon", systemImage: "building.columns.circle") }.tag(2)
                    
                    // 4. MADENLER
                    PortfolioLayout(title: "Değerli Madenler", themeColor: AppTheme.elementColor, totalValue: totalElementValue, selectedCurrency: $selectedCurrency, exchangeRates: $exchangeRates, isCurrencyBusy: $isCurrencyBusy, isRefreshing: isRefreshingElement, onRefresh: refreshElements, onAdd: { showElementAdder = true }) {
                        ElementListView(elements: elements, currency: selectedCurrency, rates: exchangeRates, themeColor: AppTheme.elementColor, onRefresh: refreshElements, onDeleteRequest: { item in
                            activeCategory = .element
                            handleDelete(message: "'\(item.displayName)' silindi!", type: .element(symbol: item.symbol, quantity: item.quantity, price: item.currentPrice), itemToDelete: item)
                        })
                    }
                    .sheet(isPresented: $showElementAdder) {
                        ElementAdderScreen(themeColor: AppTheme.elementColor)
                            .presentationDetents([.fraction(0.6), .large])
                    }
                    .tabItem { Label("Maden", systemImage: "circle.hexagonpath.fill") }.tag(3)
                    
                    // 5. NAKİT
                    PortfolioLayout(title: "Nakit Varlıklar", themeColor: AppTheme.cashColor, totalValue: totalCashValue, selectedCurrency: $selectedCurrency, exchangeRates: $exchangeRates, isCurrencyBusy: $isCurrencyBusy, isRefreshing: isRefreshingCash, onRefresh: refreshCash, onAdd: { showCashAdder = true }) {
                        CashListView(cashItems: cashItems, currency: selectedCurrency, rates: exchangeRates, themeColor: AppTheme.cashColor, onRefresh: refreshCash, onDeleteRequest: { item in
                            activeCategory = .cash
                            handleDelete(message: "'\(item.displayName)' silindi!", type: .cash(symbol: item.symbol, quantity: item.quantity, price: item.currentPrice), itemToDelete: item)
                        })
                    }
                    .sheet(isPresented: $showCashAdder) {
                        CashAdderScreen(themeColor: AppTheme.cashColor)
                            .presentationDetents([.fraction(0.6), .large])
                    }
                    .tabItem { Label("Nakit", systemImage: "banknote") }.tag(4)
                }
                .tint(currentTabColor)
            }
            
            // TOAST MESAJI
            if showToast {
                FancyToastView(
                    message: toastMessage,
                    themeColor: AppTheme.color(for: activeCategory),
                    timeLeft: timeLeft,
                    onUndo: undoDelete
                )
                .padding(.bottom, 100)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .opacity
                ))
                .zIndex(100)
            }
        }
        .onChange(of: selectedCurrency) { _, n in
            if n != .tryCurrency && exchangeRates == (1.0, 1.0) {
                Task {
                    isCurrencyBusy = true
                    if let r = await currencyService.fetchRates() { exchangeRates = r }
                    isCurrencyBusy = false
                }
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
    
    // MARK: - API REFRESH FONKSİYONLARI
    func refreshStocks() async { isRefreshingStock = true; for s in stocks { if let p = await apiService.fetchStockPrice(symbol: s.symbol) { s.currentPrice = p } }; try? context.save(); isRefreshingStock = false }
    func refreshCryptos() async { isRefreshingCrypto = true; for c in cryptos { if let p = await apiService.fetchCryptoPrice(symbol: c.symbol) { c.currentPrice = p } }; try? context.save(); isRefreshingCrypto = false }
    func refreshFunds() async { isRefreshingFund = true; for f in funds { if let p = await apiService.fetchFundPrice(symbol: f.symbol) { f.currentPrice = p } }; try? context.save(); isRefreshingFund = false }
    func refreshElements() async { isRefreshingElement = true; for e in elements { if let p = await apiService.fetchElementPrice(symbol: e.symbol) { e.currentPrice = p } }; try? context.save(); isRefreshingElement = false }
    func refreshCash() async { isRefreshingCash = true; if let rates = await currencyService.fetchRates() { exchangeRates = rates; for item in cashItems { if item.symbol == "USD" { item.currentPrice = rates.usd } else if item.symbol == "EUR" { item.currentPrice = rates.eur } else { item.currentPrice = 1.0 } }; try? context.save() }; isRefreshingCash = false }
    
    // MARK: - DELETE & UNDO
    func handleDelete<T: PersistentModel>(message: String, type: DeletedItemWrapper, itemToDelete: T) {
        undoTimer?.invalidate()
        deletedItemBackup = type
        context.delete(itemToDelete)
        
        // Mesajı Set Et
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
        case .stock(let s, let q, let p): context.insert(Stock(symbol: s, quantity: q, currentPrice: p))
        case .crypto(let s, let q, let p): context.insert(Crypto(symbol: s, quantity: q, currentPrice: p))
        case .fund(let s, let q, let p): context.insert(Fund(symbol: s, quantity: q, currentPrice: p))
        case .element(let s, let q, let p): context.insert(Element(symbol: s, quantity: q, currentPrice: p))
        case .cash(let s, let q, let p): context.insert(Cash(symbol: s, quantity: q, currentPrice: p))
        }
        withAnimation { showToast = false }
        deletedItemBackup = nil
    }
}

// MARK: - 4. LİSTE GÖRÜNÜMLERİ (FULL)

struct StockListView: View {
    var stocks: [Stock]; var currency: Currency; var rates: (usd: Double, eur: Double); var themeColor: Color; var onRefresh: () async -> Void; var onDeleteRequest: (Stock) -> Void
    @State private var itemToUpdate: Stock?
    func convert(_ value: Double) -> Double { switch currency { case .tryCurrency: return value; case .usd: return value / (rates.usd > 0 ? rates.usd : 1); case .eur: return value / (rates.eur > 0 ? rates.eur : 1) } }
    
    var body: some View {
        List {
            ForEach(stocks) { stock in
                HStack {
                    VStack(alignment: .leading) { Text(stock.symbol).font(.headline).bold(); Text("\(stock.quantity, specifier: "%.0f") adet").font(.caption).foregroundStyle(.gray) }
                    Spacer()
                    VStack(alignment: .trailing) { Text("\(convert(stock.totalValue), specifier: "%.2f") \(currency.rawValue)").bold(); Text("\(convert(stock.currentPrice), specifier: "%.2f") \(currency.rawValue)").font(.caption).foregroundStyle(.secondary) }
                }
                .padding(.vertical, 4)
                .listRowBackground(Rectangle().fill(Color(uiColor: .secondarySystemGroupedBackground)))
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) { onDeleteRequest(stock) } label: { Label("Sil", systemImage: "trash") }.tint(.red)
                    Button { itemToUpdate = stock } label: { Label("Güncelle", systemImage: "pencil") }.tint(themeColor)
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable { await onRefresh() }
        .sheet(item: $itemToUpdate) { stock in StandardUpdateSheet(title: stock.symbol, currentQuantity: stock.quantity, themeColor: themeColor) { newQty in stock.quantity = newQty } }
    }
}

struct CryptoListView: View {
    var cryptos: [Crypto]; var currency: Currency; var rates: (usd: Double, eur: Double); var themeColor: Color; var onRefresh: () async -> Void; var onDeleteRequest: (Crypto) -> Void
    @State private var itemToUpdate: Crypto?
    func convert(_ value: Double) -> Double { switch currency { case .tryCurrency: return value; case .usd: return value / (rates.usd > 0 ? rates.usd : 1); case .eur: return value / (rates.eur > 0 ? rates.eur : 1) } }
    
    var body: some View {
        List {
            ForEach(cryptos) { crypto in
                HStack {
                    VStack(alignment: .leading) { Text(crypto.symbol).font(.headline).bold(); Text("\(crypto.quantity, specifier: "%.4f") adet").font(.caption).foregroundStyle(.gray) }
                    Spacer()
                    VStack(alignment: .trailing) { Text("\(convert(crypto.totalValue), specifier: "%.2f") \(currency.rawValue)").bold(); Text("\(convert(crypto.currentPrice), specifier: "%.2f") \(currency.rawValue)").font(.caption).foregroundStyle(.secondary) }
                }
                .padding(.vertical, 4)
                .listRowBackground(Rectangle().fill(Color(uiColor: .secondarySystemGroupedBackground)))
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) { onDeleteRequest(crypto) } label: { Label("Sil", systemImage: "trash") }.tint(.red)
                    Button { itemToUpdate = crypto } label: { Label("Güncelle", systemImage: "pencil") }.tint(themeColor)
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable { await onRefresh() }
        .sheet(item: $itemToUpdate) { crypto in StandardUpdateSheet(title: crypto.symbol, currentQuantity: crypto.quantity, themeColor: themeColor) { newQty in crypto.quantity = newQty } }
    }
}

struct FundListView: View {
    var funds: [Fund]; var currency: Currency; var rates: (usd: Double, eur: Double); var themeColor: Color; var onRefresh: () async -> Void; var onDeleteRequest: (Fund) -> Void
    @State private var itemToUpdate: Fund?
    func convert(_ value: Double) -> Double { switch currency { case .tryCurrency: return value; case .usd: return value / (rates.usd > 0 ? rates.usd : 1); case .eur: return value / (rates.eur > 0 ? rates.eur : 1) } }
    
    var body: some View {
        List {
            ForEach(funds) { fund in
                HStack {
                    VStack(alignment: .leading) { Text(fund.symbol).font(.headline).bold(); Text("\(fund.quantity, specifier: "%.0f") adet").font(.caption).foregroundStyle(.gray) }
                    Spacer()
                    VStack(alignment: .trailing) { Text("\(convert(fund.totalValue), specifier: "%.2f") \(currency.rawValue)").bold(); Text("\(convert(fund.currentPrice), specifier: "%.4f") \(currency.rawValue)").font(.caption).foregroundStyle(.secondary) }
                }
                .padding(.vertical, 4)
                .listRowBackground(Rectangle().fill(Color(uiColor: .secondarySystemGroupedBackground)))
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) { onDeleteRequest(fund) } label: { Label("Sil", systemImage: "trash") }.tint(.red)
                    Button { itemToUpdate = fund } label: { Label("Güncelle", systemImage: "pencil") }.tint(themeColor)
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable { await onRefresh() }
        .sheet(item: $itemToUpdate) { fund in StandardUpdateSheet(title: fund.symbol, currentQuantity: fund.quantity, themeColor: themeColor) { newQty in fund.quantity = newQty } }
    }
}

struct ElementListView: View {
    var elements: [Element]; var currency: Currency; var rates: (usd: Double, eur: Double); var themeColor: Color; var onRefresh: () async -> Void; var onDeleteRequest: (Element) -> Void
    @State private var itemToUpdate: Element?
    func convert(_ value: Double) -> Double { switch currency { case .tryCurrency: return value; case .usd: return value / (rates.usd > 0 ? rates.usd : 1); case .eur: return value / (rates.eur > 0 ? rates.eur : 1) } }
    
    var body: some View {
        List {
            ForEach(elements) { element in
                HStack {
                    VStack(alignment: .leading) { Text(element.displayName).font(.headline).bold(); Text("\(element.quantity, specifier: "%.2f") Gr").font(.caption).foregroundStyle(.gray) }
                    Spacer()
                    VStack(alignment: .trailing) { Text("\(convert(element.totalValue), specifier: "%.2f") \(currency.rawValue)").bold(); Text("\(convert(element.currentPrice), specifier: "%.2f") \(currency.rawValue)").font(.caption).foregroundStyle(.secondary) }
                }
                .padding(.vertical, 4)
                .listRowBackground(Rectangle().fill(Color(uiColor: .secondarySystemGroupedBackground)))
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) { onDeleteRequest(element) } label: { Label("Sil", systemImage: "trash") }.tint(.red)
                    Button { itemToUpdate = element } label: { Label("Güncelle", systemImage: "pencil") }.tint(themeColor)
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable { await onRefresh() }
        .sheet(item: $itemToUpdate) { element in StandardUpdateSheet(title: element.displayName, currentQuantity: element.quantity, themeColor: themeColor) { newQty in element.quantity = newQty } }
    }
}

struct CashListView: View {
    var cashItems: [Cash]; var currency: Currency; var rates: (usd: Double, eur: Double); var themeColor: Color; var onRefresh: () async -> Void; var onDeleteRequest: (Cash) -> Void
    @State private var itemToUpdate: Cash?
    func convert(_ value: Double) -> Double { switch currency { case .tryCurrency: return value; case .usd: return value / (rates.usd > 0 ? rates.usd : 1); case .eur: return value / (rates.eur > 0 ? rates.eur : 1) } }
    
    var body: some View {
        List {
            ForEach(cashItems) { item in
                HStack {
                    VStack(alignment: .leading) { Text(item.displayName).font(.headline).bold(); Text("\(item.quantity, specifier: "%.2f")").font(.caption).foregroundStyle(.gray) }
                    Spacer()
                    VStack(alignment: .trailing) { Text("\(convert(item.totalValue), specifier: "%.2f") \(currency.rawValue)").bold(); if item.symbol != "TRY" { Text("Kur: \(item.currentPrice, specifier: "%.2f") ₺").font(.caption).foregroundStyle(.secondary) } }
                }
                .padding(.vertical, 4)
                .listRowBackground(Rectangle().fill(Color(uiColor: .secondarySystemGroupedBackground)))
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) { onDeleteRequest(item) } label: { Label("Sil", systemImage: "trash") }.tint(.red)
                    Button { itemToUpdate = item } label: { Label("Güncelle", systemImage: "pencil") }.tint(themeColor)
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable { await onRefresh() }
        .sheet(item: $itemToUpdate) { item in StandardUpdateSheet(title: item.displayName, currentQuantity: item.quantity, themeColor: themeColor) { newQty in item.quantity = newQty } }
    }
}
