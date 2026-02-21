import SwiftUI

/**
 * AllAppsView - The primary Data Hub for Stride.
 * 
 * This view provides a high-level overview of every application tracked by the system.
 * It serves as the "Big Picture" tab where users can search, sort, and filter their 
 * entire usage history.
 * 
 * **Architecture:**
 * - Uses a `NavigationSplitView` to balance a high-density grid with a detailed sidebar.
 * - `mainContent`: A searchable grid of `AppGridCard` components.
 * - `detailSidebar`: An `AppDetailSidebar` that opens when an app is selected.
 * 
 * **Data Flow:**
 * - Fetches all apps from `UsageDatabase` on appear.
 * - Triggers a re-load whenever the `selectedApp` changes or an app's category is updated.
 */
struct AllAppsView: View {
    @State private var applications: [AppUsage] = []
    @State private var searchText = ""
    @State private var sortOrder: SortOrder = .time
    @State private var selectedCategory: Category?
    @State private var categories: [Category] = []
    @State private var isAnimating = false
    @State private var selectedApp: AppUsage?
    
    private let backgroundColor = Color(red: 0.98, green: 0.973, blue: 0.957)
    private let cardBackground = Color.white
    private let accentColor = Color(red: 0.78, green: 0.357, blue: 0.224)
    private let textColor = Color(red: 0.173, green: 0.173, blue: 0.173)
    private let secondaryText = Color(red: 0.38, green: 0.38, blue: 0.38)
    
    enum SortOrder: String, CaseIterable {
        case time = "Time"
        case name = "Name"
        case visits = "Visits"
    }
    
    /// Logic for filtering the grid based on search text and category selection
    var filteredApps: [AppUsage] {
        var apps = applications
        
        if let category = selectedCategory {
            apps = apps.filter { $0.categoryId == category.id.uuidString.lowercased() }
        }
        
        if !searchText.isEmpty {
            apps = apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        switch sortOrder {
        case .time:
            apps.sort { $0.totalTimeSpent > $1.totalTimeSpent }
        case .name:
            apps.sort { $0.name < $1.name }
        case .visits:
            apps.sort { $0.visitCount > $1.visitCount }
        }
        
        return apps
    }
    
    var body: some View {
        NavigationSplitView {
            mainContent
        } detail: {
            if let app = selectedApp {
                // The Sidebar provides the actual "Edit" capability for individual apps
                AppDetailSidebar(app: app, selectedApp: $selectedApp, onCategoryChanged: {
                    loadData()
                })
                .id(app.id) // Force redraw when selection changes to update stats
            } else {
                EmptyDetailView(
                    title: "Select an App",
                    subtitle: "Choose an application from the list to see detailed usage statistics and manage its category.",
                    icon: "app.fill"
                )
            }
        }
        .onAppear {
            loadData()
            withAnimation(DesignSystem.Animation.entrance.spring) {
                isAnimating = true
            }
        }
        .onChange(of: selectedApp) {
            // Refresh data when selection changes to ensure the grid reflects sidebar changes
            loadData()
        }
    }
    
    /// The left-side (or primary) container holding the header and the grid
    private var mainContent: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header: Search, Category Filter, and Sort
                headerView
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 20)
                
                if filteredApps.isEmpty {
                    emptyStateView
                } else {
                    appsGridView
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        VStack(spacing: 20) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("All Apps")
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundColor(textColor)
                    
                    Text("\(filteredApps.count) application\(filteredApps.count == 1 ? "" : "s")")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(secondaryText)
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                // Search bar
                searchBar
                
                // Category filter menu
                categoryFilterMenu
                
                // Sort segmented picker
                sortPicker
            }
        }
    }
    
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(secondaryText.opacity(0.7))
            
            TextField("Search apps...", text: $searchText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(textColor)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(secondaryText.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(cardBackground)
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                )
        )
        .frame(maxWidth: .infinity)
    }
    
    private var categoryFilterMenu: some View {
        Menu {
            Button("All Categories") {
                selectedCategory = nil
            }
            
            Divider()
            
            ForEach(categories) { category in
                Button(category.name) {
                    selectedCategory = category
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: selectedCategory?.icon ?? "line.3.horizontal.decrease.circle")
                    .font(.system(size: 14, weight: .medium))
                Text(selectedCategory?.name ?? "Filter")
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(selectedCategory != nil ? Color(hex: selectedCategory!.color).opacity(0.12) : cardBackground)
                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(
                                selectedCategory != nil ? Color(hex: selectedCategory!.color).opacity(0.3) : Color.black.opacity(0.08),
                                lineWidth: 1
                            )
                    )
            )
            .foregroundColor(selectedCategory != nil ? Color(hex: selectedCategory!.color) : textColor)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
    
    private var sortPicker: some View {
        Picker("", selection: $sortOrder) {
            ForEach(SortOrder.allCases, id: \.self) { order in
                Text(order.rawValue)
                    .tag(order)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 200)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle().fill(accentColor.opacity(0.1)).frame(width: 160, height: 160)
                Image(systemName: "magnifyingglass").font(.system(size: 48, weight: .light)).foregroundColor(accentColor.opacity(0.6))
            }
            VStack(spacing: 8) {
                Text("No Apps Found").font(.system(size: 20, weight: .semibold)).foregroundColor(textColor)
                Text("Try adjusting your search or filters").font(.system(size: 14)).foregroundColor(secondaryText)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var appsGridView: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 300), spacing: 16)],
                spacing: 16
            ) {
                ForEach(Array(filteredApps.enumerated()), id: \.element.id) { index, app in
                    AppGridCard(app: app)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(accentColor, lineWidth: selectedApp?.id == app.id ? 2 : 0)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // Selecting an app opens the Detail Sidebar
                            selectedApp = app
                        }
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                        .animation(DesignSystem.Animation.entrance.spring.delay(Double(index) * 0.03), value: isAnimating)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Data Loading
    
    /**
     * Refreshes the local application and category lists from the database.
     * 
     * Ensures that any changes made in other tabs (like Categories) 
     * are reflected here.
     */
    private func loadData() {
        applications = UsageDatabase.shared.getAllApplications()
        categories = UsageDatabase.shared.getAllCategories()
    }
}
