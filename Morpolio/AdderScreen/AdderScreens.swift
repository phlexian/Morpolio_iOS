import SwiftUI
import SwiftData

// Focus yönetimi için enum (purchasePrice eklendi)
enum AdderField {
    case symbol
    case quantity
    case purchasePrice
}

// --- 1. HİSSE EKLEME ---
struct StockAdderScreen: View {
    @Environment(\.modelContext) private var context
    var themeColor: Color
    private let api = APIService()
    
    @State private var symbol = ""
    @State private var quantity = ""
    @State private var purchasePriceStr = ""
    
    @State private var isLoading = false
    @State private var errorMsg: String?
    @State private var showDuplicateAlert = false
    @State private var existingItem: Stock?
    @State private var pendingPrice: Double = 0.0
    
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: AdderField?
    
    var isFormValid: Bool { !symbol.isEmpty && !quantity.isEmpty && !purchasePriceStr.isEmpty }

    var body: some View {
        StandardAdderLayout(title: "Hisse Ekle", themeColor: themeColor, isLoading: isLoading, errorMessage: errorMsg, isSaveDisabled: !isFormValid, onSave: { Task { await processAddition() } }) {
            AdderTextField(title: "Hisse Kodu (Örn: THYAO)", text: $symbol, submitLabel: .next) { focusedField = .quantity }
                .focused($focusedField, equals: .symbol)
            
            AdderTextField(title: "Adet", text: $quantity, isNumber: true, submitLabel: .next) { focusedField = .purchasePrice }
                .focused($focusedField, equals: .quantity)
            
            AdderTextField(title: "Alış Fiyatı (Maliyet)", text: $purchasePriceStr, isNumber: true, submitLabel: .done) { focusedField = nil }
                .focused($focusedField, equals: .purchasePrice)
        }
        .alert("Bu Hisse Zaten Var", isPresented: $showDuplicateAlert) {
            Button("İptal", role: .cancel) { }
            Button("Üzerine Ekle") { updateExisting() }
        } message: { Text("Portföyünüzde \(existingItem?.symbol ?? "") bulunuyor. Üzerine eklemek ister misiniz?") }
    }
    
    func processAddition() async {
        errorMsg = nil
        guard let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")),
              let cost = Double(purchasePriceStr.replacingOccurrences(of: ",", with: ".")) else { return }
        
        let searchSymbol = symbol.uppercased()
        isLoading = true
        if let price = await api.fetchStockPrice(symbol: searchSymbol) {
            pendingPrice = price
            let fetchDesc = FetchDescriptor<Stock>(predicate: #Predicate { $0.symbol == searchSymbol })
            if let existing = try? context.fetch(fetchDesc).first { existingItem = existing; showDuplicateAlert = true }
            else { context.insert(Stock(symbol: searchSymbol, quantity: qty, currentPrice: price, purchasePrice: cost)); dismiss() }
        } else { errorMsg = "Hisse bulunamadı." }
        isLoading = false
    }
    
    func updateExisting() {
        guard let item = existingItem,
              let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")),
              let newCost = Double(purchasePriceStr.replacingOccurrences(of: ",", with: ".")) else { return }
        
        let totalOldCost = item.quantity * item.purchasePrice
        let totalNewCost = qty * newCost
        let newTotalQuantity = item.quantity + qty
        
        item.purchasePrice = (totalOldCost + totalNewCost) / newTotalQuantity
        item.quantity = newTotalQuantity
        item.currentPrice = pendingPrice
        dismiss()
    }
}

// --- 2. KRİPTO EKLEME ---
struct CryptoAdderScreen: View {
    @Environment(\.modelContext) private var context
    var themeColor: Color
    private let api = APIService()
    
    @State private var symbol = ""
    @State private var quantity = ""
    @State private var purchasePriceStr = ""
    
    @State private var isLoading = false
    @State private var errorMsg: String?
    @State private var showDuplicateAlert = false
    @State private var existingItem: Crypto?
    @State private var pendingPrice: Double = 0.0
    
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: AdderField?
    
    var isFormValid: Bool { !symbol.isEmpty && !quantity.isEmpty && !purchasePriceStr.isEmpty }

