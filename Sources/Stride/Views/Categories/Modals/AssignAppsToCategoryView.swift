import SwiftUI

/**
 * AssignAppsToCategoryView - Modal for assigning apps to a category
 *
 * Aesthetic: Warm Paper/Editorial Light
 * - Warm cream/paper backgrounds
 * - Clean white cards with soft shadows
 * - Animated search and list
 * - Visual selection feedback
 */
struct AssignAppsToCategoryView: View {
    let category: Category
    let onComplete: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var allApps: [AppUsage] = []
    @State private var selectedAppIds: Set<String> = []
    @State private var searchText = ""
    @State private var isAnimating = false
    @State private var hoveredAppId: String?
    
    private let backgroundColor = Color(red: 0.98, green: 0.973, blue: 0.957)
    private let cardBackground = Color.white
    private let accentColor = Color(red: 0.78, green: 0.357, blue: 0.224)
    private let textColor = Color(red: 0.173, green: 0.173, blue: 0.173)
    private let secondaryText = Color(red: 0.38, green: 0.38, blue: 0.38)
    
    var filteredApps: [AppUsage] {
        if searchText.isEmpty {
            return allApps
        }
        return allApps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var selectionCount: Int {
        selectedAppIds.count
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    searchBar
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                    
                    // Apps list
                    appsList
                }
            }
            .navigationTitle("Assign to \(category.name)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(secondaryText)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        assignApps()
                    }
                    .foregroundColor(accentColor)
                    .font(.system(size: 15, weight: .semibold))
                }
            }
        }
        .frame(width: 420, height: 550)
        .onAppear {
            loadApps()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(secondaryText.opacity(0.7))
            
            TextField("Search apps", text: $searchText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(textColor)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(secondaryText.opacity(0.6))
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
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
                        .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Apps List
    private var appsList: some View {
        List {
            Section {
                if filteredApps.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 28, weight: .light))
                                .foregroundColor(secondaryText.opacity(0.5))
                            
                            Text("No apps found")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(secondaryText)
                        }
                        .padding(.vertical, 40)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(Array(filteredApps.enumerated()), id: \.element.id) { index, app in
                        AppSelectionRow(
                            app: app,
                            isSelected: selectedAppIds.contains(app.id.uuidString),
                            isHovered: hoveredAppId == app.id.uuidString,
                            categoryColor: category.color
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleAppSelection(app.id.uuidString)
                        }
                        .onHover { hovering in
                            hoveredAppId = hovering ? app.id.uuidString : nil
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
                        .offset(y: isAnimating ? 0 : 10)
                        .opacity(isAnimating ? 1 : 0)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.75)
                            .delay(Double(index) * 0.01),
                            value: isAnimating
                        )
                    }
                }
            } header: {
                HStack {
                    Text("\(filteredApps.count) Apps")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(secondaryText.opacity(0.8))
                        .textCase(.uppercase)
                    
                    Spacer()
                    
                    if selectionCount > 0 {
                        Text("\(selectionCount) selected")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(accentColor)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    // MARK: - Selection Footer
    private var selectionFooter: some View {
        HStack(spacing: 12) {
            Text("\(selectionCount) app\(selectionCount == 1 ? "" : "s") selected")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(textColor)
            
            Spacer()
            
            // Only show selection count, no save button here - use Done in toolbar
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            Rectangle()
                .fill(cardBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: -2)
                .overlay(
                    Rectangle()
                        .fill(Color.black.opacity(0.06))
                        .frame(height: 1),
                    alignment: .top
                )
        )
    }
    
    // MARK: - Actions
    private func toggleAppSelection(_ appId: String) {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
            if selectedAppIds.contains(appId) {
                selectedAppIds.remove(appId)
            } else {
                selectedAppIds.insert(appId)
            }
        }
    }
    
    private func loadApps() {
        allApps = UsageDatabase.shared.getAllApplications()
        selectedAppIds = Set(allApps.filter { $0.categoryId == category.id.uuidString }.map { $0.id.uuidString })
    }
    
    private func assignApps() {
        for appId in selectedAppIds {
            UsageDatabase.shared.updateAppCategory(appId: appId, categoryId: category.id.uuidString)
        }
        
        let unselectedApps = allApps.filter { !selectedAppIds.contains($0.id.uuidString) && $0.categoryId == category.id.uuidString }
        for app in unselectedApps {
            UsageDatabase.shared.updateAppCategory(appId: app.id.uuidString, categoryId: "uncategorized")
        }
        
        // Notify parent that assignment is complete
        onComplete?()
        
        dismiss()
    }
}

// MARK: - App Selection Row
private struct AppSelectionRow: View {
    let app: AppUsage
    let isSelected: Bool
    let isHovered: Bool
    let categoryColor: String
    
    private let textColor = Color(red: 0.173, green: 0.173, blue: 0.173)
    private let secondaryText = Color(red: 0.38, green: 0.38, blue: 0.38)
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator
            ZStack {
                Circle()
                    .fill(isSelected ? Color(hex: categoryColor).opacity(0.15) : Color.black.opacity(0.04))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                isSelected ? Color(hex: categoryColor).opacity(0.5) : Color.black.opacity(0.12),
                                lineWidth: 1.5
                            )
                    )
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: categoryColor))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isSelected)
            
            // App name
            Text(app.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(textColor)
            
            Spacer()
            
            // Current category indicator
            if app.categoryId != "uncategorized" && !isSelected {
                Circle()
                    .fill(Color(hex: app.getCategory().color).opacity(0.7))
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isHovered ? Color.black.opacity(0.03) : Color.clear)
        )
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}
