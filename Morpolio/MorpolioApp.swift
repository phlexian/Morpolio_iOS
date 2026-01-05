import SwiftUI
import SwiftData

@main
struct MorpolioApp: App {
    var body: some Scene {
        WindowGroup {
            RootView() // GÜNCELLENDİ
        }
        .modelContainer(for: [Stock.self, Crypto.self, Fund.self, Element.self, Cash.self])
    }
}
