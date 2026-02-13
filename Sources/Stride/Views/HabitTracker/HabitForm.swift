import SwiftUI

/**
 * HabitForm - Modal form for creating or editing habits
 *
 * Allows users to configure:
 * - Name and icon
 * - Habit type (checkbox, timer, counter)
 * - Target/goal
 * - Frequency (daily, weekly, monthly)
 * - Reminder time
 * - Color customization
 */
struct HabitForm: View {
    @Environment(\.dismiss) private var dismiss
    
    let habit: Habit? // nil for new habit, existing habit for edit
    let onSave: (Habit) -> Void
    
    // Form state
    @State private var name = ""
    @State private var selectedIcon = "checkmark.circle.fill"
    @State private var selectedColor = "#4A7C59"
    @State private var selectedType: HabitType = .checkbox
    @State private var selectedFrequency: HabitFrequency = .daily
    @State private var targetValue = 1.0
    @State private var reminderEnabled = false
    @State private var reminderTime = Date()
    
    @State private var showingIconPicker = false
    @State private var showingColorPicker = false
    
    // Dark Forest theme
    private let backgroundColor = Color(hex: "#0F1F17")
    private let cardBackground = Color(hex: "#1A2820")
    private let accentColor = Color(hex: "#4A7C59")
    
    private var isEditing: Bool { habit != nil }
    
    // Available icons
    private let availableIcons = [
        "checkmark.circle.fill",
        "figure.mind.and.body",
        "drop.fill",
        "book.fill",
        "moon.fill",
        "sun.max.fill",
        "bolt.fill",
        "heart.fill",
        "star.fill",
        "flame.fill",
        "leaf.fill",
        "apple.logo",
        "fork.knife.circle.fill",
        "bed.double.fill",
        "dumbbell.fill",
        "figure.walk",
        "figure.run",
        "figure.yoga",
        "pencil.circle.fill",
        "paintbrush.fill",
        "guitars.fill",
        "music.note",
        "headphones",
        "laptopcomputer",
        "iphone",
        "dollarsign.circle.fill",
        "creditcard.fill",
        "house.fill",
        "car.fill",
        "bicycle",
        "airplane",
        "globe",
        "envelope.fill",
        "phone.fill",
        "video.fill",
        "camera.fill",
        "photo.fill",
        "gift.fill",
        "cart.fill",
        "bag.fill",
        "wallet.pass.fill"
    ]
    
    // Available colors (Dark Forest palette)
    // Design System - Earthy, desaturated habit colors
    private let availableColors = [
        "#4A7C59",  // Moss (brand primary)
        "#5B7C8C",  // Slate - Focus, work
        "#D4A853",  // Gold (brand achievement)
        "#C75B39",  // Terracotta - Passion
        "#7A8C8C",  // Sage - Balance, wellness
        "#B8834C",  // Bronze - Learning
        "#9C7C7C",  // Dusty Rose - Self-care
        "#5A8C8C",  // Sea - Hydration
        "#9C8B7C",  // Taupe - Organization
        "#8C8C8C",  // Stone - Neutral
        "#7C6B5B",  // Coffee - Morning
        "#C4B49C"   // Sand - Evening
    ]
    
