import SwiftUI
import SwiftData

struct CryptoSellSheet: View {
    var crypto: Crypto
    var themeColor: Color
    var rates: (usd: Double, eur: Double)
    
    var onSell: (Double, Double) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var sellQuantity: String = ""
    @State private var sellPrice: String = ""
    @State private var selectedCurrency: String = "₺"
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Mevcut Adet: \(crypto.quantity.formatted(.number.precision(.fractionLength(0...8))))")) {
                    TextField("Satılacak Adet Giriniz", text: $sellQuantity)
                        .keyboardType(.decimalPad)
                        // Girilen değer mevcut adetten fazlaysa metni kırmızı yap
                        .foregroundStyle(sellQuantity.toDouble() > crypto.quantity ? .red : .primary)
                        .onChange(of: sellQuantity) { _, newValue in
                            sellQuantity = newValue.formatNumber()
                        }
                }
                
                Section(header: Text("O Anki Satış Fiyatı")) {
                    HStack {
                        TextField("Satış Fiyatı Giriniz", text: $sellPrice)
                            .keyboardType(.decimalPad)
                            .onChange(of: sellPrice) { _, newValue in
                                sellPrice = newValue.formatNumber()
                            }
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                if selectedCurrency == "₺" { selectedCurrency = "$" }
                                else if selectedCurrency == "$" { selectedCurrency = "€" }
                                else { selectedCurrency = "₺" }
                            }
                        }) {
                            Text(selectedCurrency)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .frame(width: 45, height: 45)
                                .background(themeColor)
                                .clipShape(Circle())
                                .shadow(color: themeColor.opacity(0.4), radius: 4, x: 0, y: 2)
                        }
                    }
                }
                
                Section(header: Text("Satış Analizi")) {
                    VStack(alignment: .leading, spacing: 8) {
                        let qty = sellQuantity.toDouble()
                        let priceInput = sellPrice.toDouble()
                        
                        let multiplier: Double = {
                            if selectedCurrency == "$" { return rates.usd }
                            else if selectedCurrency == "€" { return rates.eur }
                            return 1.0
                        }()
                        
                        let totalRevenueTRY = qty * priceInput * multiplier
                        let totalCostTRY = qty * crypto.purchasePrice
                        let profitTRY = totalRevenueTRY - totalCostTRY
                        let profitPct = totalCostTRY > 0 ? (profitTRY / totalCostTRY) * 100 : 0.0
                        
                        // Sıfır durumu için gri renk kontrolü eklendi
                        let color = profitTRY > 0 ? Color.green : (profitTRY < 0 ? Color.red : Color.gray)
                        let sign = profitTRY > 0 ? "+" : ""
                        
                        Text("Toplam Maliyet: \(totalCostTRY / multiplier, specifier: "%.2f") \(selectedCurrency)")
                        Text("Toplam Gelir: \(totalRevenueTRY / multiplier, specifier: "%.2f") \(selectedCurrency)")
                        Text("Kar/Zarar: \(sign)\(profitTRY / multiplier, specifier: "%.2f") \(selectedCurrency) (\(sign)\(profitPct, specifier: "%.2f")%)")
                            .foregroundStyle(color)
                            .bold()
                    }
                    .padding(.vertical, 4)
                }
                
                let isExceeding = sellQuantity.toDouble() > crypto.quantity
                let isZero = sellQuantity.toDouble() <= 0
                
                Button("Satışı Onayla") {
                    let qty = sellQuantity.toDouble()
                    let priceInput = sellPrice.toDouble()
                    let finalInput = priceInput == 0.0 ? crypto.currentPrice : priceInput
                    
                    let multiplier: Double = {
                        if selectedCurrency == "$" { return rates.usd }
                        else if selectedCurrency == "€" { return rates.eur }
                        return 1.0
                    }()
                    
                    let finalPriceTRY = finalInput * multiplier
                    
                    onSell(qty, finalPriceTRY)
                    dismiss()
                }
                // Adet fazla girildiyse veya 0 ise butonu inaktif yap ve grileştir
                .disabled(isExceeding || isZero)
                .foregroundStyle(.white)
                .listRowBackground((isExceeding || isZero) ? Color.gray : themeColor)
            }
            .navigationTitle("\(crypto.symbol) Sat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
            }
            .onAppear {
                let multiplier: Double = {
                    if selectedCurrency == "$" { return rates.usd }
                    else if selectedCurrency == "€" { return rates.eur }
                    return 1.0
                }()
                let displayedPrice = crypto.currentPrice / multiplier
                sellPrice = String(format: "%.2f", displayedPrice).formatNumber()
            }
        }
    }
}
