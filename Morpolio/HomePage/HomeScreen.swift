import SwiftUI
import SwiftData

// Portföy Listesi için Yardımcı Model
struct PortfolioSummaryItem: Identifiable {
    var id: String { name }
    let name: String
    let value: Double
    let color: Color
    var percentage: Double = 0.0
    let tabIndex: Int
}

struct HomeScreen: View {
    // Veri Tabanı Bağlantıları
    @Query private var stocks: [Stock]
    @Query private var cryptos: [Crypto]
    @Query private var funds: [Fund]
    @Query private var elements: [Element]
    @Query private var cashItems: [Cash]
    
    // Animasyon Durumları
    @Namespace private var animation
    @State private var isTextVisible = false
    @State private var isAnimationCompleted = false
    @State private var showListItems = false
    
    // RootView İletişim
    @Binding var activeTab: Int
    var onDragChanged: ((CGSize) -> Void)?
    var onDragEnded: ((CGSize) -> Void)?
    var onTapOpen: (() -> Void)?
    
    @State private var bounceAnimation = false
    
    // Para Birimi Yönetimi
    @State private var selectedCurrency: Currency = .tryCurrency
    @State private var exchangeRates: (usd: Double, eur: Double) = (1.0, 1.0)
    @State private var isCurrencyBusy = false
    private let currencyService = CurrencyService()
    
    // Hesaplamalar
    var grandTotal: Double {
        let s = stocks.reduce(0) { $0 + $1.totalValue }
        let c = cryptos.reduce(0) { $0 + $1.totalValue }
        let f = funds.reduce(0) { $0 + $1.totalValue }
        let e = elements.reduce(0) { $0 + $1.totalValue }
        let m = cashItems.reduce(0) { $0 + $1.totalValue }
        return s + c + f + e + m
    }
    
    func convert(_ value: Double) -> Double {
        switch selectedCurrency {
        case .tryCurrency: return value
        case .usd: return value / (rates.usd > 0 ? rates.usd : 1)
        case .eur: return value / (rates.eur > 0 ? rates.eur : 1)
        }
    }
    
    var rates: (usd: Double, eur: Double) { exchangeRates }
    
