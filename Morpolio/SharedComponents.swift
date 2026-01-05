import SwiftUI

// MARK: - RENK TANIMLAMASI
extension Color {
    static let mainAppColor = Color(red: 244/255, green: 67/255, blue: 54/255)
}

// MARK: - STANDART ADET GÜNCELLEME EKRANI
struct StandardUpdateSheet: View {
    let title: String
    let currentQuantity: Double
    let themeColor: Color // YENİ: Tema Rengi
    let onSave: (Double) -> Void
    
    @State private var text: String
    @Environment(\.dismiss) private var dismiss
    
    init(title: String, currentQuantity: Double, themeColor: Color, onSave: @escaping (Double) -> Void) {
        self.title = title
        self.currentQuantity = currentQuantity
        self.themeColor = themeColor
        self.onSave = onSave
        let formatted = currentQuantity.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", currentQuantity) : String("\(currentQuantity)")
        _text = State(initialValue: formatted)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
            
            Text("\(title) Güncelle")
                .font(.title2)
                .bold()
                .foregroundStyle(themeColor) // Tema Rengi Kullanıldı
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Yeni Adet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextField("Adet giriniz", text: $text)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeColor.opacity(0.5), lineWidth: 1) // Tema Rengi
                    )
            }
            .padding(.horizontal)
            
            Button(action: {
                let cleanText = text.replacingOccurrences(of: ",", with: ".")
                if let newValue = Double(cleanText) {
                    onSave(newValue)
                    dismiss()
                }
            }) {
                Text("Kaydet")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeColor) // Tema Rengi
                    .foregroundStyle(.white)
                    .cornerRadius(16)
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            Spacer()
        }
        .presentationDetents([.fraction(0.4)]) // Sadece alt kısmı kaplar
    }
}

// MARK: - STANDART EKLEME EKRANI TASLĞI
struct StandardAdderLayout<Content: View>: View {
    let title: String
    let themeColor: Color // YENİ: Tema Rengi
    let onSave: () -> Void
    @ViewBuilder let content: Content
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Üst Tutamaç
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 20)
            
            // Başlık
            Text(title)
                .font(.title)
                .bold()
                .foregroundStyle(themeColor) // Tema Rengi
                .padding(.bottom, 30)
            
            // İçerik
            ScrollView {
                VStack(spacing: 20) {
                    content
                }
                .padding(.horizontal)
            }
            
            // Kaydet Butonu
            Button(action: {
                onSave()
                dismiss()
            }) {
                Text("Listeye Ekle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeColor) // Tema Rengi
                    .foregroundStyle(.white)
                    .cornerRadius(16)
                    .shadow(radius: 5)
            }
            .padding()
        }
        .background(Color(uiColor: .systemBackground))
    }
}
