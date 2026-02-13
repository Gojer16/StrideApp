import SwiftUI

/**
 * CategoryAppsListView - A detailed list of apps within a specific category.
 * 
 * This component is used as the "Detail" side of the `CategoryManagementView` split layout.
 * It provides the primary interface for **Bulk Assignment**—allowing users to add
 * or remove multiple apps from a category at once.
 * 
 * **Behaviors:**
 * - Auto-Loading: Fetches the app list for its assigned category immediately on appear.
 * - Reactive: Listens for dismissals of the `AssignAppsToCategoryView` to refresh the local state.
 * - Feedback: Triggers `onAppsChanged` so the parent view can update counts in the category list.
 */
struct CategoryAppsListView: View {
    /// The parent category being inspected
    let category: Category
    
    @State private var apps: [AppUsage] = []
    @State private var showingAssignApps = false
    @State private var isAnimating = false
    @State private var hoveredAppId: UUID?
    
    /// Callback triggered whenever apps are added or removed from this category
    var onAppsChanged: (() -> Void)?
    
    init(category: Category, onAppsChanged: (() -> Void)? = nil) {
        self.category = category
        self.onAppsChanged = onAppsChanged
    }
    
    private let backgroundColor = Color(red: 0.98, green: 0.973, blue: 0.957)
    private let cardBackground = Color.white
    private let accentColor = Color(red: 0.78, green: 0.357, blue: 0.224)
    private let textColor = Color(red: 0.173, green: 0.173, blue: 0.173)
    private let secondaryText = Color(red: 0.38, green: 0.38, blue: 0.38)
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            if apps.isEmpty {
                emptyStateView
            } else {
                appsListView
            }
        }
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(cardBackground).shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 3))
        .padding(.trailing, 20).padding(.bottom, 20)
        .onAppear {
            // MARK: Initial Data Fetch
            loadCategoryApps()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
        .sheet(isPresented: $showingAssignApps, onDismiss: {
            // MARK: Sync on Dismiss
            self.loadCategoryApps()
            self.onAppsChanged?()
        }) {
            // MARK: Bulk Assignment Trigger
            AssignAppsToCategoryView(category: category, onComplete: {
                self.loadCategoryApps()
                self.onAppsChanged?()
            })
        }
    }
    
    // MARK: - Layout Sections
    
    private var headerView: some View {
        HStack(alignment: .center, spacing: 16) {
            // Category Icon with Brand Glow
            ZStack {
                Circle().fill(RadialGradient(colors: [Color(hex: category.color).opacity(0.2), Color(hex: category.color).opacity(0.05)], center: .center, startRadius: 0, endRadius: 30)).frame(width: 56, height: 56)
                Image(systemName: category.icon).font(.system(size: 24, weight: .medium)).foregroundColor(Color(hex: category.color))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name).font(.system(size: 22, weight: .bold)).foregroundColor(textColor)
                HStack(spacing: 6) {
                    Text("\(apps.count) app\(apps.count == 1 ? "" : "s")").font(.system(size: 13, weight: .medium)).foregroundColor(secondaryText)
                    if apps.count > 0 {
                        Text("•").font(.system(size: 10)).foregroundColor(secondaryText.opacity(0.5))
                        Text(totalTimeFormatted()).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundColor(accentColor)
                    }
                }
            }
            Spacer()
            // Bulk Edit Button
            Button(action: { showingAssignApps = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus").font(.system(size: 11, weight: .semibold))
                    Text("Assign Apps").font(.system(size: 12, weight: .semibold))
                }
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Capsule().fill(Color.black.opacity(0.05)).overlay(Capsule().strokeBorder(Color.black.opacity(0.1), lineWidth: 1)))
                .foregroundColor(textColor)
            }
            .buttonStyle(.plain)
            .scaleEffect(isAnimating ? 1.0 : 0.9).opacity(isAnimating ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.2), value: isAnimating)
        }
        .padding(.horizontal, 20).padding(.vertical, 20)
        .background(LinearGradient(colors: [Color(hex: category.color).opacity(0.06), Color.clear], startPoint: .top, endPoint: .bottom))
        .overlay(Rectangle().fill(Color.black.opacity(0.06)).frame(height: 1), alignment: .bottom)
    }
    
    private var appsListView: some View {
        List {
            Section {
                ForEach(Array(apps.enumerated()), id: \.element.id) { index, app in
                    AppRowItem(app: app, categoryColor: category.color, isHovered: hoveredAppId == app.id)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
                        .onHover { isHovered in hoveredAppId = isHovered ? app.id : nil }
                        .offset(y: isAnimating ? 0 : 15).opacity(isAnimating ? 1 : 0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.75).delay(0.1 + Double(index) * 0.03), value: isAnimating)
                }
            }
        }
        .listStyle(.plain).scrollContentBackground(.hidden).padding(.vertical, 8)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle().fill(RadialGradient(colors: [Color(hex: category.color).opacity(0.12), Color.clear], center: .center, startRadius: 0, endRadius: 60)).frame(width: 120, height: 120)
                Image(systemName: "app.badge.checkmark").font(.system(size: 40, weight: .light)).foregroundColor(Color(hex: category.color).opacity(0.7))
            }
            VStack(spacing: 8) {
                Text("No Apps Assigned").font(.system(size: 18, weight: .semibold)).foregroundColor(textColor)
                Text("Add apps to track their time in this category").font(.system(size: 13)).foregroundColor(secondaryText)
            }
            Button(action: { showingAssignApps = true }) {
                Text("Assign Apps").font(.system(size: 13, weight: .semibold)).padding(.horizontal, 20).padding(.vertical, 10).background(Capsule().fill(Color(hex: category.color).opacity(0.15)).overlay(Capsule().strokeBorder(Color(hex: category.color).opacity(0.3), lineWidth: 1))).foregroundColor(Color(hex: category.color))
            }
            .buttonStyle(.plain).padding(.top, 4)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helpers
    
    private func totalTimeFormatted() -> String {
        let total = apps.reduce(0) { $0 + $1.totalTimeSpent }
        return total.formatted()
    }
    
    /**
     * Queries the database for all apps matching this category's ID.
     */
    private func loadCategoryApps() {
        let refreshedApps = UsageDatabase.shared.getApplicationsByCategory(categoryId: category.id.uuidString)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            apps = refreshedApps
        }
    }
}

/**
 * AppRowItem - A lightweight row for listing apps within a category container.
 */
private struct AppRowItem: View {
    let app: AppUsage
    let categoryColor: String
    let isHovered: Bool
    
    private let textColor = Color(red: 0.173, green: 0.173, blue: 0.173)
    private let secondaryText = Color(red: 0.38, green: 0.38, blue: 0.38)
    
    var body: some View {
        HStack(spacing: 14) {
            Text(app.name).font(.system(size: 14, weight: .medium)).foregroundColor(textColor)
            Spacer()
            // High-impact time badge
            HStack(spacing: 4) {
                Image(systemName: "clock").font(.system(size: 10, weight: .medium))
                Text(app.formattedTotalTime()).font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Capsule().fill(isHovered ? Color(hex: categoryColor).opacity(0.15) : Color.black.opacity(0.04)))
            .foregroundColor(isHovered ? Color(hex: categoryColor) : secondaryText)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(isHovered ? Color.black.opacity(0.03) : Color.clear))
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}
