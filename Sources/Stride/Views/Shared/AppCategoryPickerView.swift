import SwiftUI

/**
 * AppCategoryPickerView - Modal for selecting a category for an app
 *
 * Aesthetic: Warm Paper/Editorial Light
 * - Warm cream/paper backgrounds
 * - Clean white cards with soft shadows
 * - Animated category list
 * - Visual selection feedback
 */
struct AppCategoryPickerView: View {
    let app: AppUsage
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
                backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // App info header
                    appHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 16)
                    
                    // Categories list
                    categoriesList
                }
            }
            .navigationTitle("Select Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(secondaryText)
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
    
    // MARK: - App Header
    private var appHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                accentColor.opacity(0.15),
                                accentColor.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(accentColor.opacity(0.25), lineWidth: 1)
                    )
                
                Image(systemName: "app.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(accentColor)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Assign Category")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(secondaryText)
                    .textCase(.uppercase)
                
                Text(app.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(textColor)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(cardBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        )
        .scaleEffect(isAnimating ? 1.0 : 0.95)
        .opacity(isAnimating ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isAnimating)
    }
    
    // MARK: - Categories List
    private var categoriesList: some View {
        List {
            Section {
                ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                    CategorySelectionRow(
                        category: category,
                        isSelected: selectedCategoryId == category.id.uuidString,
                        isHovered: hoveredCategoryId == category.id
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectCategory(category)
                    }
                    .onHover { hovering in
                        hoveredCategoryId = hovering ? category.id : nil
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
                    .offset(y: isAnimating ? 0 : 15)
                    .opacity(isAnimating ? 1 : 0)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.75)
                        .delay(0.1 + Double(index) * 0.03),
                        value: isAnimating
                    )
                }
            } header: {
                Text("\(categories.count) Categories")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(secondaryText.opacity(0.8))
                    .textCase(.uppercase)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    // MARK: - Actions
    private func selectCategory(_ category: Category) {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
            selectedCategoryId = category.id.uuidString
        }
        
        UsageDatabase.shared.updateAppCategory(appId: app.id.uuidString, categoryId: category.id.uuidString)
        
        onComplete?()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            dismiss()
        }
    }
}

// MARK: - Category Selection Row
private struct CategorySelectionRow: View {
    let category: Category
    let isSelected: Bool
    let isHovered: Bool
    
    private let accentColor = Color(red: 0.78, green: 0.357, blue: 0.224)
    private let textColor = Color(red: 0.173, green: 0.173, blue: 0.173)
    private let secondaryText = Color(red: 0.38, green: 0.38, blue: 0.38)
    
    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            ZStack {
                Circle()
                    .fill(Color(hex: category.color).opacity(0.12))
                    .frame(width: 34, height: 34)
                
                Image(systemName: category.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: category.color))
            }
            
            // Category name
            Text(category.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(textColor)
            
            Spacer()
            
            // Selection checkmark
            if isSelected {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 26, height: 26)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(accentColor)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(backgroundFill)
        )
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isSelected)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
    
    private var backgroundFill: Color {
        if isSelected {
            return accentColor.opacity(0.08)
        } else if isHovered {
            return Color.black.opacity(0.04)
        } else {
            return Color.clear
        }
    }
}