    var body: some View {
        StandardAdderLayout(title: "Kripto Ekle", themeColor: themeColor, isLoading: isLoading, errorMessage: errorMsg, isSaveDisabled: !isFormValid, onSave: { Task { await processAddition() } }) {
            AdderTextField(title: "Sembol (Örn: BTC)", text: $symbol, submitLabel: .next) { focusedField = .quantity }
                .focused($focusedField, equals: .symbol)
            
            AdderTextField(title: "Adet", text: $quantity, isNumber: true, submitLabel: .next) { focusedField = .purchasePrice }
                .focused($focusedField, equals: .quantity)
            
            AdderTextField(title: "Alış Fiyatı (Maliyet)", text: $purchasePriceStr, isNumber: true, submitLabel: .done) { focusedField = nil }
                .focused($focusedField, equals: .purchasePrice)
        }
        .alert("Bu Varlık Zaten Var", isPresented: $showDuplicateAlert) {
            Button("İptal", role: .cancel) { }
            Button("Üzerine Ekle") { updateExisting() }
        } message: { Text("Portföyünüzde mevcut. Üzerine eklensin mi?") }
    }
    
    func processAddition() async {
        errorMsg = nil
        guard let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")),
              let cost = Double(purchasePriceStr.replacingOccurrences(of: ",", with: ".")) else { return }
        
        let searchSymbol = symbol.uppercased()
        isLoading = true
        if let price = await api.fetchCryptoPrice(symbol: searchSymbol) {
            pendingPrice = price
            let fetchDesc = FetchDescriptor<Crypto>(predicate: #Predicate { $0.symbol == searchSymbol })
            if let existing = try? context.fetch(fetchDesc).first { existingItem = existing; showDuplicateAlert = true }
            else { context.insert(Crypto(symbol: searchSymbol, quantity: qty, currentPrice: price, purchasePrice: cost)); dismiss() }
        } else { errorMsg = "Varlık bulunamadı." }
        isLoading = false
    }
    
    func updateExisting() {
        guard let item = existingItem,
              let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")),
              let newCost = Double(purchasePriceStr.replacingOccurrences(of: ",", with: ".")) else { return }
        
        let totalOldCost = item.quantity * item.purchasePrice
        let totalNewCost = qty * newCost
        let newTotalQuantity = item.quantity + qty
        
        item.purchasePrice = (totalOldCost + totalNewCost) / newTotalQuantity
        item.quantity = newTotalQuantity
        item.currentPrice = pendingPrice
        dismiss()
    }
}

// --- 3. FON EKLEME ---
struct FundAdderScreen: View {
    @Environment(\.modelContext) private var context
    var themeColor: Color
    private let api = APIService()
    
    @State private var symbol = ""
    @State private var quantity = ""
    @State private var purchasePriceStr = ""
    
    @State private var isLoading = false
    @State private var errorMsg: String?
    @State private var showDuplicateAlert = false
    @State private var existingItem: Fund?
    @State private var pendingPrice: Double = 0.0
    
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: AdderField?
    
    var isFormValid: Bool { !symbol.isEmpty && !quantity.isEmpty && !purchasePriceStr.isEmpty }

    var body: some View {
        StandardAdderLayout(title: "Fon Ekle", themeColor: themeColor, isLoading: isLoading, errorMessage: errorMsg, isSaveDisabled: !isFormValid, onSave: { Task { await processAddition() } }) {
            AdderTextField(title: "Fon Kodu (Örn: TTE)", text: $symbol, submitLabel: .next) { focusedField = .quantity }
                .focused($focusedField, equals: .symbol)
            
            AdderTextField(title: "Adet", text: $quantity, isNumber: true, submitLabel: .next) { focusedField = .purchasePrice }
                .focused($focusedField, equals: .quantity)
            
            AdderTextField(title: "Alış Fiyatı (Maliyet)", text: $purchasePriceStr, isNumber: true, submitLabel: .done) { focusedField = nil }
                .focused($focusedField, equals: .purchasePrice)
        }
        .alert("Bu Fon Zaten Var", isPresented: $showDuplicateAlert) {
            Button("İptal", role: .cancel) { }
            Button("Üzerine Ekle") { updateExisting() }
        } message: { Text("Portföyünüzde mevcut. Üzerine eklensin mi?") }
    }
    
