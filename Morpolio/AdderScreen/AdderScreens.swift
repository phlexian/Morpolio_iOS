import SwiftUI
import SwiftData

// Focus yönetimi için enum (Alış Fiyatı eklendi)
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
            
            AdderTextField(title: "Hisse Kodu (Örn: THYAO)", text: $symbol, submitLabel: .next) {
                focusedField = .quantity
            }
            .focused($focusedField, equals: .symbol)
            
            AdderTextField(title: "Adet", text: $quantity, isNumber: true, submitLabel: .next) {
                focusedField = .purchasePrice
            }
            .focused($focusedField, equals: .quantity)
            
            AdderTextField(title: "Alış Fiyatı (Maliyet)", text: $purchasePriceStr, isNumber: true, submitLabel: .done) {
                focusedField = nil
            }
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
            if let existing = try? context.fetch(fetchDesc).first {
                existingItem = existing
                showDuplicateAlert = true
            } else {
                context.insert(Stock(symbol: searchSymbol, quantity: qty, currentPrice: price, purchasePrice: cost))
                try? context.save() // HATA ÇÖZÜMÜ: Ekleme sonrası veritabanını zorla kaydet
                dismiss()
            }
        } else { errorMsg = "Hisse bulunamadı." }
        isLoading = false
    }
    
    func updateExisting() {
        guard let item = existingItem,
              let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")),
              let cost = Double(purchasePriceStr.replacingOccurrences(of: ",", with: ".")) else { return }
        
        let totalOldCost = item.quantity * item.purchasePrice
        let totalNewCost = qty * cost
        let newTotalQuantity = item.quantity + qty
        
        item.purchasePrice = (totalOldCost + totalNewCost) / newTotalQuantity
        item.quantity = newTotalQuantity
        item.currentPrice = pendingPrice
        
        try? context.save() // HATA ÇÖZÜMÜ: Güncelleme sonrası veritabanını zorla kaydet
        dismiss()
    }
}

// --- 2. KRİPTO EKLEME ---
struct CryptoAdderScreen: View {
    @Environment(\.modelContext) private var context
    var themeColor: Color
    private let api = APIService()
    private let currencyApi = CurrencyService()
    
    @State private var symbol = ""
    @State private var quantity = ""
    @State private var purchasePriceStr = ""
    @State private var selectedCostCurrency = "₺"
    
    @State private var isLoading = false
    @State private var errorMsg: String?
    @State private var showDuplicateAlert = false
    @State private var existingItem: Crypto?
    
    @State private var pendingPrice: Double = 0.0
    @State private var pendingCostInTRY: Double = 0.0
    @State private var pendingOriginalCost: Double = 0.0
    
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: AdderField?
    
    var isFormValid: Bool { !symbol.isEmpty && !quantity.isEmpty && !purchasePriceStr.isEmpty }

