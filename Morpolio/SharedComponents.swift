import SwiftUI

// MARK: - RENK TANIMLAMASI
extension Color {
    static let mainAppColor = Color(red: 244/255, green: 67/255, blue: 54/255)
}

// MARK: - ODAK YÖNETİMİ İÇİN ENUM
enum AdderField {
    case symbol
    case quantity
    case purchasePrice
}

// MARK: - LIQUID GLASS PICKER
struct CustomSegmentedPicker: View {
    let options: [(id: String, label: String)]
    @Binding var selection: String
    let color: Color
    @Namespace private var pickerTransition
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.id) { option in
                ZStack {
                    if selection == option.id {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(color.opacity(0.8))
                            .matchedGeometryEffect(id: "activeBackground", in: pickerTransition)
                            .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    Text(option.label)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(selection == option.id ? .white : .primary)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                selection = option.id
                            }
                        }
                }
            }
        }
        .padding(4)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - STANDART ADET GÜNCELLEME EKRANI
struct StandardUpdateSheet: View {
    let title: String
    let currentQuantity: Double
    let themeColor: Color
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
            Text("\(title) Güncelle")
                .font(.title2)
                .bold()
                .foregroundStyle(themeColor)
                .padding(.top, 35) // Başlığı aşağı itmek için artırıldı
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Yeni Adet").font(.caption).foregroundStyle(.secondary)
                TextField("Adet giriniz", text: $text)
                    .keyboardType(.decimalPad)
                    .frame(height: 50)
                    .padding(.horizontal)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(themeColor.opacity(0.5), lineWidth: 1))
            }.padding(.horizontal)
            Button(action: {
                if let val = Double(text.replacingOccurrences(of: ",", with: ".")) { onSave(val); dismiss() }
            }) {
                Text("Kaydet").font(.headline).frame(maxWidth: .infinity).padding().background(themeColor).foregroundStyle(.white).cornerRadius(16)
            }.padding(.horizontal)
            Spacer()
        }
        .presentationDetents([.fraction(0.4)])
        .contentShape(Rectangle())
        .onTapGesture {
            hideKeyboard()
        }
    }
}

// MARK: - STANDART EKLEME EKRANI TASLAĞI
struct StandardAdderLayout<Content: View>: View {
    let title: String
    let themeColor: Color
    let isLoading: Bool
    let errorMessage: String?
    let isSaveDisabled: Bool
    let onSave: () -> Void
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.title)
                .bold()
                .foregroundStyle(themeColor)
                .padding(.top, 40) // Başlığı aşağı itmek için artırıldı
                .padding(.bottom, 30)
            
            if let error = errorMessage {
                Text(error).font(.caption).foregroundStyle(.red).padding(.bottom, 10)
            }
            
            ScrollView {
                VStack(spacing: 20) { content }.padding(.horizontal)
            }
            .disabled(isLoading)
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
            
            Button(action: onSave) {
                ZStack {
                    if isLoading { ProgressView().tint(.white) }
                    else { Text("Portföye Ekle").font(.headline) }
                }
                .frame(maxWidth: .infinity).padding()
                .background(isSaveDisabled || isLoading ? Color.gray : themeColor)
                .foregroundStyle(.white).cornerRadius(16).shadow(radius: isSaveDisabled ? 0 : 5)
            }
            .disabled(isSaveDisabled || isLoading)
            .padding()
        }
    }
}

// MARK: - TOAST GÖRÜNÜMÜ
struct FancyToastView: View {
    let message: String
    let themeColor: Color
    let timeLeft: Int
    var onUndo: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().stroke(themeColor.opacity(0.3), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: CGFloat(timeLeft) / 5.0)
                    .stroke(themeColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(timeLeft)").font(.system(size: 11, weight: .bold))
            }
            .frame(width: 30, height: 30)
            
            Text(message)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .layoutPriority(1)
            
            Spacer()
            
            Button(action: onUndo) {
                Text("Geri Al")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(themeColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.1), lineWidth: 1))
        .padding(.horizontal, 24)
        .shadow(color: Color.black.opacity(0.15), radius: 10, y: 5)
    }
}
