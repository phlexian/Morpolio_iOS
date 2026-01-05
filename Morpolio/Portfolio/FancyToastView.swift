import SwiftUI

struct FancyToastView: View {
    var message: String
    var themeColor: Color
    var timeLeft: Int      // Dışarıdan gelen kalan süre
    var totalTime: Int = 5 // Toplam süre (Progress bar hesabı için)
    var onUndo: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            // 1. Sol Taraf: Geri Sayım ve Circle Bar
            ZStack {
                // Arkaplan Çemberi (Soluk)
                Circle()
                    .stroke(themeColor.opacity(0.3), lineWidth: 3)
                
                // İlerleyen Çember (Dolu)
                // timeLeft azaldıkça çember de azalır
                Circle()
                    .trim(from: 0, to: CGFloat(timeLeft) / CGFloat(totalTime))
                    .stroke(themeColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.0), value: timeLeft) // Akıcı geçiş
                
                // Ortadaki Rakam
                Text("\(timeLeft)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(themeColor)
                    .contentTransition(.numericText())
            }
            .frame(width: 30, height: 30)
            
            // 2. Mesaj
            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            // 3. Sağ Taraf: Geri Al Butonu (U Ok)
            Button(action: onUndo) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.title3)
                    .bold()
                    .foregroundStyle(themeColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                .overlay(Capsule().stroke(Color.gray.opacity(0.2), lineWidth: 1))
        )
        .padding(.horizontal, 20)
    }
}
