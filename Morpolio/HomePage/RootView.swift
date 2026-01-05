import SwiftUI
import SwiftData

struct RootView: View {
    // MARK: - STATE
    @State private var activeTab: Int = 0
    @State private var currentOffset: CGFloat = 0
    @State private var lastOffset: CGFloat = 0
    @State private var isFirstLoad = true
    
    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            
            // AYAR 1: AÇIK KONUM (Tam tepeye yapışması için 0)
            let openHeight: CGFloat = 0
            
            // AYAR 2: KAPALI KONUM (Ekranın tamamen altında)
            let closeHeight = screenHeight
            
            ZStack(alignment: .bottom) {
                // A. ARKA PLAN (ANA EKRAN)
                HomeScreen(
                    activeTab: $activeTab,
                    onDragChanged: { translation in
                        // Kullanıcı "Varlıklarım" kısmından yukarı çekiyor
                        // translation.height negatif gelir (yukarı doğru -10, -20...)
                        
                        let dragAmount = translation.height
                        let targetOffset = closeHeight + dragAmount
                        
                        // Sadece yukarı harekete izin ver ve tepeyi (0) geçirmemeye çalış
                        if targetOffset > openHeight {
                            currentOffset = targetOffset
                        } else {
                            // Lastik etkisi: 0'ı geçerse biraz direnç göster (opsiyonel)
                            currentOffset = openHeight + (targetOffset - openHeight) * 0.1
                        }
                    },
                    onDragEnded: { translation in
                        // Sürükleme bittiğinde nereye yapışacak?
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            // Eğer 100 birimden fazla yukarı çekildiyse AÇ
                            // (translation.height negatif olduğu için -100'den küçükse demektir)
                            if translation.height < -100 {
                                currentOffset = openHeight
                            } else {
                                // Yeterince çekmediyse geri KAPAT
                                currentOffset = closeHeight
                            }
                            lastOffset = currentOffset
                        }
                    },
                    onTapOpen: {
                        // Oku tıklayınca direkt AÇ
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            currentOffset = openHeight
                        }
                        lastOffset = currentOffset
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // B. ÖN PLAN (PORTFÖY LİSTESİ)
                ContentView(
                    onClose: {
                        // İçerideki tutamaça basınca KAPAT
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            currentOffset = closeHeight
                        }
                        lastOffset = currentOffset
                    },
                    selectedTab: $activeTab
                )
                .frame(height: screenHeight) // Tam ekran boyutu
                .background(Color(uiColor: .systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: -5)
                .offset(y: currentOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let translation = value.translation.height
                            let newOffset = lastOffset + translation
                            
                            // Panelin kendi tutamacından sürüklerken sınırla
                            if newOffset >= openHeight {
                                currentOffset = newOffset
                            }
                        }
                        .onEnded { value in
                            let translation = value.translation.height
                            
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                if translation > 100 {
                                    // Aşağı hızlı çektiyse -> KAPAT
                                    currentOffset = closeHeight
                                } else if translation < -100 {
                                    // Yukarı hızlı çektiyse -> AÇ
                                    currentOffset = openHeight
                                } else {
                                    // Ortada bıraktıysa en yakına git
                                    let midPoint = (closeHeight + openHeight) / 2
                                    if currentOffset > midPoint {
                                        currentOffset = closeHeight
                                    } else {
                                        currentOffset = openHeight
                                    }
                                }
                                lastOffset = currentOffset
                            }
                        }
                )
            }
            .ignoresSafeArea(.all, edges: .bottom)
            .onAppear {
                if isFirstLoad {
                    // Başlangıçta kapalı olsun
                    currentOffset = closeHeight
                    lastOffset = closeHeight
                    isFirstLoad = false
                }
            }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Stock.self, Crypto.self, Fund.self, Element.self, Cash.self], inMemory: true)
}
