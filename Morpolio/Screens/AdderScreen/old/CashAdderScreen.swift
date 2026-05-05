/*import SwiftUI
import SwiftData

struct CashAdderScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedSymbol: String = "TRY"
    @State private var quantity: String = ""
    
    @State private var isLoading = false
    @State private var showDuplicateAlert = false
    @State private var existingCash: Cash?
    
    private let currencyService = CurrencyService()
    @FocusState private var isQuantityFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Para Birimi")) {
                    HStack(spacing: 10) {
                        currencyButton(title: "₺", symbol: "TRY")
                        currencyButton(title: "$", symbol: "USD")
                        currencyButton(title: "€", symbol: "EUR")
                    }
                    .padding(.vertical, 5)
                }
                Section(header: Text("Miktar")) {
                    HStack {
                        TextField("Tutar Giriniz", text: $quantity)
                            .keyboardType(.decimalPad)
                            .focused($isQuantityFocused)
                        Text(selectedSymbol).foregroundStyle(.gray)
                    }
                }
            }
            .onTapGesture { hideKeyboard() }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .tabBar)
            // ...
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button(action: { dismiss() }) {
                                    Image(systemName: "xmark").fontWeight(.bold).foregroundStyle(.white) // XMARK
                                        .frame(width: 32, height: 32).background(Circle().fill(AppTheme.cashColor))
                                }
                            }
                            ToolbarItem(placement: .principal) {
                                Text("Nakit Ekle").font(.title3).bold().foregroundStyle(AppTheme.cashColor)
                            }
                            ToolbarItem(placement: .topBarTrailing) {
                                Button(action: { Task { await checkAndAdd() } }) {
                                    if isLoading {
                                        ProgressView().tint(.white).frame(width: 32, height: 32).background(Circle().fill(AppTheme.cashColor))
                                    } else {
                                        Image(systemName: "checkmark").fontWeight(.bold).foregroundStyle(.white)
                                            .frame(width: 32, height: 32)
                                            .background(Circle().fill(isFormValid ? AppTheme.cashColor : Color.gray.opacity(0.5)))
                                    }
                                }
                                .disabled(isLoading || !isFormValid)
                            }
                        }
            // ...
            .alert("Mevcut Kayıt", isPresented: $showDuplicateAlert) {
                Button("Ekle") { if let c = existingCash, let q = Double(quantity) { c.quantity += q; dismiss() } }
                Button("Güncelle") { if let c = existingCash, let q = Double(quantity) { c.quantity = q; dismiss() } }
                Button("İptal", role: .cancel) { }
            } message: { Text("Bu para birimi zaten portföyde var.") }
        }
        .onAppear { isQuantityFocused = true }
    }
    
    var isFormValid: Bool { !quantity.isEmpty }
    
    func currencyButton(title: String, symbol: String) -> some View {
        Button(action: { selectedSymbol = symbol; isQuantityFocused = true }) {
            Text(title)
                .font(.title2).bold()
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 10).fill(selectedSymbol == symbol ? AppTheme.cashColor : Color(uiColor: .systemGray6)))
                .foregroundStyle(selectedSymbol == symbol ? .white : .primary)
                .animation(.easeInOut, value: selectedSymbol)
        }.buttonStyle(.plain)
    }
    
    func checkAndAdd() async {
        guard let qty = Double(quantity) else { return }
        isLoading = true
        
        let descriptor = FetchDescriptor<Cash>(predicate: #Predicate { $0.symbol == selectedSymbol })
        if let existing = try? context.fetch(descriptor).first {
            existingCash = existing; isLoading = false; showDuplicateAlert = true; return
        }
        
        var price: Double = 1.0
        if selectedSymbol != "TRY" {
            if let rates = await currencyService.fetchRates() {
                if selectedSymbol == "USD" { price = rates.usd }
                else if selectedSymbol == "EUR" { price = rates.eur }
            }
        }
        
        context.insert(Cash(symbol: selectedSymbol, quantity: qty, currentPrice: price))
        isLoading = false
        dismiss()
    }
 }*/