    init(habit: Habit? = nil, onSave: @escaping (Habit) -> Void) {
        self.habit = habit
        self.onSave = onSave
        
        if let habit = habit {
            _name = State(initialValue: habit.name)
            _selectedIcon = State(initialValue: habit.icon)
            _selectedColor = State(initialValue: habit.color)
            _selectedType = State(initialValue: habit.type)
            _selectedFrequency = State(initialValue: habit.frequency)
            _targetValue = State(initialValue: habit.targetValue)
            _reminderEnabled = State(initialValue: habit.reminderEnabled)
            if let time = habit.reminderTime {
                _reminderTime = State(initialValue: time)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Icon and Color picker
                        iconColorSection
                        
                        // Name input
                        nameSection
                        
                        // Habit type
                        typeSection
                        
                        // Target value (if not checkbox)
                        if selectedType != .checkbox {
                            targetSection
                        }
                        
                        // Frequency
                        frequencySection
                        
                        // Reminder
                        reminderSection
                        
                        Spacer()
                            .frame(height: 40)
                    }
                    .padding(24)
                }
            }
            .navigationTitle(isEditing ? "Edit Habit" : "New Habit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#9A9A9A"))
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveHabit()
                    }
                    .disabled(name.isEmpty)
                    .foregroundColor(name.isEmpty ? Color(hex: "#666666") : accentColor)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 600)
    }
    
    // MARK: - Sections
    
    private var iconColorSection: some View {
        HStack(spacing: 20) {
            // Icon picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Icon")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#808080"))
                    .textCase(.uppercase)
                    .tracking(1)
                
                Button(action: { showingIconPicker = true }) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: selectedColor).opacity(0.15))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: selectedIcon)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(Color(hex: selectedColor))
                    }
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            // Color picker
            VStack(alignment: .trailing, spacing: 8) {
                Text("Color")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#808080"))
                    .textCase(.uppercase)
                    .tracking(1)
                
                Button(action: { showingColorPicker = true }) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: selectedColor))
                            .frame(width: 40, height: 40)
                        
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 40, height: 40)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBackground)
        )
        .sheet(isPresented: $showingIconPicker) {
            IconPickerView(
                selectedIcon: $selectedIcon,
                selectedColor: selectedColor,
                icons: availableIcons
            )
        }
        .sheet(isPresented: $showingColorPicker) {
            ColorPickerView(
                selectedColor: $selectedColor,
                colors: availableColors
            )
        }
    }
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Habit Name")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "#808080"))
                .textCase(.uppercase)
                .tracking(1)
            
            TextField("e.g., Morning Meditation", text: $name)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(cardBackground)
                )
                .textFieldStyle(.plain)
        }
    }
    
    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tracking Type")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "#808080"))
                .textCase(.uppercase)
                .tracking(1)
            
            HStack(spacing: 12) {
                ForEach(HabitType.allCases) { type in
                    TypeButton(
                        type: type,
                        isSelected: selectedType == type,
                        accentColor: accentColor
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedType = type
                            // Reset target value appropriate for type
                            if type == .checkbox {
                                targetValue = 1.0
                            } else if type == .timer {
                                targetValue = 10.0
                            } else {
                                targetValue = 8.0
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var targetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Goal")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "#808080"))
                .textCase(.uppercase)
                .tracking(1)
            
            HStack(spacing: 16) {
                if selectedType == .timer {
                    // Hours and Minutes
                    HStack(spacing: 8) {
                        Stepper("\(Int(targetValue) / 60)h", value: Binding(
                            get: { Int(targetValue) / 60 },
                            set: { targetValue = Double($0 * 60 + Int(targetValue) % 60) }
                        ), in: 0...23)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        
                        Stepper("\(Int(targetValue) % 60)m", value: Binding(
                            get: { Int(targetValue) % 60 },
                            set: { targetValue = Double((Int(targetValue) / 60) * 60 + $0) }
                        ), in: 0...59)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    }
                } else {
                    // Counter
                    HStack(spacing: 16) {
                        Button(action: { targetValue = max(1, targetValue - 1) }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(accentColor)
                        }
                        .buttonStyle(.plain)
                        
                        Text("\(Int(targetValue))")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(minWidth: 50)
                        
                        Button(action: { targetValue += 1 }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(cardBackground)
            )
        }
    }
    
    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Frequency")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "#808080"))
                .textCase(.uppercase)
                .tracking(1)
            
            HStack(spacing: 12) {
                ForEach(HabitFrequency.allCases) { freq in
                    FrequencyButton(
                        frequency: freq,
                        isSelected: selectedFrequency == freq,
                        accentColor: accentColor
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFrequency = freq
                        }
                    }
                }
            }
        }
    }
    
    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $reminderEnabled) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "bell.fill")
                            .font(.system(size: 16))
                            .foregroundColor(accentColor)
                    }
                    
                    Text("Daily Reminder")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: accentColor))
            
            if reminderEnabled {
                DatePicker(
                    "Reminder Time",
                    selection: $reminderTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(CompactDatePickerStyle())
                .colorMultiply(accentColor)
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBackground)
        )
    }
    
    // MARK: - Actions
    
    private func saveHabit() {
        let newHabit = Habit(
            id: habit?.id ?? UUID(),
            name: name,
            icon: selectedIcon,
            color: selectedColor,
            type: selectedType,
            frequency: selectedFrequency,
            targetValue: targetValue,
            reminderTime: reminderEnabled ? reminderTime : nil,
            reminderEnabled: reminderEnabled,
            createdAt: habit?.createdAt ?? Date(),
            isArchived: habit?.isArchived ?? false
        )
        
        onSave(newHabit)
        dismiss()
    }
}

/**
 * Icon picker view
 */
struct IconPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedIcon: String
    let selectedColor: String
    let icons: [String]
    
    private let backgroundColor = Color(hex: "#0F1F17")
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 16) {
                    ForEach(icons, id: \.self) { icon in
                        Button(action: {
                            selectedIcon = icon
                            dismiss()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(selectedIcon == icon ? Color(hex: selectedColor).opacity(0.3) : Color.white.opacity(0.05))
                                    .frame(width: 56, height: 56)
                                
                                Image(systemName: icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(selectedIcon == icon ? Color(hex: selectedColor) : .white)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .background(backgroundColor)
            .navigationTitle("Choose Icon")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "#9A9A9A"))
                }
            }
        }
        .frame(minWidth: 400, minHeight: 500)
    }
}

/**
 * Color picker view
 */
struct ColorPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedColor: String
    let colors: [String]
    
    private let backgroundColor = Color(hex: "#0F1F17")
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 16) {
                    ForEach(colors, id: \.self) { color in
                        Button(action: {
                            selectedColor = color
                            dismiss()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 56, height: 56)
                                
                                if selectedColor == color {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .background(backgroundColor)
            .navigationTitle("Choose Color")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "#9A9A9A"))
                }
            }
        }
        .frame(minWidth: 400, minHeight: 400)
    }
}

/**
 * Habit type selection button
 */
struct TypeButton: View {
    let type: HabitType
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : Color(hex: "#9A9A9A"))
                
                Text(type.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color(hex: "#9A9A9A"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? accentColor : Color.white.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
    }
}

/**
 * Frequency selection button
 */
struct FrequencyButton: View {
    let frequency: HabitFrequency
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(frequency.displayName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : Color(hex: "#9A9A9A"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? accentColor : Color.white.opacity(0.05))
                )
        }
        .buttonStyle(.plain)
    }
}