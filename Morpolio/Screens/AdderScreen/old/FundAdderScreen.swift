/*import SwiftUI
import SwiftData

struct FundAdderScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    
    @State private var symbol: String = ""
    @State private var quantity: String = ""
    @State private var isLoading = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showDuplicateAlert = false
    @State private var existingFund: Fund?
    private let apiService = APIService()
    
    enum Field { case symbol, quantity }
    @FocusState private var focusedField: Field?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Fon Bilgileri")) {
                    TextField("Fon Kodu (Örn: TTE)", text: $symbol)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .symbol)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .quantity }
                    
                    TextField("Adet", text: $quantity)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .quantity)
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
                                        .frame(width: 32, height: 32).background(Circle().fill(AppTheme.fundColor))
                                }
                            }
                            ToolbarItem(placement: .principal) {
                                Text("Fon Ekle").font(.title3).bold().foregroundStyle(AppTheme.fundColor)
                            }
                            ToolbarItem(placement: .topBarTrailing) {
                                Button(action: { Task { await checkAndAdd() } }) {
                                    if isLoading {
                                        ProgressView().tint(.white).frame(width: 32, height: 32).background(Circle().fill(AppTheme.fundColor))
                                    } else {
                                        Image(systemName: "checkmark").fontWeight(.bold).foregroundStyle(.white)
                                            .frame(width: 32, height: 32)
                                            .background(Circle().fill(isFormValid ? AppTheme.fundColor : Color.gray.opacity(0.5)))
                                    }
                                }
                                .disabled(isLoading || !isFormValid)
                            }
                        }
            // ...
            .alert("Hata", isPresented: $showErrorAlert) { Button("Tamam", role: .cancel) { } } message: { Text(errorMessage) }
            .alert("Mevcut Kayıt", isPresented: $showDuplicateAlert) {
                Button("Ekle") { if let f = existingFund, let q = Double(quantity) { f.quantity += q; dismiss() } }
                Button("Güncelle") { if let f = existingFund, let q = Double(quantity) { f.quantity = q; dismiss() } }
                Button("İptal", role: .cancel) { }
            } message: { Text("Bu fon zaten portföyde var.") }
        }
        .onAppear { focusedField = .symbol }
    }
    
    var isFormValid: Bool { !symbol.isEmpty && !quantity.isEmpty }
    
    func checkAndAdd() async {
        guard let qty = Double(quantity) else { return }
        let upperSymbol = symbol.uppercased()
        isLoading = true
        let descriptor = FetchDescriptor<Fund>(predicate: #Predicate { $0.symbol == upperSymbol })
        if let existing = try? context.fetch(descriptor).first { existingFund = existing; isLoading = false; showDuplicateAlert = true; return }
        if let p = await apiService.fetchFundPrice(symbol: upperSymbol) {
            context.insert(Fund(symbol: upperSymbol, quantity: qty, currentPrice: p)); dismiss()
        } else { errorMessage = "Bulunamadı"; showErrorAlert = true; isLoading = false }
    }
}*/