    func processAddition() async {
        errorMsg = nil
        guard let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")),
              let cost = Double(purchasePriceStr.replacingOccurrences(of: ",", with: ".")) else { return }
        
        let searchSymbol = symbol.uppercased()
        isLoading = true
        if let price = await api.fetchFundPrice(symbol: searchSymbol) {
            pendingPrice = price
            let fetchDesc = FetchDescriptor<Fund>(predicate: #Predicate { $0.symbol == searchSymbol })
            if let existing = try? context.fetch(fetchDesc).first { existingItem = existing; showDuplicateAlert = true }
            else { context.insert(Fund(symbol: searchSymbol, quantity: qty, currentPrice: price, purchasePrice: cost)); dismiss() }
        } else { errorMsg = "Fon bulunamadı." }
        isLoading = false
    }
    
    func updateExisting() {
        guard let item = existingItem,
              let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")),
              let newCost = Double(purchasePriceStr.replacingOccurrences(of: ",", with: ".")) else { return }
        
        let totalOldCost = item.quantity * item.purchasePrice
        let totalNewCost = qty * newCost
        let newTotalQuantity = item.quantity + qty
        
        item.purchasePrice = (totalOldCost + totalNewCost) / newTotalQuantity
        item.quantity = newTotalQuantity
        item.currentPrice = pendingPrice
        dismiss()
    }
}

// --- 4. MADEN EKLEME ---
struct ElementAdderScreen: View {
    @Environment(\.modelContext) private var context
    var themeColor: Color
    private let api = APIService()
    
    @State private var selectedElement = "GLD"
    @State private var quantity = ""
    @State private var purchasePriceStr = ""
    
    @State private var isLoading = false
    @State private var errorMsg: String?
    @State private var showDuplicateAlert = false
    @State private var existingItem: Element?
    @State private var pendingPrice: Double = 0.0
    
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: AdderField?
    
    var isFormValid: Bool { !quantity.isEmpty && !purchasePriceStr.isEmpty }
    let elements = [("GLD", "Altın"), ("SLV", "Gümüş"), ("PLT", "Platin")]

    var body: some View {
        StandardAdderLayout(title: "Maden Ekle", themeColor: themeColor, isLoading: isLoading, errorMessage: errorMsg, isSaveDisabled: !isFormValid, onSave: { Task { await processAddition() } }) {
            CustomSegmentedPicker(options: elements, selection: $selectedElement, color: themeColor)
            
            AdderTextField(title: "Adet (Gram)", text: $quantity, isNumber: true, submitLabel: .next) { focusedField = .purchasePrice }
                .focused($focusedField, equals: .quantity)
            
            AdderTextField(title: "Alış Fiyatı (Gram Maliyeti)", text: $purchasePriceStr, isNumber: true, submitLabel: .done) { focusedField = nil }
                .focused($focusedField, equals: .purchasePrice)
        }
        .alert("Maden Zaten Var", isPresented: $showDuplicateAlert) {
            Button("İptal", role: .cancel) { }
            Button("Üzerine Ekle") { updateExisting() }
        } message: { Text("Mevcut gramajın üzerine eklensin mi?") }
    }
    
    func processAddition() async {
        guard let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")),
              let cost = Double(purchasePriceStr.replacingOccurrences(of: ",", with: ".")) else { return }
        
        isLoading = true
        let searchSymbol = selectedElement
        if let price = await api.fetchElementPrice(symbol: searchSymbol) {
            pendingPrice = price
            let fetchDesc = FetchDescriptor<Element>(predicate: #Predicate { $0.symbol == searchSymbol })
            if let existing = try? context.fetch(fetchDesc).first { existingItem = existing; showDuplicateAlert = true }
            else { context.insert(Element(symbol: searchSymbol, quantity: qty, currentPrice: price, purchasePrice: cost)); dismiss() }
        } else { errorMsg = "Fiyat alınamadı." }
        isLoading = false
    }
    
    func updateExisting() {
        guard let item = existingItem,
              let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")),
              let newCost = Double(purchasePriceStr.replacingOccurrences(of: ",", with: ".")) else { return }
        
        let totalOldCost = item.quantity * item.purchasePrice
        let totalNewCost = qty * newCost
        let newTotalQuantity = item.quantity + qty
        
        item.purchasePrice = (totalOldCost + totalNewCost) / newTotalQuantity
        item.quantity = newTotalQuantity
        item.currentPrice = pendingPrice
        dismiss()
    }
}

// --- 5. NAKİT EKLEME ---
struct CashAdderScreen: View {
    @Environment(\.modelContext) private var context
    var themeColor: Color
    private let currencyApi = CurrencyService()
    