    var body: some View {
        StandardAdderLayout(title: "Kripto Ekle", themeColor: themeColor, isLoading: isLoading, errorMessage: errorMsg, isSaveDisabled: !isFormValid, onSave: { Task { await processAddition() } }) {
            AdderTextField(title: "Sembol (Örn: BTC)", text: $symbol, submitLabel: .next) { focusedField = .quantity }
                .focused($focusedField, equals: .symbol)
            
            AdderTextField(title: "Adet", text: $quantity, isNumber: true, submitLabel: .next) { focusedField = .purchasePrice }
                .focused($focusedField, equals: .quantity)
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Alış Fiyatı (Maliyet)").font(.caption).foregroundStyle(.secondary)
                
                HStack(spacing: 12) {
                    TextField("", text: $purchasePriceStr)
                        .keyboardType(.numbersAndPunctuation)
                        .submitLabel(.done)
                        .onSubmit { focusedField = nil }
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                        .focused($focusedField, equals: .purchasePrice)
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            if selectedCostCurrency == "₺" { selectedCostCurrency = "$" }
                            else if selectedCostCurrency == "$" { selectedCostCurrency = "€" }
                            else { selectedCostCurrency = "₺" }
                        }
                    }) {
                        Text(selectedCostCurrency)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(width: 54, height: 54)
                            .background(themeColor)
                            .clipShape(Circle())
                            .shadow(color: themeColor.opacity(0.4), radius: 4, x: 0, y: 2)
                    }
                }
            }
        }
        .alert("Bu Varlık Zaten Var", isPresented: $showDuplicateAlert) {
            Button("İptal", role: .cancel) { }
            Button("Üzerine Ekle") { updateExisting() }
        } message: { Text("Portföyünüzde mevcut. Üzerine eklensin mi?") }
    }
    
    func processAddition() async {
        errorMsg = nil
        guard let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")),
              let enteredCost = Double(purchasePriceStr.replacingOccurrences(of: ",", with: ".")) else { return }
        
        isLoading = true
        var finalCostInTRY = enteredCost
        if selectedCostCurrency != "₺" {
            if let rates = await currencyApi.fetchRates() {
                let multiplier = selectedCostCurrency == "$" ? rates.usd : rates.eur
                finalCostInTRY = enteredCost * multiplier
            } else { errorMsg = "Kur bilgisi alınamadı."; isLoading = false; return }
        }
        
        pendingCostInTRY = finalCostInTRY
        pendingOriginalCost = enteredCost
        
        let searchSymbol = symbol.uppercased()
        if let price = await api.fetchCryptoPrice(symbol: searchSymbol) {
            pendingPrice = price
            let fetchDesc = FetchDescriptor<Crypto>(predicate: #Predicate { $0.symbol == searchSymbol })
            
            if let existing = try? context.fetch(fetchDesc).first {
                existingItem = existing
                showDuplicateAlert = true
            } else {
                context.insert(Crypto(symbol: searchSymbol, quantity: qty, currentPrice: price, purchasePrice: finalCostInTRY, originalPurchasePrice: enteredCost, purchaseCurrency: selectedCostCurrency))
                try? context.save() // HATA ÇÖZÜMÜ
                dismiss()
            }
        } else { errorMsg = "Varlık bulunamadı." }
        isLoading = false
    }
    
    func updateExisting() {
        guard let item = existingItem, let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")) else { return }
        
        let totalOldCost = item.quantity * item.purchasePrice
        let totalNewCost = qty * pendingCostInTRY
        let newTotalQuantity = item.quantity + qty
        item.purchasePrice = (totalOldCost + totalNewCost) / newTotalQuantity
        
        let totalOldOriginal = item.quantity * item.originalPurchasePrice
        let totalNewOriginal = qty * pendingOriginalCost
        item.originalPurchasePrice = (totalOldOriginal + totalNewOriginal) / newTotalQuantity
        item.purchaseCurrency = selectedCostCurrency
        
        item.quantity = newTotalQuantity
        item.currentPrice = pendingPrice
        
        try? context.save() // HATA ÇÖZÜMÜ
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
            if let existing = try? context.fetch(fetchDesc).first {
                existingItem = existing
                showDuplicateAlert = true
            } else {
                context.insert(Fund(symbol: searchSymbol, quantity: qty, currentPrice: price, purchasePrice: cost))
                try? context.save() // HATA ÇÖZÜMÜ
                dismiss()
            }
        } else { errorMsg = "Fon bulunamadı." }
        isLoading = false
    }
    
    func updateExisting() {
        guard let item = existingItem,
              let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")),
              let cost = Double(purchasePriceStr.replacingOccurrences(of: ",", with: ".")) else { return }
        
        let totalOldCost = item.quantity * item.purchasePrice
        let totalNewCost = qty * cost
        let newTotalQuantity = item.quantity + qty
        
        item.purchasePrice = (totalOldCost + totalNewCost) / newTotalQuantity
        item.quantity = newTotalQuantity
        item.currentPrice = pendingPrice
        
        try? context.save() // HATA ÇÖZÜMÜ
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
        errorMsg = nil
        guard let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")),
              let cost = Double(purchasePriceStr.replacingOccurrences(of: ",", with: ".")) else { return }
        
        isLoading = true
        let searchSymbol = selectedElement
        if let price = await api.fetchElementPrice(symbol: searchSymbol) {
            pendingPrice = price
            let fetchDesc = FetchDescriptor<Element>(predicate: #Predicate { $0.symbol == searchSymbol })
            if let existing = try? context.fetch(fetchDesc).first {
                existingItem = existing
                showDuplicateAlert = true
            } else {
                context.insert(Element(symbol: searchSymbol, quantity: qty, currentPrice: price, purchasePrice: cost))
                try? context.save() // HATA ÇÖZÜMÜ
                dismiss()
            }
        } else { errorMsg = "Fiyat alınamadı." }
        isLoading = false
    }
    
    func updateExisting() {
        guard let item = existingItem,
              let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")),
              let cost = Double(purchasePriceStr.replacingOccurrences(of: ",", with: ".")) else { return }
        
        let totalOldCost = item.quantity * item.purchasePrice
        let totalNewCost = qty * cost
        let newTotalQuantity = item.quantity + qty
        
        item.purchasePrice = (totalOldCost + totalNewCost) / newTotalQuantity
        item.quantity = newTotalQuantity
        item.currentPrice = pendingPrice
        
        try? context.save() // HATA ÇÖZÜMÜ
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
    
    var isFormValid: Bool {
        if selectedCurrency == "TRY" { return !quantity.isEmpty }
        return !quantity.isEmpty && !purchasePriceStr.isEmpty
    }
    
    let currencies = [("TRY", "₺"), ("USD", "$"), ("EUR", "€")]

    var body: some View {
        StandardAdderLayout(title: "Nakit Ekle", themeColor: themeColor, isLoading: isLoading, errorMessage: errorMsg, isSaveDisabled: !isFormValid, onSave: { Task { await processAddition() } }) {
            CustomSegmentedPicker(options: currencies, selection: $selectedCurrency, color: themeColor)
            
            AdderTextField(title: "Miktar", text: $quantity, isNumber: true, submitLabel: selectedCurrency == "TRY" ? .done : .next) {
                if selectedCurrency == "TRY" { focusedField = nil }
                else { focusedField = .purchasePrice }
            }
            .focused($focusedField, equals: .quantity)
            
            // Yalnızca döviz eklenecekse kur maliyeti istiyoruz
            if selectedCurrency != "TRY" {
                AdderTextField(title: "Alış Kuru (Maliyet)", text: $purchasePriceStr, isNumber: true, submitLabel: .done) { focusedField = nil }
                    .focused($focusedField, equals: .purchasePrice)
            }
        }
        .alert("Para Birimi Zaten Var", isPresented: $showDuplicateAlert) {
            Button("İptal", role: .cancel) { }
            Button("Üzerine Ekle") { updateExisting() }
        } message: { Text("Mevcut bakiyenin üzerine eklensin mi?") }
    }
    
    func processAddition() async {
        guard let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")) else { return }
        
        let cost: Double
        if selectedCurrency == "TRY" {
            cost = 1.0
        } else {
            guard let c = Double(purchasePriceStr.replacingOccurrences(of: ",", with: ".")) else { return }
            cost = c
        }
        
        isLoading = true
        var price = 1.0
        if selectedCurrency != "TRY" {
            if let rates = await currencyApi.fetchRates() { price = (selectedCurrency == "USD") ? rates.usd : rates.eur }
            else { errorMsg = "Kur alınamadı."; isLoading = false; return }
        }
        
        pendingPrice = price
        let searchSymbol = selectedCurrency
        let fetchDesc = FetchDescriptor<Cash>(predicate: #Predicate { $0.symbol == searchSymbol })
        
        if let existing = try? context.fetch(fetchDesc).first {
            existingItem = existing
            showDuplicateAlert = true
        } else {
            context.insert(Cash(symbol: searchSymbol, quantity: qty, currentPrice: price, purchasePrice: cost))
            try? context.save() // HATA ÇÖZÜMÜ
            dismiss()
        }
        isLoading = false
    }
    
    func updateExisting() {
        guard let item = existingItem, let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")) else { return }
        
        let cost: Double
        if selectedCurrency == "TRY" {
            cost = 1.0
        } else {
            guard let c = Double(purchasePriceStr.replacingOccurrences(of: ",", with: ".")) else { return }
            cost = c
        }
        
        let totalOldCost = item.quantity * item.purchasePrice
        let totalNewCost = qty * cost
        let newTotalQuantity = item.quantity + qty
        
        item.purchasePrice = (totalOldCost + totalNewCost) / newTotalQuantity
        item.quantity = newTotalQuantity
        item.currentPrice = pendingPrice
        
        try? context.save() // HATA ÇÖZÜMÜ
        dismiss()
    }
}
