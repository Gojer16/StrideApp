import SwiftUI

/**
 * CategoryEditorView - Modal for creating/editing categories
 *
 * Aesthetic: Warm Paper/Editorial Light
 * - Warm cream/paper backgrounds
 * - Clean white cards with soft shadows
 * - Live preview with subtle glow effect
 * - Smooth form interactions
 */
struct CategoryEditorView: View {
    let category: Category?
    let onSave: (Category) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedIcon = "folder"
    @State private var selectedColor = "#3498DB"
    @State private var isAnimating = false
    @State private var hoveredIcon: String?
    @State private var hoveredColor: String?
    
    private let backgroundColor = Color(red: 0.98, green: 0.973, blue: 0.957)
    private let cardBackground = Color.white
    private let accentColor = Color(red: 0.78, green: 0.357, blue: 0.224)
    private let textColor = Color(red: 0.173, green: 0.173, blue: 0.173)
    private let secondaryText = Color(red: 0.38, green: 0.38, blue: 0.38)
    
    let availableIcons = [
        "folder", "briefcase.fill", "play.circle.fill", "person.2.fill",
        "checkmark.circle.fill", "chevron.left.forwardslash.chevron.right",
        "message.fill", "wrench.fill", "gamecontroller.fill", "book.fill",
        "music.note", "photo.fill", "video.fill", "cart.fill",
        "house.fill", "building.2.fill", "graduationcap.fill", "heart.fill",
        "star.fill", "flag.fill", "tag.fill", "bell.fill"
    ]
    
    let availableColors = [
        "#FF6B6B", "#FF8E53", "#FFCD56", "#4BC0C0", "#36A2EB",
        "#9966FF", "#C9CBCF", "#FF99CC", "#99CCFF", "#99FF99",
        "#FFB366", "#66FFB3", "#B366FF", "#FF66B3", "#66B3FF"
    ]
    
    var isEditing: Bool {
        category != nil
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        previewSection
                            .padding(.top, 8)
                        
                        nameSection
                        
                        iconSection
                        
                        colorSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle(isEditing ? "Edit Category" : "New Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(secondaryText)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCategory()
                    }
                    .disabled(name.isEmpty)
                    .foregroundColor(name.isEmpty ? secondaryText.opacity(0.4) : accentColor)
                    .font(.system(size: 15, weight: .semibold))
                }
            }
        }
        .frame(width: 420, height: 580)
        .onAppear {
            if let category = category {
                name = category.name
                selectedIcon = category.icon
                selectedColor = category.color
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
    }
    
    // MARK: - Preview Section
    private var previewSection: some View {
        VStack(spacing: 12) {
            Text("Preview")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(secondaryText.opacity(0.8))
                .textCase(.uppercase)
            
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: selectedColor).opacity(0.25),
                                Color(hex: selectedColor).opacity(0.08)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 15)
                
                // Icon container
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: selectedColor).opacity(0.2),
                                Color(hex: selectedColor).opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(
                                Color(hex: selectedColor).opacity(0.4),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: Color(hex: selectedColor).opacity(0.15), radius: 12, x: 0, y: 4)
                
                Image(systemName: selectedIcon)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(Color(hex: selectedColor))
                    .symbolRenderingMode(.hierarchical)
            }
            
            Text(name.isEmpty ? "Category Name" : name)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(name.isEmpty ? secondaryText.opacity(0.6) : textColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 3)
        )
        .scaleEffect(isAnimating ? 1.0 : 0.95)
        .opacity(isAnimating ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isAnimating)
    }
    
    // MARK: - Name Section
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Name")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(textColor.opacity(0.9))
            
            TextField("", text: $name)
                .font(.system(size: 15, weight: .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(cardBackground)
                        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
                        )
                )
                .foregroundColor(textColor)
                .textFieldStyle(.plain)
        }
    }
    
    // MARK: - Icon Section
    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Icon")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(textColor.opacity(0.9))
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 48, maximum: 48))], spacing: 10) {
                ForEach(Array(availableIcons.enumerated()), id: \.element) { index, icon in
                    IconButton(
                        icon: icon,
                        isSelected: selectedIcon == icon,
                        isHovered: hoveredIcon == icon,
                        color: selectedColor
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedIcon = icon
                        }
                    }
                    .onHover { hovering in
                        hoveredIcon = hovering ? icon : nil
                    }
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .opacity(isAnimating ? 1 : 0)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.7)
                        .delay(0.1 + Double(index) * 0.01),
                        value: isAnimating
                    )
                }
            }
        }
    }
    
    // MARK: - Color Section
    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(textColor.opacity(0.9))
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 36, maximum: 36))], spacing: 12) {
                ForEach(Array(availableColors.enumerated()), id: \.element) { index, color in
                    ColorButton(
                        color: color,
                        isSelected: selectedColor == color,
                        isHovered: hoveredColor == color
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedColor = color
                        }
                    }
                    .onHover { hovering in
                        hoveredColor = hovering ? color : nil
                    }
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .opacity(isAnimating ? 1 : 0)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.7)
                        .delay(0.15 + Double(index) * 0.01),
                        value: isAnimating
                    )
                }
            }
        }
    }
    
    // MARK: - Save
    private func saveCategory() {
        let newCategory: Category
        if let existing = category {
            newCategory = Category(
                id: existing.id,
                name: name,
                icon: selectedIcon,
                color: selectedColor,
                order: existing.order,
                isDefault: existing.isDefault
            )
            UsageDatabase.shared.updateCategory(newCategory)
        } else {
            let categories = UsageDatabase.shared.getAllCategories()
            let newOrder = categories.count
            newCategory = Category(
                name: name,
                icon: selectedIcon,
                color: selectedColor,
                order: newOrder
            )
            UsageDatabase.shared.createCategory(newCategory)
        }
        onSave(newCategory)
        dismiss()
    }
}

// MARK: - Icon Button
private struct IconButton: View {
    let icon: String
    let isSelected: Bool
    let isHovered: Bool
    let color: String
    
    private let cardBackground = Color.white
    private let secondaryText = Color(red: 0.38, green: 0.38, blue: 0.38)
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? Color(hex: color).opacity(0.15) : cardBackground)
                .shadow(color: Color.black.opacity(isSelected ? 0.06 : 0.03), radius: isSelected ? 6 : 3, x: 0, y: isSelected ? 3 : 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            isSelected ? Color(hex: color).opacity(0.5) : (isHovered ? Color.black.opacity(0.15) : Color.black.opacity(0.06)),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
            
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isSelected ? Color(hex: color) : secondaryText.opacity(0.7))
        }
        .frame(width: 48, height: 48)
        .scaleEffect(isHovered && !isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isSelected)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}

// MARK: - Color Button
private struct ColorButton: View {
    let color: String
    let isSelected: Bool
    let isHovered: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: color))
                .frame(width: 36, height: 36)
                .shadow(color: Color(hex: color).opacity(0.3), radius: isSelected ? 6 : 3, x: 0, y: isSelected ? 3 : 2)
            
            if isSelected {
                Circle()
                    .strokeBorder(Color.white, lineWidth: 3)
                    .frame(width: 36, height: 36)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
        }
        .scaleEffect(isSelected ? 1.1 : (isHovered ? 1.05 : 1.0))
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isSelected)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}
