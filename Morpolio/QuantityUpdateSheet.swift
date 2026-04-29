import SwiftUI

struct QuantityUpdateSheet: View {
    var symbol: String
    var currentQuantity: Double
    var currentPurchasePrice: Double
    var purchaseCurrency: String = "₺" // Varsayılan döviz
    
    var onUpdate: (Double, Double) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var newQuantity: String = ""
    @State private var newPurchasePrice: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Mevcut Adet: \(currentQuantity, specifier: "%.4f")")) {
                    TextField("Yeni Adet Giriniz", text: $newQuantity)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("Mevcut Alış Fiyatı: \(currentPurchasePrice, specifier: "%.4f") \(purchaseCurrency)")) {
                    HStack {
                        TextField("Yeni Alış Fiyatı Giriniz", text: $newPurchasePrice)
                            .keyboardType(.decimalPad)
                        
                        // YENİ: Sağ tarafta sabit olarak duran ve değiştirilemeyen döviz sembolü
                        Text(purchaseCurrency)
                            .foregroundStyle(.secondary)
                            .fontWeight(.bold)
                    }
                }
                
                Button("Güncelle") {
                    let qty = Double(newQuantity.replacingOccurrences(of: ",", with: ".")) ?? currentQuantity
                    let price = Double(newPurchasePrice.replacingOccurrences(of: ",", with: ".")) ?? currentPurchasePrice
                    
                    onUpdate(qty, price)
                    dismiss()
                }
            }
            .navigationTitle("\(symbol) Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
            }
            .onAppear {
                newQuantity = String(currentQuantity)
                newPurchasePrice = String(currentPurchasePrice)
            }
        }
    }
}
