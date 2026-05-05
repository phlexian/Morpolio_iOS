import SwiftUI

struct QuantityUpdateSheet: View {
    var symbol: String
    var currentQuantity: Double
    var currentPurchasePrice: Double
    var purchaseCurrency: String = "₺"
    
    var onUpdate: (Double, Double) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var newQuantity: String = ""
    @State private var newPurchasePrice: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Mevcut Adet: \(currentQuantity.formatted(.number.precision(.fractionLength(0...8))))")) {
                    TextField("Yeni Adet Giriniz", text: $newQuantity)
                        .keyboardType(.decimalPad)
                        .onChange(of: newQuantity) { _, newValue in
                            newQuantity = newValue.formatNumber()
                        }
                }
                
                Section(header: Text("Mevcut Alış Fiyatı: \(currentPurchasePrice.formatted(.number.precision(.fractionLength(0...8)))) \(purchaseCurrency)")) {
                    HStack {
                        TextField("Yeni Alış Fiyatı Giriniz", text: $newPurchasePrice)
                            .keyboardType(.decimalPad)
                            .onChange(of: newPurchasePrice) { _, newValue in
                                newPurchasePrice = newValue.formatNumber()
                            }
                        
                        Text(purchaseCurrency)
                            .foregroundStyle(.secondary)
                            .fontWeight(.bold)
                    }
                }
                
                Button("Güncelle") {
                    let qty = newQuantity.toDouble() == 0.0 ? currentQuantity : newQuantity.toDouble()
                    let price = newPurchasePrice.toDouble() == 0.0 ? currentPurchasePrice : newPurchasePrice.toDouble()
                    
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
                newQuantity = String(format: "%g", currentQuantity).formatNumber()
                newPurchasePrice = String(format: "%g", currentPurchasePrice).formatNumber()
            }
        }
    }
}
