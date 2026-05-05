import SwiftUI

struct SellSheet: View {
    var symbol: String
    var currentQuantity: Double
    var currentPrice: Double
    var themeColor: Color
    
    var onSell: (Double, Double) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var sellQuantity: String = ""
    @State private var sellPrice: String = ""
    
    // YENİ: Girilen miktar mevcut miktardan büyük mü kontrol eden mantık
    var isOverLimit: Bool {
        let qty = Double(sellQuantity.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        return qty > currentQuantity
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Mevcut Adet: \(currentQuantity, specifier: "%.4f")")) {
                    TextField("Satılacak Adet Giriniz", text: $sellQuantity)
                        .keyboardType(.decimalPad)
                        // Limit aşıldıysa yazıyı kırmızı yap, aksi halde normal renkte bırak
                        .foregroundStyle(isOverLimit ? .red : .primary)
                }
                
                Section(header: Text("O Anki Satış Fiyatı")) {
                    TextField("Satış Fiyatı Giriniz", text: $sellPrice)
                        .keyboardType(.decimalPad)
                }
                
                Button("Satışı Onayla") {
                    let qty = Double(sellQuantity.replacingOccurrences(of: ",", with: ".")) ?? 0.0
                    let price = Double(sellPrice.replacingOccurrences(of: ",", with: ".")) ?? currentPrice
                    onSell(qty, price)
                    dismiss()
                }
                .foregroundStyle(.white)
                // Limit aşıldıysa butonu da gri yaparak işlemi engellediğimizi görsel olarak belli ediyoruz
                .listRowBackground(isOverLimit ? Color.gray : themeColor)
                .disabled(isOverLimit) // Mevcut varlıktan daha fazlasının satılmasını teknik olarak engelle
            }
            .navigationTitle("\(symbol) Sat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
            }
            .onAppear {
                sellPrice = String(currentPrice)
            }
        }
    }
}
