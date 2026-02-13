import SwiftUI

/**
 Main entry point for the application's content.
 
 This lightweight view simply delegates to MainWindowView, which handles
 the actual navigation and layout structure.
 */
struct ContentView: View {
    var body: some View {
        MainWindowView()
    }
}
