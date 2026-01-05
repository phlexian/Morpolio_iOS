import SwiftUI
import SwiftData

// --- 1. HİSSE EKLEME ---
struct StockAdderScreen: View {
    @Environment(\.modelContext) private var context
    var themeColor: Color // Parametre
    @State private var symbol = ""
    @State private var quantity = ""
    
    var body: some View {
        StandardAdderLayout(title: "Hisse Ekle", themeColor: themeColor, onSave: save) {
            CustomTextField(title: "Hisse Kodu (Örn: THYAO)", text: $symbol)
            CustomTextField(title: "Adet", text: $quantity, isNumber: true)
        }
    }
    
    func save() {
        guard !symbol.isEmpty, let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")) else { return }
        let stock = Stock(symbol: symbol.uppercased(), quantity: qty, currentPrice: 0.0)
        context.insert(stock)
    }
}

// --- 2. KRİPTO EKLEME ---
struct CryptoAdderScreen: View {
    @Environment(\.modelContext) private var context
    var themeColor: Color
    @State private var symbol = ""
    @State private var quantity = ""
    
    var body: some View {
        StandardAdderLayout(title: "Kripto Ekle", themeColor: themeColor, onSave: save) {
            CustomTextField(title: "Sembol (Örn: BTC)", text: $symbol)
            CustomTextField(title: "Adet", text: $quantity, isNumber: true)
        }
    }
    
    func save() {
        guard !symbol.isEmpty, let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")) else { return }
        let crypto = Crypto(symbol: symbol.uppercased(), quantity: qty, currentPrice: 0.0)
        context.insert(crypto)
    }
}

// --- 3. FON EKLEME ---
struct FundAdderScreen: View {
    @Environment(\.modelContext) private var context
    var themeColor: Color
    @State private var symbol = ""
    @State private var quantity = ""
    
    var body: some View {
        StandardAdderLayout(title: "Fon Ekle", themeColor: themeColor, onSave: save) {
            CustomTextField(title: "Fon Kodu (Örn: TTE)", text: $symbol)
            CustomTextField(title: "Adet", text: $quantity, isNumber: true)
        }
    }
    
    func save() {
        guard !symbol.isEmpty, let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")) else { return }
        let fund = Fund(symbol: symbol.uppercased(), quantity: qty, currentPrice: 0.0)
        context.insert(fund)
    }
}

// --- 4. MADEN EKLEME ---
struct ElementAdderScreen: View {
    @Environment(\.modelContext) private var context
    var themeColor: Color
    @State private var selectedElement = "GLD"
    @State private var quantity = ""
    
    // (Gr) ifadesi kaldırıldı
    let elements = [("GLD", "Altın"), ("SLV", "Gümüş"), ("PLT", "Platin")]
    
    var body: some View {
        StandardAdderLayout(title: "Maden Ekle", themeColor: themeColor, onSave: save) {
            // Büyük Fontlu Özel Seçim
            CustomSegmentedPicker(options: elements, selection: $selectedElement, color: themeColor)
            
            CustomTextField(title: "Adet (Gram)", text: $quantity, isNumber: true)
        }
    }
    
    func save() {
        guard let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")) else { return }
        let element = Element(symbol: selectedElement, quantity: qty, currentPrice: 0.0)
        context.insert(element)
    }
}

// --- 5. NAKİT EKLEME ---
struct CashAdderScreen: View {
    @Environment(\.modelContext) private var context
    var themeColor: Color
    @State private var selectedCurrency = "TRY"
    @State private var quantity = ""
    
    // Semboller kullanıldı
    let currencies = [("TRY", "₺"), ("USD", "$"), ("EUR", "€")]
    
    var body: some View {
        StandardAdderLayout(title: "Nakit Ekle", themeColor: themeColor, onSave: save) {
            // Büyük Fontlu Özel Seçim
            CustomSegmentedPicker(options: currencies, selection: $selectedCurrency, color: themeColor)
            
            CustomTextField(title: "Miktar", text: $quantity, isNumber: true)
        }
    }
    
    func save() {
        guard let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")) else { return }
        let cash = Cash(symbol: selectedCurrency, quantity: qty, currentPrice: 1.0)
        context.insert(cash)
    }
}

// MARK: - YARDIMCI BİLEŞENLER

// Standart Input
struct CustomTextField: View {
    let title: String
    @Binding var text: String
    var isNumber: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            TextField("", text: $text)
                .keyboardType(isNumber ? .decimalPad : .default)
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// Büyük Fontlu Özel Segmented Picker
struct CustomSegmentedPicker: View {
    let options: [(id: String, label: String)]
    @Binding var selection: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.id) { option in
                Button(action: {
                    withAnimation(.spring()) {
                        selection = option.id
                    }
                }) {
                    Text(option.label)
                        .font(.title2) // BÜYÜK FONT İSTEĞİ
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selection == option.id ? color : Color.clear)
                        .foregroundStyle(selection == option.id ? .white : .primary)
                }
            }
        }
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .padding(.bottom, 10)
    }
}
