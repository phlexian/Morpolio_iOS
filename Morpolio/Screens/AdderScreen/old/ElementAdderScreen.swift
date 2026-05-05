/*import SwiftUI
import SwiftData

struct ElementAdderScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedSymbol: String = "GLD"
    @State private var quantity: String = ""
    @State private var isLoading = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showDuplicateAlert = false
    @State private var existingElement: Element?
    
    private let apiService = APIService()
    @FocusState private var isQuantityFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Maden Seçimi")) {
                    HStack(spacing: 10) {
                        elementSelectionButton(title: "Altın", symbol: "GLD")
                        elementSelectionButton(title: "Gümüş", symbol: "SLV")
                        elementSelectionButton(title: "Platin", symbol: "PLT")
                    }
                    .padding(.vertical, 5)
                }
                Section(header: Text("Miktar")) {
                    HStack {
                        TextField("Gram (Örn: 10.5)", text: $quantity)
                            .keyboardType(.decimalPad)
                            .focused($isQuantityFocused)
                        Text("Gr").foregroundStyle(.gray)
                    }
                }
            }
            .onTapGesture { hideKeyboard() }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .tabBar)
            .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button(action: { dismiss() }) {
                                    Image(systemName: "xmark").fontWeight(.bold).foregroundStyle(.white) // XMARK
                                        .frame(width: 32, height: 32).background(Circle().fill(AppTheme.elementColor))
                                }
                            }
                            ToolbarItem(placement: .principal) {
                                Text("Değerli Maden Ekle").font(.title3).bold().foregroundStyle(AppTheme.elementColor)
                            }
                            ToolbarItem(placement: .topBarTrailing) {
                                Button(action: { Task { await checkAndAdd() } }) {
                                    if isLoading {
                                        ProgressView().tint(.white).frame(width: 32, height: 32).background(Circle().fill(AppTheme.elementColor))
                                    } else {
                                        Image(systemName: "checkmark").fontWeight(.bold).foregroundStyle(.white)
                                            .frame(width: 32, height: 32)
                                            .background(Circle().fill(isFormValid ? AppTheme.elementColor : Color.gray.opacity(0.5)))
                                    }
                                }
                                .disabled(isLoading || !isFormValid)
                            }
                        }
            .alert("Hata", isPresented: $showErrorAlert) { Button("Tamam", role: .cancel) { } } message: { Text(errorMessage) }
            .alert("Mevcut Kayıt", isPresented: $showDuplicateAlert) {
                Button("Ekle") { if let e = existingElement, let q = Double(quantity) { e.quantity += q; dismiss() } }
                Button("Güncelle") { if let e = existingElement, let q = Double(quantity) { e.quantity = q; dismiss() } }
                Button("İptal", role: .cancel) { }
            } message: { Text("Bu maden zaten portföyde var.") }
        }
        .onAppear { isQuantityFocused = true }
    }
    
    var isFormValid: Bool { !quantity.isEmpty }
    
    func elementSelectionButton(title: String, symbol: String) -> some View {
        Button(action: { selectedSymbol = symbol; isQuantityFocused = true }) {
            Text(title)
                .font(.subheadline).bold()
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 10).fill(selectedSymbol == symbol ? AppTheme.elementColor : Color(uiColor: .systemGray6)))
                .foregroundStyle(selectedSymbol == symbol ? .white : .primary)
                .animation(.easeInOut, value: selectedSymbol)
        }.buttonStyle(.plain)
    }
    
    func checkAndAdd() async {
        guard let qty = Double(quantity) else { return }
        isLoading = true
        let descriptor = FetchDescriptor<Element>(predicate: #Predicate { $0.symbol == selectedSymbol })
        if let existing = try? context.fetch(descriptor).first { existingElement = existing; isLoading = false; showDuplicateAlert = true; return }
        
        if let p = await apiService.fetchElementPrice(symbol: selectedSymbol) {
            context.insert(Element(symbol: selectedSymbol, quantity: qty, currentPrice: p)); dismiss()
        } else {
            errorMessage = "Fiyat bilgisi alınamadı."; showErrorAlert = true; isLoading = false
        }
    }
}*/
