import SwiftUI
import SwiftData

// Focus yönetimi için enum
enum AdderField {
    case symbol
    case quantity
}

// --- 1. HİSSE EKLEME ---
struct StockAdderScreen: View {
    @Environment(\.modelContext) private var context
    var themeColor: Color
    private let api = APIService()
    @State private var symbol = ""; @State private var quantity = ""; @State private var isLoading = false; @State private var errorMsg: String?
    @State private var showDuplicateAlert = false; @State private var existingItem: Stock?; @State private var pendingPrice: Double = 0.0
    
    @Environment(\.dismiss) private var dismiss
    
    // YENİ: Focus State
    @FocusState private var focusedField: AdderField?
    
    var isFormValid: Bool { !symbol.isEmpty && !quantity.isEmpty }

    var body: some View {
        StandardAdderLayout(title: "Hisse Ekle", themeColor: themeColor, isLoading: isLoading, errorMessage: errorMsg, isSaveDisabled: !isFormValid, onSave: { Task { await processAddition() } }) {
            
            AdderTextField(title: "Hisse Kodu (Örn: THYAO)", text: $symbol, submitLabel: .next) {
                focusedField = .quantity // Enter basınca alta geç
            }
            .focused($focusedField, equals: .symbol)
            
            AdderTextField(title: "Adet", text: $quantity, isNumber: true, submitLabel: .done) {
                focusedField = nil // Klavye kapat
            }
            .focused($focusedField, equals: .quantity)
        }
        .alert("Bu Hisse Zaten Var", isPresented: $showDuplicateAlert) {
            Button("İptal", role: .cancel) { }
            Button("Üzerine Ekle") { updateExisting() }
        } message: { Text("Portföyünüzde \(existingItem?.symbol ?? "") bulunuyor. Üzerine eklemek ister misiniz?") }
    }
    
    // ... processAddition ve updateExisting aynı (Uppercased dışarıda olacak şekilde) ...
    func processAddition() async {
        errorMsg = nil; guard let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")) else { return }
        let searchSymbol = symbol.uppercased()
        isLoading = true
        if let price = await api.fetchStockPrice(symbol: searchSymbol) {
            pendingPrice = price
            let fetchDesc = FetchDescriptor<Stock>(predicate: #Predicate { $0.symbol == searchSymbol })
            if let existing = try? context.fetch(fetchDesc).first { existingItem = existing; showDuplicateAlert = true }
            else { context.insert(Stock(symbol: searchSymbol, quantity: qty, currentPrice: price)); dismiss() }
        } else { errorMsg = "Hisse bulunamadı." }; isLoading = false
    }
    func updateExisting() {
        guard let item = existingItem, let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")) else { return }
        item.quantity += qty; item.currentPrice = pendingPrice; dismiss()
    }
}

// --- 2. KRİPTO EKLEME ---
struct CryptoAdderScreen: View {
    @Environment(\.modelContext) private var context
    var themeColor: Color
    private let api = APIService()
    @State private var symbol = ""; @State private var quantity = ""; @State private var isLoading = false; @State private var errorMsg: String?
    @State private var showDuplicateAlert = false; @State private var existingItem: Crypto?; @State private var pendingPrice: Double = 0.0
    @Environment(\.dismiss) private var dismiss
    
    @FocusState private var focusedField: AdderField?
    var isFormValid: Bool { !symbol.isEmpty && !quantity.isEmpty }

    var body: some View {
        StandardAdderLayout(title: "Kripto Ekle", themeColor: themeColor, isLoading: isLoading, errorMessage: errorMsg, isSaveDisabled: !isFormValid, onSave: { Task { await processAddition() } }) {
            AdderTextField(title: "Sembol (Örn: BTC)", text: $symbol, submitLabel: .next) { focusedField = .quantity }
                .focused($focusedField, equals: .symbol)
            AdderTextField(title: "Adet", text: $quantity, isNumber: true, submitLabel: .done) { focusedField = nil }
                .focused($focusedField, equals: .quantity)
        }
        .alert("Bu Varlık Zaten Var", isPresented: $showDuplicateAlert) { Button("İptal", role: .cancel) { }; Button("Üzerine Ekle") { updateExisting() } } message: { Text("Portföyünüzde mevcut. Üzerine eklensin mi?") }
    }
    