    @State private var selectedCurrency = "TRY"
    @State private var quantity = ""
    @State private var purchasePriceStr = ""
    
    @State private var isLoading = false
    @State private var errorMsg: String?
    @State private var showDuplicateAlert = false
    @State private var existingItem: Cash?
    @State private var pendingPrice: Double = 0.0
    
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: AdderField?
    
    // Eğer TRY seçiliyse alış fiyatı (kuru) girmeye gerek yok
    var isFormValid: Bool {
        if selectedCurrency == "TRY" { return !quantity.isEmpty }
        return !quantity.isEmpty && !purchasePriceStr.isEmpty
    }
    let currencies = [("TRY", "₺"), ("USD", "$"), ("EUR", "€")]

    var body: some View {
        StandardAdderLayout(title: "Nakit Ekle", themeColor: themeColor, isLoading: isLoading, errorMessage: errorMsg, isSaveDisabled: !isFormValid, onSave: { Task { await processAddition() } }) {
            CustomSegmentedPicker(options: currencies, selection: $selectedCurrency, color: themeColor)
            
            AdderTextField(title: "Miktar", text: $quantity, isNumber: true, submitLabel: selectedCurrency == "TRY" ? .done : .next) {
                if selectedCurrency == "TRY" { focusedField = nil } else { focusedField = .purchasePrice }
            }
            .focused($focusedField, equals: .quantity)
            
            // Sadece USD ve EUR için Kur soruyoruz
            if selectedCurrency != "TRY" {
                AdderTextField(title: "Alış Kuru (Maliyeti)", text: $purchasePriceStr, isNumber: true, submitLabel: .done) { focusedField = nil }
                    .focused($focusedField, equals: .purchasePrice)
            }
        }
        .onChange(of: selectedCurrency) { _, newValue in
            // Para birimi değiştiğinde eğer TRY ise purchasePrice alanını temizle
            if newValue == "TRY" { purchasePriceStr = "" }
        }
        .alert("Para Birimi Zaten Var", isPresented: $showDuplicateAlert) {
            Button("İptal", role: .cancel) { }
            Button("Üzerine Ekle") { updateExisting() }
        } message: { Text("Mevcut bakiyenin üzerine eklensin mi?") }
    }
    
    func processAddition() async {
        guard let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")) else { return }
        
        let cost = selectedCurrency == "TRY" ? 1.0 : (Double(purchasePriceStr.replacingOccurrences(of: ",", with: ".")) ?? 1.0)
        
        isLoading = true
        var price = 1.0
        if selectedCurrency != "TRY" {
            if let rates = await currencyApi.fetchRates() { price = (selectedCurrency == "USD") ? rates.usd : rates.eur }
            else { errorMsg = "Kur alınamadı."; isLoading = false; return }
        }
        
        pendingPrice = price
        let searchSymbol = selectedCurrency
        let fetchDesc = FetchDescriptor<Cash>(predicate: #Predicate { $0.symbol == searchSymbol })
        
        if let existing = try? context.fetch(fetchDesc).first { existingItem = existing; showDuplicateAlert = true }
        else { context.insert(Cash(symbol: searchSymbol, quantity: qty, currentPrice: price, purchasePrice: cost)); dismiss() }
        isLoading = false
    }
    
    func updateExisting() {
        guard let item = existingItem,
              let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")),
              let newCost = selectedCurrency == "TRY" ? 1.0 : Double(purchasePriceStr.replacingOccurrences(of: ",", with: ".")) else { return }
        
        let totalOldCost = item.quantity * item.purchasePrice
        let totalNewCost = qty * newCost
        let newTotalQuantity = item.quantity + qty
        
        item.purchasePrice = (totalOldCost + totalNewCost) / newTotalQuantity
        item.quantity = newTotalQuantity
        item.currentPrice = pendingPrice
        dismiss()
    }
}
