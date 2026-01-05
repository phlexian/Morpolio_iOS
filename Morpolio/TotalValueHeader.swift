import SwiftUI

struct TotalValueHeader: View {
    var totalValueTRY: Double // Her zaman TL gelir
    var themeColor: Color
    @Binding var currentCurrency: Currency
    @Binding var currencyRates: (usd: Double, eur: Double) // Kurlar
    @Binding var isBusy: Bool // Veri çekiliyor mu?
    
    // Hesaplanan Görüntü Değeri
    var displayValue: Double {
        switch currentCurrency {
        case .tryCurrency: return totalValueTRY
        case .usd: return totalValueTRY / (currencyRates.usd > 0 ? currencyRates.usd : 1)
        case .eur: return totalValueTRY / (currencyRates.eur > 0 ? currencyRates.eur : 1)
        }
    }
    
    var body: some View {
        Button(action: cycleCurrency) {
            HStack(spacing: 4) {
                Text(currentCurrency.rawValue) // Sembol (₺, $, €)
                    .font(.headline)
                    .bold()
                
                Text("\(displayValue, specifier: "%.2f")")
                    .font(.headline)
                    .bold()
                    .contentTransition(.numericText()) // Rakam değişirken animasyon
            }
            .foregroundStyle(themeColor) // İçi tema rengi (yazı)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .stroke(themeColor, lineWidth: 2) // Kenarlıklı
                    .background(Capsule().fill(.white)) // İçi beyaz
            )
        }
        .disabled(isBusy) // Meşgulse tıklanmaz
        .opacity(isBusy ? 0.5 : 1.0) // Solgun görünür
    }
    
    func cycleCurrency() {
        // Döngü: TRY -> USD -> EUR -> TRY
        switch currentCurrency {
        case .tryCurrency: currentCurrency = .usd
        case .usd: currentCurrency = .eur
        case .eur: currentCurrency = .tryCurrency
        }
    }
}
