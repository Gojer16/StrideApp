import SwiftUI

/**
 * AppCategoryPickerView - A focused selection modal for individual app labeling.
 * 
 * This component is primarily triggered from the `AppDetailSidebar` in the `AllAppsView`.
 * It provides a clean, single-purpose interface for assigning an application 
 * to a specific organizational category.
 * 
 * **Functionality:**
 * - Selection: Users click a category to instantly update the app's metadata.
 * - Auto-Dismiss: Closes automatically after a successful assignment.
 * - Feedback: Triggers an `onComplete` callback to notify parent views 
 *   that the database has changed.
 * 
 * **Data Flow:**
 * - Reads all available categories from `UsageDatabase`.
 * - Writes the new `category_id` to the `applications` table using a thread-safe sync operation.
 */
struct AppCategoryPickerView: View {
    /// The application being re-labeled
    let app: AppUsage
    
    /// Callback triggered after a selection is made
    var onComplete: (() -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    @State private var categories: [Category] = []
    @State private var isAnimating = false
    @State private var hoveredCategoryId: UUID?
    @State private var selectedCategoryId: String?
    
    private let backgroundColor = Color(red: 0.98, green: 0.973, blue: 0.957)
    private let cardBackground = Color.white
    private let accentColor = Color(red: 0.78, green: 0.357, blue: 0.224)
    private let textColor = Color(red: 0.173, green: 0.173, blue: 0.173)
    private let secondaryText = Color(red: 0.38, green: 0.38, blue: 0.38)
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: App Context Header
                    appHeader
                        .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 16)
                    
                    // MARK: Selectable List
                    categoriesList
                }
            }
            .navigationTitle("Select Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(secondaryText)
                }
            }
        }
        .frame(width: 340, height: 480)
        .onAppear {
            categories = UsageDatabase.shared.getAllCategories()
            selectedCategoryId = app.categoryId
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
    }
    
    // MARK: - Subviews
    
    private var appHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(LinearGradient(colors: [accentColor.opacity(0.15), accentColor.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 48, height: 48)
                Image(systemName: "app.fill").font(.system(size: 22, weight: .medium)).foregroundColor(accentColor)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Assign Category").font(.system(size: 12, weight: .medium)).foregroundColor(secondaryText).textCase(.uppercase)
                Text(app.name).font(.system(size: 17, weight: .semibold)).foregroundColor(textColor).lineLimit(1)
            }
            Spacer()
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(cardBackground).shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3))
        .scaleEffect(isAnimating ? 1.0 : 0.95).opacity(isAnimating ? 1 : 0)
    }
    
    private var categoriesList: some View {
        List {
            Section {
                ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                    CategorySelectionRow(category: category, isSelected: selectedCategoryId == category.id.uuidString.lowercased(), isHovered: hoveredCategoryId == category.id)
                        .contentShape(Rectangle())
                        .onTapGesture { selectCategory(category) }
                        .onHover { hovering in hoveredCategoryId = hovering ? category.id : nil }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
                        .offset(y: isAnimating ? 0 : 15).opacity(isAnimating ? 1 : 0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.75).delay(0.1 + Double(index) * 0.03), value: isAnimating)
                }
            } header: {
                Text("\(categories.count) Categories").font(.system(size: 11, weight: .medium)).foregroundColor(secondaryText.opacity(0.8)).textCase(.uppercase).padding(.horizontal, 4).padding(.vertical, 8)
            }
        }
        .listStyle(.plain).scrollContentBackground(.hidden)
    }
    
    // MARK: - Actions
    
    private func selectCategory(_ category: Category) {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
            selectedCategoryId = category.id.uuidString.lowercased()
        }
        
        // Persist change to database
        UsageDatabase.shared.updateAppCategory(appId: app.id.uuidString, categoryId: category.id.uuidString)
        
        // Notify parent views to refresh
        onComplete?()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            dismiss()
        }
    }
}

/**
 * CategorySelectionRow - Individual selectable row within the category picker list.
 */
private struct CategorySelectionRow: View {
    let category: Category
    let isSelected: Bool
    let isHovered: Bool
    
    private let accentColor = Color(red: 0.78, green: 0.357, blue: 0.224)
    private let textColor = Color(red: 0.173, green: 0.173, blue: 0.173)
    private let secondaryText = Color(red: 0.38, green: 0.38, blue: 0.38)
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color(hex: category.color).opacity(0.12)).frame(width: 34, height: 34)
                Image(systemName: category.icon).font(.system(size: 14, weight: .medium)).foregroundColor(Color(hex: category.color))
            }
            Text(category.name).font(.system(size: 14, weight: .medium)).foregroundColor(textColor)
            Spacer()
            if isSelected {
                ZStack {
                    Circle().fill(accentColor.opacity(0.15)).frame(width: 26, height: 26)
                    Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundColor(accentColor)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(isSelected ? accentColor.opacity(0.08) : (isHovered ? Color.black.opacity(0.04) : Color.clear)))
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isSelected)
    }
}
