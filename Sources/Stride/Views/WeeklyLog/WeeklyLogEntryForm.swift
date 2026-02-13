import SwiftUI

/**
 * WeeklyLogEntryForm - Modal form for adding or editing weekly log entries
 *
 * Features:
 * - Date picker
 * - Category field with autocomplete
 * - Task field
 * - Time slider (0.1 to 4 pomodoros)
 * - Progress notes
 * - Win of the day toggle
 * - Color picker for new categories
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
    
    // Time options: 0.1 | 0.25 | 0.5 | 0.75 | 1 | 1.5 | 2 (max 2 hours)
    let timeOptions: [Double] = [0.1, 0.25, 0.5, 0.75, 1.0, 1.5, 2.0]
    
    var isEditing: Bool {
        entry != nil
    }
    
    var availableCategories: [String] {
        WeeklyLogDatabase.shared.getAllCategories()
    }
    
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
            _isWinOfDay = State(initialValue: entry.isWinOfDay)
            
            // Get existing color or default
            let existingColor = WeeklyLogDatabase.shared.getCategoryColor(for: entry.category)
            _selectedCategoryColor = State(initialValue: existingColor ?? "#4ECDC4")
        } else {
            _date = State(initialValue: weekStart)
            _category = State(initialValue: "")
            _task = State(initialValue: "")
            _timeSpent = State(initialValue: 1.0)
            _progressNote = State(initialValue: "")
            _isWinOfDay = State(initialValue: false)
            _selectedCategoryColor = State(initialValue: "#4ECDC4")
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Date picker
                        dateSection
                        
                        // Category
                        categorySection
                        
                        // Task
                        taskSection
                        
                        // Time
                        timeSection
                        
                        // Win toggle
                        winSection
                        
                        // Progress notes
                        notesSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle(isEditing ? "Edit Entry" : "New Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(secondaryText)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                    .disabled(category.isEmpty || task.isEmpty)
                    .foregroundColor(category.isEmpty || task.isEmpty ? secondaryText.opacity(0.4) : accentColor)
                    .font(.system(size: 15, weight: .semibold))
                }
            }
        }
        .frame(width: 480, height: 650)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
    }
    
    // MARK: - Date Section
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Date")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(textColor.opacity(0.9))
            
            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(cardBackground)
                        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                        )
                )
        }
    }
    
    // MARK: - Category Section
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Category")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(textColor.opacity(0.9))
                
                Spacer()
                
                // Color indicator
                if !category.isEmpty {
                    Button(action: { showingColorPicker = true }) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(hex: selectedCategoryColor))
                                .frame(width: 14, height: 14)
                            
                            Text("Color")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(secondaryText)
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(secondaryText.opacity(0.6))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Category text field with suggestions
            VStack(spacing: 8) {
                TextField("Enter category (e.g., Reading, Learning, Work)", text: $category)
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
                    .onChange(of: category) { oldValue, newValue in
                        // Load existing color if category exists
                        if let existingColor = WeeklyLogDatabase.shared.getCategoryColor(for: newValue) {
                            selectedCategoryColor = existingColor
                        }
                    }
                
                // Autocomplete suggestions
                if !category.isEmpty {
                    let suggestions = availableCategories.filter { 
                        $0.lowercased().contains(category.lowercased()) && $0 != category 
                    }.prefix(5)
                    
                    if !suggestions.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(Array(suggestions), id: \.self) { suggestion in
                                Button(action: { 
                                    category = suggestion
                                    if let color = WeeklyLogDatabase.shared.getCategoryColor(for: suggestion) {
                                        selectedCategoryColor = color
                                    }
                                }) {
                                    Text(suggestion)
                                        .font(.system(size: 12, weight: .medium))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(Color.black.opacity(0.06))
                                        )
                                        .foregroundColor(secondaryText)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingColorPicker) {
            ColorPickerSheet(
                categoryName: category,
                selectedColor: $selectedCategoryColor
            )
        }
    }
    
    // MARK: - Task Section
    private var taskSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Task")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(textColor.opacity(0.9))
            
            TextField("What did you work on?", text: $task)
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
    
    // MARK: - Time Section
    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Time Spent")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(textColor.opacity(0.9))
                
                Spacer()
                
                // Display selected time
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(String(format: "%.2f", timeSpent)) hours")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(accentColor)
                    
                    let minutes = Int(timeSpent * 60)
                    if minutes < 60 {
                        Text("\(minutes) minutes")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(secondaryText)
                    } else {
                        let hours = minutes / 60
                        let mins = minutes % 60
                        Text("\(hours)h \(mins)m")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(secondaryText)
                    }
                }
            }
            
            // Time selector buttons
            FlowLayout(spacing: 10) {
                ForEach(timeOptions, id: \.self) { option in
                    Button(action: { timeSpent = option }) {
                        Text(timeLabel(for: option))
                            .font(.system(size: 13, weight: timeSpent == option ? .bold : .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(timeSpent == option ? accentColor.opacity(0.15) : cardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .strokeBorder(
                                                timeSpent == option ? accentColor.opacity(0.5) : Color.black.opacity(0.08),
                                                lineWidth: timeSpent == option ? 2 : 1
                                            )
                                    )
                            )
                            .foregroundColor(timeSpent == option ? accentColor : textColor)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Win Section
    private var winSection: some View {
        Button(action: { isWinOfDay.toggle() }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isWinOfDay ? winColor.opacity(0.2) : Color.black.opacity(0.04))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "star.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isWinOfDay ? winColor.opacity(0.9) : secondaryText.opacity(0.5))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Win of the Day")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(textColor)
                    
                    Text("Mark this as a highlight achievement")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(secondaryText)
                }
                
                Spacer()
                
                Image(systemName: isWinOfDay ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isWinOfDay ? winColor.opacity(0.9) : secondaryText.opacity(0.3))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                isWinOfDay ? winColor.opacity(0.4) : Color.black.opacity(0.08),
                                lineWidth: isWinOfDay ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Progress Notes")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(textColor.opacity(0.9))
                
                Spacer()
                
                Text("Optional")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(secondaryText.opacity(0.7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.04))
                    )
            }
            
            TextEditor(text: $progressNote)
                .font(.system(size: 14, weight: .regular))
                .frame(minHeight: 80)
                .padding(10)
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
    }
    
    // MARK: - Helpers
    private func timeLabel(for value: Double) -> String {
        switch value {
        case 0.1: return "0.1"
        case 0.25: return "0.25"
        case 0.5: return "0.5"
        case 0.75: return "0.75"
        case 1.0: return "1"
        case 1.5: return "1.5"
        case 2.0: return "2"
        case 2.5: return "2.5"
        case 3.0: return "3"
        case 3.5: return "3.5"
        case 4.0: return "4"
        default: return String(format: "%.2f", value)
        }
    }
    
    private func saveEntry() {
        // Save category color if it's a new category or color changed
        WeeklyLogDatabase.shared.setCategoryColor(for: category, color: selectedCategoryColor)
        
        let newEntry: WeeklyLogEntry
        if let existingEntry = entry {
            newEntry = WeeklyLogEntry(
                id: existingEntry.id,
                date: date,
                category: category,
                task: task,
                timeSpent: timeSpent,
                progressNote: progressNote,
                isWinOfDay: isWinOfDay,
                createdAt: existingEntry.createdAt
            )
            WeeklyLogDatabase.shared.updateEntry(newEntry)
        } else {
            newEntry = WeeklyLogEntry(
                date: date,
                category: category,
                task: task,
                timeSpent: timeSpent,
                progressNote: progressNote,
                isWinOfDay: isWinOfDay
            )
            WeeklyLogDatabase.shared.createEntry(newEntry)
        }
        
        onSave(newEntry)
        dismiss()
    }
}

// MARK: - Flow Layout Helper
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Color Picker Sheet
struct ColorPickerSheet: View {
    let categoryName: String
    @Binding var selectedColor: String
    @Environment(\.dismiss) private var dismiss
    
    let colorOptions = [
        "#FF6B6B", "#E74C3C", "#F39C12", "#F1C40F", "#2ECC71",
        "#27AE60", "#1ABC9C", "#16A085", "#3498DB", "#2980B9",
        "#9B59B6", "#8E44AD", "#E91E63", "#F48FB1", "#795548",
        "#607D8B", "#34495E", "#2C3E50"
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
