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
            let openHeight: CGFloat = 0
            let closeHeight = screenHeight
            
            ZStack(alignment: .bottom) {
                // A. ARKA PLAN (ANA EKRAN)
                HomeScreen(
                    activeTab: $activeTab,
                    onDragChanged: { translation in
                        let dragAmount = translation.height
                        let targetOffset = closeHeight + dragAmount
                        if targetOffset > openHeight {
                            currentOffset = targetOffset
                        } else {
                            currentOffset = openHeight + (targetOffset - openHeight) * 0.1
                        }
                    },
                    onDragEnded: { translation in
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            if translation.height < -100 {
                                currentOffset = openHeight
                            } else {
                                currentOffset = closeHeight
                            }
                            lastOffset = currentOffset
                        }
                    },
                    onTapOpen: {
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
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            currentOffset = closeHeight
                        }
                        lastOffset = currentOffset
                    },
                    selectedTab: $activeTab
                )
                .frame(height: screenHeight)
                .background(Color(uiColor: .systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: -5)
                .offset(y: currentOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let translation = value.translation.height
                            let newOffset = lastOffset + translation
                            if newOffset >= openHeight {
                                currentOffset = newOffset
                            }
                        }
                        .onEnded { value in
                            let translation = value.translation.height
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                if translation > 100 {
                                    currentOffset = closeHeight
                                } else if translation < -100 {
                                    currentOffset = openHeight
                                } else {
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
                    currentOffset = closeHeight
                    lastOffset = closeHeight
                    isFirstLoad = false
                }
            }
        }
    }
}
