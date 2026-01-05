import SwiftUI

extension View {
    // Klavyeyi kapatan fonksiyon
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
