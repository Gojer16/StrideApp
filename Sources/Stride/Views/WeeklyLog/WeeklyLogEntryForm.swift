import SwiftUI

/**
 * WeeklyLogEntryForm - A refined modal for capturing focus sessions.
 * 
 * **UX Improvements:**
 * 1. Horizontal Day Selector: Replaces the bulky graphical calendar for faster date entry.
 * 2. Integrated Win Notes: Provides a dedicated text field for achievement highlights.
 * 3. Hitbox Optimization: Input fields now have large, accessible tap targets.
 * 4. Minimalist Layout: Follows the editorial Stride design language.
 */
struct WeeklyLogEntryForm: View {
    let entry: WeeklyLogEntry?
    let weekStart: Date
    let onSave: (WeeklyLogEntry) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var date: Date
    @State private var category: String
    @State private var task: String
    @State private var timeSpent: Double
    @State private var progressNote: String
    @State private var winNote: String
    @State private var isWinOfDay: Bool
    @State private var isAnimating = false
    @State private var showingColorPicker = false
    @State private var selectedCategoryColor: String
    
    private let backgroundColor = Color(hex: "#FAF8F4")
    private let cardBackground = Color.white
    private let accentColor = Color(hex: "#C75B39")
    private let textColor = Color(hex: "#2C2C2C")
    private let secondaryText = Color(hex: "#616161")
    private let winColor = Color(hex: "#D4A853")
    
    /// Incremental time options for quick selection
    let timeOptions: [Double] = [0.1, 0.25, 0.5, 0.75, 1.0, 1.5, 2.0]
    
    var isEditing: Bool { entry != nil }
    var availableCategories: [String] { WeeklyLogDatabase.shared.getAllCategories() }
    
