import SwiftUI

/**
 Sidebar showing detailed information about a selected app.
 
 Displays:
 - App icon and name
 - Category with edit button
 - Usage statistics (total, today, visits, windows)
 - First/last used dates
 - Top windows by time spent
 */
struct AppDetailSidebar: View {
    let app: AppUsage
    @Binding var selectedApp: AppUsage?
    var onCategoryChanged: (() -> Void)? = nil
    @State private var windows: [WindowUsage] = []
    @State private var editingCategory = false
    
    var body: some View {
        let category = app.getCategory()
        
        ScrollView {
            VStack(spacing: 24) {
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
                    
                    Button(action: { editingCategory = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 10))
                            Text(category.name)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color(hex: category.color).opacity(0.15))
                        )
                        .foregroundColor(Color(hex: category.color))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 20)
                
                Divider()
                
                let todayTime = UsageDatabase.shared.getTodayTime(for: app.id.uuidString)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    DetailStatBox(value: app.formattedTotalTime(), label: "Total", icon: "clock")
                    DetailStatBox(value: todayTime.formatted(), label: "Today", icon: "sun.max")
                    DetailStatBox(value: "\(app.visitCount)", label: "Visits", icon: "arrow.counterclockwise")
                    DetailStatBox(value: "\(windows.count)", label: "Windows", icon: "uiwindow.split.2x1")
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Usage History")
                        .font(.headline)
                    
                    DetailInfoRow(icon: "calendar", label: "First Used", value: app.firstSeen.formatted(date: .abbreviated, time: .omitted))
                    DetailInfoRow(icon: "clock.arrow.circlepath", label: "Last Used", value: app.lastSeen.formatted(date: .abbreviated, time: .shortened))
                }
                
                if !windows.isEmpty {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Top Windows")
                            .font(.headline)
                        
                        ForEach(windows.prefix(5)) { window in
                            HStack {
                                Text(window.title.isEmpty ? "Untitled" : window.title)
                                    .font(.system(size: 13))
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text(window.formattedTotalTime())
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(.secondary)
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
            windows = UsageDatabase.shared.getWindows(for: app.id.uuidString)
        }
        .sheet(isPresented: $editingCategory) {
            AppCategoryPickerView(app: app, onComplete: onCategoryChanged)
        }
    }
}