    func processAddition() async {
        errorMsg = nil; guard let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")) else { return }
        let searchSymbol = symbol.uppercased()
        isLoading = true
        if let price = await api.fetchCryptoPrice(symbol: searchSymbol) {
            pendingPrice = price
            let fetchDesc = FetchDescriptor<Crypto>(predicate: #Predicate { $0.symbol == searchSymbol })
            if let existing = try? context.fetch(fetchDesc).first { existingItem = existing; showDuplicateAlert = true }
            else { context.insert(Crypto(symbol: searchSymbol, quantity: qty, currentPrice: price)); dismiss() }
        } else { errorMsg = "Varlık bulunamadı." }; isLoading = false
    }
    func updateExisting() { guard let item = existingItem, let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")) else { return }; item.quantity += qty; item.currentPrice = pendingPrice; dismiss() }
}

// --- 3. FON EKLEME ---
struct FundAdderScreen: View {
    @Environment(\.modelContext) private var context
    var themeColor: Color
    private let api = APIService()
    @State private var symbol = ""; @State private var quantity = ""; @State private var isLoading = false; @State private var errorMsg: String?
    @State private var showDuplicateAlert = false; @State private var existingItem: Fund?; @State private var pendingPrice: Double = 0.0
    @Environment(\.dismiss) private var dismiss
    
    @FocusState private var focusedField: AdderField?
    var isFormValid: Bool { !symbol.isEmpty && !quantity.isEmpty }

    var body: some View {
        StandardAdderLayout(title: "Fon Ekle", themeColor: themeColor, isLoading: isLoading, errorMessage: errorMsg, isSaveDisabled: !isFormValid, onSave: { Task { await processAddition() } }) {
            AdderTextField(title: "Fon Kodu (Örn: TTE)", text: $symbol, submitLabel: .next) { focusedField = .quantity }
                .focused($focusedField, equals: .symbol)
            AdderTextField(title: "Adet", text: $quantity, isNumber: true, submitLabel: .done) { focusedField = nil }
                .focused($focusedField, equals: .quantity)
        }
        .alert("Bu Fon Zaten Var", isPresented: $showDuplicateAlert) { Button("İptal", role: .cancel) { }; Button("Üzerine Ekle") { updateExisting() } } message: { Text("Portföyünüzde mevcut. Üzerine eklensin mi?") }
    }
    
    func processAddition() async {
        errorMsg = nil; guard let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")) else { return }
        let searchSymbol = symbol.uppercased()
        isLoading = true
        if let price = await api.fetchFundPrice(symbol: searchSymbol) {
            pendingPrice = price
            let fetchDesc = FetchDescriptor<Fund>(predicate: #Predicate { $0.symbol == searchSymbol })
            if let existing = try? context.fetch(fetchDesc).first { existingItem = existing; showDuplicateAlert = true }
            else { context.insert(Fund(symbol: searchSymbol, quantity: qty, currentPrice: price)); dismiss() }
        } else { errorMsg = "Fon bulunamadı." }; isLoading = false
    }
    func updateExisting() { guard let item = existingItem, let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")) else { return }; item.quantity += qty; item.currentPrice = pendingPrice; dismiss() }
}

// --- 4. MADEN EKLEME ---
struct ElementAdderScreen: View {
    @Environment(\.modelContext) private var context
    var themeColor: Color
    private let api = APIService()
    @State private var selectedElement = "GLD"; @State private var quantity = ""; @State private var isLoading = false; @State private var errorMsg: String?
    @State private var showDuplicateAlert = false; @State private var existingItem: Element?; @State private var pendingPrice: Double = 0.0
    @Environment(\.dismiss) private var dismiss
    
    @FocusState private var focusedField: AdderField?
    var isFormValid: Bool { !quantity.isEmpty }
    let elements = [("GLD", "Altın"), ("SLV", "Gümüş"), ("PLT", "Platin")]

    var body: some View {
        StandardAdderLayout(title: "Maden Ekle", themeColor: themeColor, isLoading: isLoading, errorMessage: errorMsg, isSaveDisabled: !isFormValid, onSave: { Task { await processAddition() } }) {
            CustomSegmentedPicker(options: elements, selection: $selectedElement, color: themeColor)
            AdderTextField(title: "Adet (Gram)", text: $quantity, isNumber: true, submitLabel: .done) { focusedField = nil }
                .focused($focusedField, equals: .quantity)
        }
        .alert("Maden Zaten Var", isPresented: $showDuplicateAlert) { Button("İptal", role: .cancel) { }; Button("Üzerine Ekle") { updateExisting() } } message: { Text("Mevcut gramajın üzerine eklensin mi?") }
    }
    
    func processAddition() async {
        guard let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")) else { return }
        isLoading = true
        let searchSymbol = selectedElement
        if let price = await api.fetchElementPrice(symbol: searchSymbol) {
            pendingPrice = price
            let fetchDesc = FetchDescriptor<Element>(predicate: #Predicate { $0.symbol == searchSymbol })
            if let existing = try? context.fetch(fetchDesc).first { existingItem = existing; showDuplicateAlert = true }
            else { context.insert(Element(symbol: searchSymbol, quantity: qty, currentPrice: price)); dismiss() }
        } else { errorMsg = "Fiyat alınamadı." }; isLoading = false
    }
    func updateExisting() { guard let item = existingItem, let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")) else { return }; item.quantity += qty; item.currentPrice = pendingPrice; dismiss() }
}

// --- 5. NAKİT EKLEME ---
struct CashAdderScreen: View {
    @Environment(\.modelContext) private var context
    var themeColor: Color
    private let currencyApi = CurrencyService()
    @State private var selectedCurrency = "TRY"; @State private var quantity = ""; @State private var isLoading = false; @State private var errorMsg: String?
    @State private var showDuplicateAlert = false; @State private var existingItem: Cash?; @State private var pendingPrice: Double = 0.0
    @Environment(\.dismiss) private var dismiss
    
    @FocusState private var focusedField: AdderField?
    var isFormValid: Bool { !quantity.isEmpty }
    let currencies = [("TRY", "₺"), ("USD", "$"), ("EUR", "€")]

    var body: some View {
        StandardAdderLayout(title: "Nakit Ekle", themeColor: themeColor, isLoading: isLoading, errorMessage: errorMsg, isSaveDisabled: !isFormValid, onSave: { Task { await processAddition() } }) {
            CustomSegmentedPicker(options: currencies, selection: $selectedCurrency, color: themeColor)
            AdderTextField(title: "Miktar", text: $quantity, isNumber: true, submitLabel: .done) { focusedField = nil }
                .focused($focusedField, equals: .quantity)
        }
        .alert("Para Birimi Zaten Var", isPresented: $showDuplicateAlert) { Button("İptal", role: .cancel) { }; Button("Üzerine Ekle") { updateExisting() } } message: { Text("Mevcut bakiyenin üzerine eklensin mi?") }
    }
    
    func processAddition() async {
        guard let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")) else { return }
        isLoading = true; var price = 1.0
        if selectedCurrency != "TRY" {
            if let rates = await currencyApi.fetchRates() { price = (selectedCurrency == "USD") ? rates.usd : rates.eur }
            else { errorMsg = "Kur alınamadı."; isLoading = false; return }
        }
        pendingPrice = price
        let searchSymbol = selectedCurrency
        let fetchDesc = FetchDescriptor<Cash>(predicate: #Predicate { $0.symbol == searchSymbol })
        if let existing = try? context.fetch(fetchDesc).first { existingItem = existing; showDuplicateAlert = true }
        else { context.insert(Cash(symbol: searchSymbol, quantity: qty, currentPrice: price)); dismiss() }
        isLoading = false
    }
    func updateExisting() { guard let item = existingItem, let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")) else { return }; item.quantity += qty; item.currentPrice = pendingPrice; dismiss() }
}