    var portfolioList: [PortfolioSummaryItem] {
        let total = grandTotal
        guard total > 0 else { return [] }
        
        var items = [
            PortfolioSummaryItem(name: "Hisseler", value: stocks.reduce(0) { $0 + $1.totalValue }, color: AppTheme.stockColor, tabIndex: 0),
            PortfolioSummaryItem(name: "Kripto", value: cryptos.reduce(0) { $0 + $1.totalValue }, color: AppTheme.cryptoColor, tabIndex: 1),
            PortfolioSummaryItem(name: "Fonlar", value: funds.reduce(0) { $0 + $1.totalValue }, color: AppTheme.fundColor, tabIndex: 2),
            PortfolioSummaryItem(name: "Madenler", value: elements.reduce(0) { $0 + $1.totalValue }, color: AppTheme.elementColor, tabIndex: 3),
            PortfolioSummaryItem(name: "Nakit", value: cashItems.reduce(0) { $0 + $1.totalValue }, color: AppTheme.cashColor, tabIndex: 4)
        ]
        
        items = items.filter { $0.value > 0 }
        for i in 0..<items.count {
            items[i].percentage = (items[i].value / total) * 100
        }
        
        return items.sorted { $0.percentage > $1.percentage }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(uiColor: .systemBackground).ignoresSafeArea()
                
                VStack {
                    // 1. LOGO ALANI
                    Spacer()
                        .frame(height: isAnimationCompleted ? 20 : geometry.size.height / 2.5)
                    
                    Text("MORPOLIO")
                        .font(.system(size: 70, weight: .heavy, design: .rounded))
                        // DÜZELTME 1: Color.mainAppColor kullanıldı
                        .foregroundStyle(Color.mainAppColor)
                        .scaleEffect(isAnimationCompleted ? 0.8 : 1.0)
                        .opacity(isTextVisible ? 1.0 : 0.0)
                    
                    // 2. İKİNCİ KATMAN
                    if isAnimationCompleted {
                        Spacer().frame(height: 50)
                        
                        VStack(spacing: 40) {
                            
                            // A. TOPLAM VARLIK
                            VStack(spacing: 5) {
                                Text("Varlıklar Toplamı")
                                    .font(.title3).bold().foregroundStyle(.secondary)
                                
                                Button(action: cycleCurrency) {
                                    HStack(spacing: 4) {
                                        Text("\(convert(grandTotal), specifier: "%.2f")")
                                            .contentTransition(.numericText())
                                        Text(selectedCurrency.rawValue)
                                    }
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)
                                    .opacity(isCurrencyBusy ? 0.5 : 1.0)
                                }
                                .buttonStyle(.plain)
                                .disabled(isCurrencyBusy)
                            }
                            
                            // B. AKORDİYON LİSTE
                            VStack(spacing: 15) {
                                ForEach(Array(portfolioList.enumerated()), id: \.element.id) { index, item in
                                    Button(action: {
                                        activeTab = item.tabIndex
                                        onTapOpen?()
                                    }) {
                                        HStack {
                                            Capsule().fill(item.color).frame(width: 6, height: 35)
                                            Text(item.name).font(.title3).fontWeight(.semibold).foregroundStyle(.primary).padding(.leading, 4)
                                            Spacer()
                                            VStack(alignment: .trailing, spacing: 2) {
                                                Text("\(convert(item.value), specifier: "%.2f") \(selectedCurrency.rawValue)")
                                                    .font(.headline).bold().foregroundStyle(.primary)
                                                Text("%\(item.percentage, specifier: "%.1f")")
                                                    .font(.subheadline).foregroundStyle(.secondary)
                                            }
                                        }
                                        .padding(.vertical, 16)
                                        .padding(.horizontal, 20)
                                        .background(Color(uiColor: .secondarySystemBackground).opacity(0.6))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, 20)
                                    .offset(x: showListItems ? 0 : -geometry.size.width * 1.5)
                                    .opacity(showListItems ? 1 : 0)
                                    .animation(
                                        .spring(response: 0.6, dampingFraction: 0.7).delay(Double(index) * 0.1),
                                        value: showListItems
                                    )
                                }
                            }
                            .padding(.top, 10)
                        }
                        .transition(.opacity)
                    }
                    
                    Spacer()
                    
                    // 3. ALT ETKİLEŞİM ALANI
                    bottomInteractiveArea
                        .padding(.bottom, 0)
                }
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    var bottomInteractiveArea: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 8) {
                Image(systemName: "chevron.compact.up")
                    .font(.system(size: 30, weight: .medium))
                    // DÜZELTME 2: Color.mainAppColor kullanıldı
                    .foregroundStyle(Color.mainAppColor)
                    .offset(y: bounceAnimation ? -5 : 5)
                
                Text("VARLIKLAR")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .background(Color.clear)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in onDragChanged?(value.translation) }
                .onEnded { value in onDragEnded?(value.translation) }
        )
        .simultaneousGesture(TapGesture().onEnded { onTapOpen?() })
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                bounceAnimation = true
            }
        }
    }
    
    func startAnimation() {
        withAnimation(.easeIn(duration: 1.0)) { isTextVisible = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut(duration: 1.0)) { isAnimationCompleted = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { showListItems = true }
    }
    
    func cycleCurrency() {
        switch selectedCurrency {
        case .tryCurrency: selectedCurrency = .usd
        case .usd: selectedCurrency = .eur
        case .eur: selectedCurrency = .tryCurrency
        }
        if selectedCurrency != .tryCurrency && exchangeRates == (1.0, 1.0) {
            Task {
                isCurrencyBusy = true
                if let rates = await currencyService.fetchRates() { exchangeRates = rates }
                isCurrencyBusy = false
            }
        }
    }
}

#Preview {
    HomeScreen(activeTab: .constant(0))
        .modelContainer(for: [Stock.self, Crypto.self, Fund.self, Element.self, Cash.self], inMemory: true)
}
