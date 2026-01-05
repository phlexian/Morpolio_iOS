import SwiftUI

struct QuantityUpdateSheet: View {
    var symbol: String
    var currentQuantity: Double
    var onUpdate: (Double) -> Void // Güncelleme tetiklendiğinde çalışacak fonksiyon
    @Environment(\.dismiss) var dismiss
    
    @State private var newQuantity: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Mevcut Adet: \(currentQuantity, specifier: "%.2f")")) {
                    TextField("Yeni Adet Giriniz", text: $newQuantity)
                        .keyboardType(.decimalPad)
                }
                
                Button("Onayla") {
                    if let qty = Double(newQuantity) {
                        onUpdate(qty)
                        dismiss()
                    }
                }
                .disabled(newQuantity.isEmpty)
            }
            .navigationTitle("Adet Güncelle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
            }
        }
    }
}
