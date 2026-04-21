import SwiftUI

struct QuantityUpdateSheet: View {
    var symbol: String
    var currentQuantity: Double
    var currentPurchasePrice: Double // YENİ: Mevcut alış fiyatını alıyoruz
    var onUpdate: (Double, Double) -> Void // YENİ: Güncelleme sonrası hem adet hem alış fiyatı dönecek
    @Environment(\.dismiss) var dismiss
    
    @State private var newQuantity: String
    @State private var newPurchasePrice: String // YENİ
    
    // Ekran açıldığında eski değerleri kutucuklara otomatik doldurmak için Init kullanıyoruz
    init(symbol: String, currentQuantity: Double, currentPurchasePrice: Double, onUpdate: @escaping (Double, Double) -> Void) {
        self.symbol = symbol
        self.currentQuantity = currentQuantity
        self.currentPurchasePrice = currentPurchasePrice
        self.onUpdate = onUpdate
        
        _newQuantity = State(initialValue: String(format: "%.2f", currentQuantity))
        _newPurchasePrice = State(initialValue: String(format: "%.2f", currentPurchasePrice))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Miktar ve Maliyet Düzenle (\(symbol))")) {
                    HStack {
                        Text("Adet:")
                        Spacer()
                        TextField("Miktar", text: $newQuantity)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Alış Fiyatı:")
                        Spacer()
                        TextField("Fiyat", text: $newPurchasePrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Button("Onayla") {
                    let qtyStr = newQuantity.replacingOccurrences(of: ",", with: ".")
                    let priceStr = newPurchasePrice.replacingOccurrences(of: ",", with: ".")
                    
                    if let qty = Double(qtyStr), let price = Double(priceStr) {
                        onUpdate(qty, price)
                        dismiss()
                    }
                }
                .disabled(newQuantity.isEmpty || newPurchasePrice.isEmpty)
            }
            .navigationTitle("Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
            }
        }
    }
}