    init(entry: WeeklyLogEntry?, weekStart: Date, onSave: @escaping (WeeklyLogEntry) -> Void) {
        self.entry = entry
        self.weekStart = weekStart
        self.onSave = onSave
        
        if let entry = entry {
            _date = State(initialValue: entry.date)
            _category = State(initialValue: entry.category)
            _task = State(initialValue: entry.task)
            _timeSpent = State(initialValue: entry.timeSpent)
            _progressNote = State(initialValue: entry.progressNote)
            _winNote = State(initialValue: entry.winNote)
            _isWinOfDay = State(initialValue: entry.isWinOfDay)
            let existingColor = WeeklyLogDatabase.shared.getCategoryColor(for: entry.category)
            _selectedCategoryColor = State(initialValue: existingColor ?? "#4A7C59")
        } else {
            _date = State(initialValue: Date().isInSameWeek(as: weekStart) ? Date() : weekStart)
            _category = State(initialValue: "")
            _task = State(initialValue: "")
            _timeSpent = State(initialValue: 1.0)
            _progressNote = State(initialValue: "")
            _winNote = State(initialValue: "")
            _isWinOfDay = State(initialValue: false)
            _selectedCategoryColor = State(initialValue: "#4A7C59")
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        // MARK: 1. Easy Day Selector
                        daySelectorSection
                        
                        // MARK: 2. Category & Branding
                        categorySection
                        
                        // MARK: 3. Task Context
                        taskSection
                        
                        // MARK: 4. Duration
                        timeSection
                        
                        // MARK: 5. Achievement (Win)
                        winSection
                        
                        // MARK: 6. Notes
                        notesSection
                    }
                    .padding(24)
                }
            }
            .navigationTitle(isEditing ? "Edit Entry" : "New Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(secondaryText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveEntry() }
                        .disabled(category.isEmpty || task.isEmpty)
                        .foregroundColor(category.isEmpty || task.isEmpty ? secondaryText.opacity(0.4) : accentColor)
                        .font(.system(size: 15, weight: .bold))
                }
            }
        }
        .frame(width: 500, height: 750)
    }
    
    // MARK: - Sections
    
    /**
     * Replaces the graphical date picker with high-tap-target day chips.
     */
    private var daySelectorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SELECT DAY").font(.system(size: 10, weight: .black)).foregroundColor(secondaryText).tracking(1.5)
            
            HStack(spacing: 10) {
                ForEach(weekStart.weekInfo.days, id: \.self) { day in
                    let isSelected = Calendar.current.isDate(day, inSameDayAs: date)
                    let isToday = Calendar.current.isDateInToday(day)
                    
                    Button(action: { date = day }) {
                        VStack(spacing: 4) {
                            Text(day.shortDayName.uppercased())
                                .font(.system(size: 9, weight: .bold))
                            Text(day.dayOfMonth)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(isSelected ? accentColor : (isToday ? accentColor.opacity(0.1) : cardBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(isSelected ? Color.clear : Color.black.opacity(0.05), lineWidth: 1)
                        )
                        .foregroundColor(isSelected ? .white : (isToday ? accentColor : textColor))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    /**
     * Optimized input field for categories with autocomplete suggestions.
     */
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("CATEGORY").font(.system(size: 10, weight: .black)).foregroundColor(secondaryText).tracking(1.5)
                Spacer()
                if !category.isEmpty {
                    Button(action: { showingColorPicker = true }) {
                        Circle().fill(Color(hex: selectedCategoryColor)).frame(width: 14, height: 14)
                    }.buttonStyle(.plain)
                }
            }
            
            VStack(spacing: 8) {
                TextField("Reading, Learning, Focus...", text: $category)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .medium))
                    .padding(14)
                    .frame(maxWidth: .infinity) // Full-width hitbox
                    .background(RoundedRectangle(cornerRadius: 12).fill(cardBackground).shadow(color: .black.opacity(0.02), radius: 4))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.06), lineWidth: 1))
                    .focusEffectDisabled()
                    .onChange(of: category) {
                        if let existingColor = WeeklyLogDatabase.shared.getCategoryColor(for: category) {
                            selectedCategoryColor = existingColor
                        }
                    }
                
                // Autocomplete Suggestions
                if !category.isEmpty {
                    let suggestions = availableCategories.filter { $0.lowercased().contains(category.lowercased()) && $0 != category }.prefix(4)
                    if !suggestions.isEmpty {
                        HStack {
                            ForEach(Array(suggestions), id: \.self) { suggestion in
                                Button(suggestion) { 
                                    category = suggestion
                                    if let color = WeeklyLogDatabase.shared.getCategoryColor(for: suggestion) {
                                        selectedCategoryColor = color
                                    }
                                }
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(Capsule().fill(Color.black.opacity(0.05)))
                                .foregroundColor(secondaryText)
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingColorPicker) {
            ColorPickerSheet(categoryName: category, selectedColor: $selectedCategoryColor)
        }
    }
    
    /**
     * Large hitbox text field for focus tasks.
     */
    private var taskSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("FOCUS TASK").font(.system(size: 10, weight: .black)).foregroundColor(secondaryText).tracking(1.5)
            TextField("What did you achieve?", text: $task)
                .textFieldStyle(.plain)
                .font(.system(size: 15, weight: .medium))
                .padding(14)
                .frame(maxWidth: .infinity) // Full-width hitbox
                .background(RoundedRectangle(cornerRadius: 12).fill(cardBackground).shadow(color: .black.opacity(0.02), radius: 4))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.06), lineWidth: 1))
                .focusEffectDisabled()
        }
    }
    
    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("DURATION").font(.system(size: 10, weight: .black)).foregroundColor(secondaryText).tracking(1.5)
                Spacer()
                Text("\(String(format: "%.2f", timeSpent)) hours").font(.system(size: 13, weight: .bold, design: .rounded)).foregroundColor(accentColor)
            }
            
            HStack(spacing: 8) {
                ForEach(timeOptions, id: \.self) { option in
                    Button(action: { timeSpent = option }) {
                        Text(timeLabel(for: option))
                            .font(.system(size: 12, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 10).fill(timeSpent == option ? accentColor.opacity(0.15) : cardBackground))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(timeSpent == option ? accentColor.opacity(0.4) : Color.black.opacity(0.06), lineWidth: 1))
                            .foregroundColor(timeSpent == option ? accentColor : textColor)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    /**
     * Toggles the "Win" status and exposes an optional achievement description field.
     */
    private var winSection: some View {
        VStack(spacing: 16) {
            Button(action: { withAnimation { isWinOfDay.toggle() } }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(isWinOfDay ? winColor.opacity(0.2) : Color.black.opacity(0.04)).frame(width: 40, height: 40)
                        Image(systemName: "star.fill").font(.system(size: 18, weight: .medium)).foregroundColor(isWinOfDay ? winColor.opacity(0.9) : secondaryText.opacity(0.5))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Win of the Day").font(.system(size: 15, weight: .bold)).foregroundColor(textColor)
                        Text("Mark this session as a highlight").font(.system(size: 12)).foregroundColor(secondaryText)
                    }
                    Spacer()
                    Image(systemName: isWinOfDay ? "checkmark.circle.fill" : "circle").font(.system(size: 20)).foregroundColor(isWinOfDay ? winColor : secondaryText.opacity(0.2))
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 16).fill(cardBackground).shadow(color: .black.opacity(0.02), radius: 8))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(isWinOfDay ? winColor.opacity(0.3) : Color.black.opacity(0.06), lineWidth: 1))
            }
            .buttonStyle(.plain)
            
            if isWinOfDay {
                VStack(alignment: .leading, spacing: 8) {
                    Text("DESCRIBE THE WIN").font(.system(size: 9, weight: .black)).foregroundColor(winColor.opacity(0.8)).tracking(1)
                    TextField("Briefly describe why this was a win...", text: $winNote)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14, weight: .medium))
                        .padding(14)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 12).fill(winColor.opacity(0.05)))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(winColor.opacity(0.2), lineWidth: 1))
                        .focusEffectDisabled()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PROGRESS NOTES").font(.system(size: 10, weight: .black)).foregroundColor(secondaryText).tracking(1.5)
            TextEditor(text: $progressNote)
                .font(.system(size: 14))
                .frame(minHeight: 100)
                .scrollContentBackground(.hidden) // Removes default macOS TextEditor styling
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(cardBackground))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.06), lineWidth: 1))
                .focusEffectDisabled()
        }
    }
    
    // MARK: - Helpers
    
    private func timeLabel(for value: Double) -> String {
        if value < 1.0 { return String(format: "%.2f", value) }
        return "\(Int(value))h"
    }
    
    private func saveEntry() {
        WeeklyLogDatabase.shared.setCategoryColor(for: category, color: selectedCategoryColor)
        
        let newEntry = WeeklyLogEntry(
            id: entry?.id ?? UUID(),
            date: date,
            category: category,
            task: task,
            timeSpent: timeSpent,
            progressNote: progressNote,
            winNote: winNote,
            isWinOfDay: isWinOfDay,
            createdAt: entry?.createdAt ?? Date()
        )
        
        if isEditing {
            WeeklyLogDatabase.shared.updateEntry(newEntry)
        } else {
            WeeklyLogDatabase.shared.createEntry(newEntry)
        }
        
        onSave(newEntry)
        dismiss()
    }
}

