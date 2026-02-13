import SwiftUI

/**
 * AppDetailSidebar - A vertical drawer for granular app inspection.
 * 
 * This component is used in `AllAppsView` to show the details of a single 
 * application without leaving the main grid.
 * 
 * **Functionality:**
 * - Statistics: Displays cumulative time, daily time, visits, and window counts.
 * - History: Shows first and last recorded usage dates.
 * - Windows: Lists top windows/tabs by time spent.
 * - Categorization: Allows the user to change the app's category via `AppCategoryPickerView`.
 * 
 * **Data Flow:**
 * - Uses `UsageDatabase` to fetch window-level granularity for the specific app.
 * - Triggers `onCategoryChanged` when the user selects a new label.
 */
struct AppDetailSidebar: View {
    /// The application record to inspect
    let app: AppUsage
    
    /// Binding to allow the sidebar to close itself or reflect selection changes
    @Binding var selectedApp: AppUsage?
    
    /// Callback triggered when the user updates the app's category
    var onCategoryChanged: (() -> Void)? = nil
    
    @State private var windows: [WindowUsage] = []
    @State private var editingCategory = false
    
    var body: some View {
        let category = app.getCategory()
        
        ScrollView {
            VStack(spacing: 24) {
                // MARK: Hero Header
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(hex: category.color).opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: category.icon)
                            .font(.system(size: 36))
                            .foregroundColor(Color(hex: category.color))
                    }
                    
                    Text(app.name)
                        .font(.title2.bold())
                    
                    // Category Editor Trigger
                    Button(action: { editingCategory = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "tag.fill").font(.system(size: 10))
                            Text(category.name).font(.system(size: 13, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color(hex: category.color).opacity(0.15)))
                        .foregroundColor(Color(hex: category.color))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 20)
                
                Divider()
                
                // MARK: Quick Stats Grid
                let todayTime = UsageDatabase.shared.getTodayTime(for: app.id.uuidString)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    DetailStatBox(value: app.formattedTotalTime(), label: "Total", icon: "clock")
                    DetailStatBox(value: todayTime.formatted(), label: "Today", icon: "sun.max")
                    DetailStatBox(value: "\(app.visitCount)", label: "Visits", icon: "arrow.counterclockwise")
                    DetailStatBox(value: "\(windows.count)", label: "Windows", icon: "uiwindow.split.2x1")
                }
                
                Divider()
                
                // MARK: Timeline Details
                VStack(alignment: .leading, spacing: 12) {
                    Text("Usage History").font(.headline)
                    DetailInfoRow(icon: "calendar", label: "First Used", value: app.firstSeen.formatted(date: .abbreviated, time: .omitted))
                    DetailInfoRow(icon: "clock.arrow.circlepath", label: "Last Used", value: app.lastSeen.formatted(date: .abbreviated, time: .shortened))
                }
                
                // MARK: granular Window list
                if !windows.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Top Windows").font(.headline)
                        ForEach(windows.prefix(5)) { window in
                            HStack {
                                Text(window.title.isEmpty ? "Untitled" : window.title).font(.system(size: 13)).lineLimit(1)
                                Spacer()
                                Text(window.formattedTotalTime()).font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .frame(minWidth: 280)
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            // Load window-level tracking data for this specific app
            windows = UsageDatabase.shared.getWindows(for: app.id.uuidString)
        }
        .sheet(isPresented: $editingCategory) {
            AppCategoryPickerView(app: app, onComplete: onCategoryChanged)
        }
    }
}
