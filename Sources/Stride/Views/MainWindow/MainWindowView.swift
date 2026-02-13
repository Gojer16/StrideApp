import SwiftUI

/**
 Main application window with sidebar navigation.
 
 Provides a NavigationSplitView with:
 - Sidebar: App branding and navigation items
 - Detail: Content views based on selected sidebar item
 */
struct MainWindowView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedSidebarItem = 0
    
    let sidebarItems = [
        ("Live", "bolt.fill", "Current session"),
        ("All Apps", "app.fill", "Browse all apps"),
        ("Categories", "chart.pie.fill", "Manage categories"),
        ("Weekly Log", "clock.badge.checkmark", "Track pomodoros"),
        ("Today", "calendar", "Today's summary"),
        ("This Week", "chart.line.uptrend.xyaxis", "Weekly patterns"),
        ("Habit Tracker", "leaf.fill", "Track your habits")
    ]
    
    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            contentView
        }
    }
    
    private var sidebar: some View {
        VStack(spacing: 0) {
            // App Header
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "eye.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }
                
                Text("Stride")
                    .font(.system(size: 20, weight: .bold))
                
                Text("Track your screen time")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 16)
            
            Divider()
            
            List(selection: $selectedSidebarItem) {
                Section("Navigation") {
                    ForEach(0..<sidebarItems.count, id: \.self) { index in
                        Label {
                            Text(sidebarItems[index].0)
                        } icon: {
                            Image(systemName: sidebarItems[index].1)
                                .symbolRenderingMode(.hierarchical)
                        }
                        .tag(index)
                        .help(sidebarItems[index].2)
                    }
                }
            }
            .listStyle(.sidebar)
        }
        .frame(minWidth: 240)
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch selectedSidebarItem {
        case 0:
            CurrentSessionView()
        case 1:
            AllAppsView()
        case 2:
            CategoryManagementView()
        case 3:
            WeeklyLogView()
        case 4:
            TodayView()
        case 5:
            WeeklyView()
        case 6:
            HabitTrackerView()
        default:
            CurrentSessionView()
        }
    }
}
