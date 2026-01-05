import SwiftUI
import SwiftData

struct RootView: View {
    // EKRAN YÜKSEKLİĞİNİ ALALIM
    @State private var screenHeight: CGFloat = UIScreen.main.bounds.height
    
    // ContentView'un Y Konumu (Başlangıçta ekran boyu kadar aşağıda = Kapalı)
    @State private var currentOffset: CGFloat = UIScreen.main.bounds.height
    
    // Aktif Sekme
    @State private var activeTab = 0
    
    var body: some View {
        ZStack {
            // 1. KATMAN: Ana Ekran (Arkada)
            HomeScreen(
                activeTab: $activeTab,
                onDragChanged: { translation in
                    // Sürükleme sırasında ofseti güncelle (Yukarı çekildikçe azalır)
                    // translation.height negatif gelir (yukarı yön), biz bunu screenHeight'ten çıkarıyoruz
                    let newOffset = screenHeight + translation.height
                    // 0'dan küçük olamaz (yukarı taşmasın), screenHeight'ten büyük olamaz
                    currentOffset = max(0, min(screenHeight, newOffset))
                },
                onDragEnded: { translation in
                    // Bırakıldığında:
                    // Eğer 100 birimden fazla yukarı çekildiyse veya hızlı çekildiyse -> AÇ
                    if translation.height < -100 {
                        openPortfolio()
                    } else {
                        // Yeterince çekilmediyse -> GERİ KAPAT
                        closePortfolio()
                    }
                },
                onTapOpen: {
                    // Tıklanırsa direkt aç
                    openPortfolio()
                }
            )
            
            // 2. KATMAN: Portföy Ekranı (Önde)
            // if bloğu YOK. Hep render ediliyor ama offset ile yönetiliyor.
            ContentView(
                onClose: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        currentOffset = screenHeight // Portföyü kapat
                    }
                },
                selectedTab: $activeTab // $ işareti olduğundan emin ol
            )
            .offset(y: currentOffset) // Ofset ile pozisyonu yönet
            // Aşağı çekme gesture'ı (ContentView içinden gelen)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Sadece aşağı çekmeye izin ver (value.translation.height > 0)
                        if value.translation.height > 0 {
                            currentOffset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        // 150 birimden fazla aşağı çekildiyse kapat
                        if value.translation.height > 150 {
                            closePortfolio()
                        } else {
                            openPortfolio()
                        }
                    }
            )
            .shadow(radius: 10) // Üstte durduğunu belli etmek için gölge
        }
        .ignoresSafeArea(.all, edges: .bottom) // Alt kısımdaki boşlukları önle
    }
    
    // Yardımcı Fonksiyonlar
    func openPortfolio() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentOffset = 0 // Tamamen yukarı çıkar
        }
    }
    
    func closePortfolio() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentOffset = screenHeight // Tamamen aşağı iner
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Stock.self, Crypto.self, Fund.self, Element.self, Cash.self], inMemory: true)
}
