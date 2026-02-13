import SwiftUI

/**
 * CategoryManagementView - Main view for managing app categories
 *
 * Aesthetic: Warm Paper/Editorial Light
 * - Warm cream/paper backgrounds (#F5F1EB, #FAF8F5)
 * - Soft charcoal text (#2C2C2C, #3D3D3D)
 * - Terracotta/ochre accents (#C75B39, #D4A574)
 * - Clean cards with soft shadows
 * - Smooth spring animations
 */
struct CategoryManagementView: View {
    @State private var categories: [Category] = []
    @State private var showingAddCategory = false
    @State private var editingCategory: Category?
    @State private var selectedCategory: Category?
    @State private var isAnimating = false
    
    private let backgroundColor = Color(red: 0.98, green: 0.973, blue: 0.957)
    private let cardBackground = Color.white
    private let accentColor = Color(red: 0.78, green: 0.357, blue: 0.224)
    private let textColor = Color(red: 0.173, green: 0.173, blue: 0.173)
    private let secondaryText = Color(red: 0.38, green: 0.38, blue: 0.38)
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                    .padding(.horizontal, 28)
                    .padding(.top, 24)
                    .padding(.bottom, 20)
                
                if categories.isEmpty {
                    emptyStateView
                        .transition(.opacity.combined(with: .scale))
                } else {
                    contentSplitView
                        .transition(.opacity)
                }
            }
        }
        .onAppear {
            loadData()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            CategoryEditorView(category: nil) { _ in
                loadData()
            }
        }
        .sheet(item: $editingCategory) { category in
            CategoryEditorView(category: category) { _ in
                loadData()
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Categories")
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundColor(textColor)
                
                Text("Organize and manage your app categories")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(secondaryText)
            }
            
            Spacer()
            
            Button(action: { showingAddCategory = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                    Text("New Category")
                        .font(.system(size: 13, weight: .semibold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(accentColor)
                        .shadow(color: accentColor.opacity(0.3), radius: 8, x: 0, y: 3)
                )
                .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .scaleEffect(isAnimating ? 1.0 : 0.95)
            .opacity(isAnimating ? 1.0 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: isAnimating)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accentColor.opacity(0.12), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(accentColor.opacity(0.8))
            }
            
            VStack(spacing: 8) {
                Text("No Categories Yet")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(textColor)
                
                Text("Create your first category to start organizing apps")
                    .font(.system(size: 14))
                    .foregroundColor(secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showingAddCategory = true }) {
                Text("Create Category")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .strokeBorder(accentColor, lineWidth: 1.5)
                    )
                    .foregroundColor(accentColor)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Content Split View
    private var contentSplitView: some View {
        GeometryReader { geometry in
            HSplitView {
                categoriesListView
                    .frame(minWidth: 280, idealWidth: 320, maxWidth: 380)
                
                if let category = selectedCategory {
                    CategoryAppsListView(
                        category: category, 
                        onAppsChanged: {
                            // Reload categories to update counts in the list
                            self.loadData()
                        }
                    )
                    .frame(minWidth: 400)
                    .id(category.id)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    selectionPromptView
                        .frame(minWidth: 400)
                }
            }
        }
    }
    
    // MARK: - Categories List
    private var categoriesListView: some View {
        VStack(spacing: 0) {
            List(selection: $selectedCategory) {
                Section {
                    ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                        CategoryRow(category: category, isSelected: selectedCategory?.id == category.id)
                            .tag(category)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .contextMenu {
                                if !category.isDefault {
                                    Button("Edit") {
                                        editingCategory = category
                                    }
                                    
                                    Button("Delete", role: .destructive) {
                                        deleteCategory(category)
                                    }
                                }
                            }
                            .offset(y: isAnimating ? 0 : 20)
                            .opacity(isAnimating ? 1 : 0)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.75)
                                .delay(Double(index) * 0.05),
                                value: isAnimating
                            )
                    }
                    .onMove(perform: moveCategories)
                } header: {
                    Text("\(categories.count) Categories")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(secondaryText.opacity(0.8))
                        .textCase(.uppercase)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 3)
        )
        .padding(.leading, 20)
        .padding(.trailing, 10)
        .padding(.bottom, 20)
    }
    
    // MARK: - Selection Prompt
    private var selectionPromptView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accentColor.opacity(0.08), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                
                Image(systemName: "arrow.left.circle")
                    .font(.system(size: 56, weight: .thin))
                    .foregroundColor(secondaryText.opacity(0.3))
                    .symbolEffect(.pulse, options: .repeating)
            }
            
            VStack(spacing: 10) {
                Text("Select a Category")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(textColor)
                
                Text("Choose a category to view and manage its apps")
                    .font(.system(size: 14))
                    .foregroundColor(secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 3)
        )
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }
    
    // MARK: - Data Operations
    private func loadData() {
        categories = UsageDatabase.shared.getAllCategories()
    }
    
    private func deleteCategory(_ category: Category) {
        UsageDatabase.shared.deleteCategory(id: category.id.uuidString)
        if selectedCategory?.id == category.id {
            selectedCategory = nil
        }
        loadData()
    }
    
    private func moveCategories(from source: IndexSet, to destination: Int) {
        var updatedCategories = categories
        updatedCategories.move(fromOffsets: source, toOffset: destination)
        
        for (index, category) in updatedCategories.enumerated() {
            var updated = category
            updated.order = index
            UsageDatabase.shared.updateCategory(updated)
        }
        
        categories = updatedCategories
    }
}
