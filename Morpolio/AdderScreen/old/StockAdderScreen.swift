/*import SwiftUI
import SwiftData

struct StockAdderScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    
    @State private var symbol: String = ""
    @State private var quantity: String = ""
    
    @State private var isLoading = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showDuplicateAlert = false
    @State private var existingStock: Stock?
    
    private let apiService = APIService()
    
    enum Field { case symbol, quantity }
    @FocusState private var focusedField: Field?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Hisse Bilgileri")) {
                    TextField("Hisse Kodu (Örn: THYAO)", text: $symbol)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .symbol)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .quantity }
                    
                    TextField("Adet (Örn: 100)", text: $quantity)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .quantity)
                }
                // Alt kısımdaki buton kaldırıldı
            }
            .onTapGesture { hideKeyboard() }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true) // Sistem geri butonunu gizle
            .toolbar(.hidden, for: .tabBar)
            .toolbar {
                            // SOL ÜST: KAPAT (XMARK)
                            ToolbarItem(placement: .topBarLeading) {
                                Button(action: { dismiss() }) {
                                    Image(systemName: "xmark") // Sheet olduğu için X daha uygun
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                        .frame(width: 32, height: 32)
                                        .background(Circle().fill(AppTheme.stockColor))
                                }
                            }
                            
                            ToolbarItem(placement: .principal) {
                                Text("Hisse Ekle").font(.title3).bold().foregroundStyle(AppTheme.stockColor)
                            }
                            
                            // SAĞ ÜST: KAYDET (TIK)
                            ToolbarItem(placement: .topBarTrailing) {
                                Button(action: { Task { await checkAndAdd() } }) {
                                    if isLoading {
                                        ProgressView().tint(.white)
                                            .frame(width: 32, height: 32)
                                            .background(Circle().fill(AppTheme.stockColor))
                                    } else {
                                        Image(systemName: "checkmark")
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                            .frame(width: 32, height: 32)
                                            .background(Circle().fill(isFormValid ? AppTheme.stockColor : Color.gray.opacity(0.5)))
                                    }
                                }
                                .disabled(isLoading || !isFormValid)
                            }
                        }
            .alert("Hata", isPresented: $showErrorAlert) { Button("Tamam", role: .cancel) { } } message: { Text(errorMessage) }
            .alert("Mevcut Kayıt", isPresented: $showDuplicateAlert) {
                Button("Ekle") { if let s = existingStock, let q = Double(quantity) { s.quantity += q; dismiss() } }
                Button("Güncelle") { if let s = existingStock, let q = Double(quantity) { s.quantity = q; dismiss() } }
                Button("İptal", role: .cancel) { }
            } message: { Text("Bu hisse zaten portföyde var.") }
        }
        .onAppear { focusedField = .symbol }
    }
    
    var isFormValid: Bool {
        !symbol.isEmpty && !quantity.isEmpty
    }
    
    func checkAndAdd() async {
        guard let qty = Double(quantity) else { return }
        let upperSymbol = symbol.uppercased()
        isLoading = true
        let descriptor = FetchDescriptor<Stock>(predicate: #Predicate { $0.symbol == upperSymbol })
        if let existing = try? context.fetch(descriptor).first { existingStock = existing; isLoading = false; showDuplicateAlert = true; return }
        if let p = await apiService.fetchStockPrice(symbol: upperSymbol) {
            context.insert(Stock(symbol: upperSymbol, quantity: qty, currentPrice: p)); dismiss()
        } else { errorMessage = "Bulunamadı"; showErrorAlert = true; isLoading = false }
    }
}*/