// MARK: - Color Picker Sheet
struct ColorPickerSheet: View {
    let categoryName: String
    @Binding var selectedColor: String
    @Environment(\.dismiss) private var dismiss
    
    let colorOptions = [
        "#C75B39", "#4A7C59", "#7A6B8A", "#5B7C8C", "#B8834C",
        "#5A8C7C", "#7A8C8C", "#9C8B7C", "#6B5B6B", "#5B6B7C",
        "#7C6B5B", "#8C7C6B", "#C4B49C", "#9C7C7C", "#6B7B7B",
        "#D4A853"
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Choose a color for \"\(categoryName)\"")
                    .font(.system(size: 17, weight: .semibold))
                    .padding(.top, 20)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 16) {
                    ForEach(colorOptions, id: \.self) { color in
                        Button(action: {
                            selectedColor = color
                            dismiss()
                        }) {
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            selectedColor == color ? Color.white : Color.clear,
                                            lineWidth: 3
                                        )
                                )
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            selectedColor == color ? Color.black.opacity(0.3) : Color.clear,
                                            lineWidth: selectedColor == color ? 1 : 0
                                        )
                                )
                                .shadow(
                                    color: Color(hex: color).opacity(0.4),
                                    radius: selectedColor == color ? 8 : 0,
                                    x: 0,
                                    y: selectedColor == color ? 4 : 0
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Category Color")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 350, height: 450)
    }
}
