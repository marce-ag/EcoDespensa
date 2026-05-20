import SwiftUI
import SwiftData

@main
struct EcoDespensaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [ProductoAlimento.self, ItemCompra.self])
    }
}
