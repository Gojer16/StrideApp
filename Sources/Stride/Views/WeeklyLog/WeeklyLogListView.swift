import SwiftUI

/**
 * WeeklyLogListView - Displays weekly log entries in an Excel-style table
 *
 * Features:
 * - Flat list (no day grouping)
 * - Sortable columns
 * - Inline editing
 * - Swipe to delete
 * - Shows: Date, Category, Task, Time, Win, Notes
 *
 * Aesthetic: Warm Paper/Editorial Light
 */
struct WeeklyLogListView: View {
    let entries: [WeeklyLogEntry]
    let onEdit: (WeeklyLogEntry) -> Void
    let onDelete: (WeeklyLogEntry) -> Void
    
    @State private var sortOrder: SortOrder = .date
    @State private var isAnimating = false
    
    enum SortOrder {
        case date
        case category
        case task
        case time
    }
    
    private let cardBackground = Color.white
    private let textColor = Color(hex: "#2C2C2C")
    private let secondaryText = Color(hex: "#616161")
    private let accentColor = Color(hex: "#C75B39")
    private let winColor = Color(hex: "#D4A853")
    
    var sortedEntries: [WeeklyLogEntry] {
        switch sortOrder {
        case .date:
            return entries.sorted { $0.date < $1.date }
        case .category:
            return entries.sorted { $0.category < $1.category }
        case .task:
            return entries.sorted { $0.task < $1.task }
        case .time:
            return entries.sorted { $0.timeSpent > $1.timeSpent }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Table header
            headerRow
            
            // Table content
            List {
                ForEach(Array(sortedEntries.enumerated()), id: \.element.id) { index, entry in
                    EntryRow(
                        entry: entry,
                        onEdit: { onEdit(entry) },
                        onDelete: { onDelete(entry) }
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 15)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.75)
                        .delay(Double(index) * 0.02),
                        value: isAnimating
                    )
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
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
    }
    
    // MARK: - Header Row
    private var headerRow: some View {
        HStack(spacing: 0) {
            // Date
            HeaderCell(title: "Date", sortOrder: .date, currentSort: $sortOrder)
                .frame(width: 100)
            
            Divider()
                .frame(height: 40)
                .background(Color.black.opacity(0.08))
            
            // Category
            HeaderCell(title: "Category", sortOrder: .category, currentSort: $sortOrder)
                .frame(width: 120)
            
            Divider()
                .frame(height: 40)
                .background(Color.black.opacity(0.08))
            
            // Task
            HeaderCell(title: "Task", sortOrder: .task, currentSort: $sortOrder)
                .frame(minWidth: 150)
            
            Divider()
                .frame(height: 40)
                .background(Color.black.opacity(0.08))
            
            // Time
            HeaderCell(title: "Time", sortOrder: .time, currentSort: $sortOrder)
                .frame(width: 140)
            
            Divider()
                .frame(height: 40)
                .background(Color.black.opacity(0.08))
            
            // Win
            Text("Win")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(secondaryText)
                .frame(width: 50)
            
            Divider()
                .frame(height: 40)
                .background(Color.black.opacity(0.08))
            
            // Actions
            Text("")
                .frame(width: 60)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.03))
        .overlay(
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

// MARK: - Header Cell
private struct HeaderCell: View {
    let title: String
    let sortOrder: WeeklyLogListView.SortOrder
    @Binding var currentSort: WeeklyLogListView.SortOrder
    
    private let secondaryText = Color(hex: "#616161")
    private let accentColor = Color(hex: "#C75B39")
    
    var isActive: Bool {
        currentSort == sortOrder
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                currentSort = sortOrder
            }
        }) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isActive ? accentColor : secondaryText)
                
                if isActive {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Entry Row
private struct EntryRow: View {
    let entry: WeeklyLogEntry
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovering = false
    
    private let textColor = Color(hex: "#2C2C2C")
    private let secondaryText = Color(hex: "#616161")
    private let accentColor = Color(hex: "#C75B39")
    private let winColor = Color(hex: "#D4A853")
    
    var categoryColor: String {
        WeeklyLogDatabase.shared.getCategoryColor(for: entry.category) ?? "#4ECDC4"
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Date
            Text(entry.date.formattedDay)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(secondaryText)
                .frame(width: 100, alignment: .leading)
            
            // Category
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: categoryColor))
                    .frame(width: 8, height: 8)
                
                Text(entry.category)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(textColor)
                    .lineLimit(1)
            }
            .frame(width: 120, alignment: .leading)
            
            // Task
            Text(entry.task)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(textColor)
                .lineLimit(1)
                .frame(minWidth: 150, alignment: .leading)
            
            // Time
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.formattedHoursCount)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(accentColor)
                
                Text(entry.formattedMinutes)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(secondaryText)
            }
            .frame(width: 140, alignment: .leading)
            
            // Win
            if entry.isWinOfDay {
                Image(systemName: "star.fill")
                    .font(.system(size: 16))
                    .foregroundColor(winColor)
                    .frame(width: 50)
            } else {
                Text("")
                    .frame(width: 50)
            }
            
            // Actions
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(secondaryText.opacity(0.7))
                }
                .buttonStyle(.plain)
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(accentColor.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            .frame(width: 60)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isHovering ? Color.black.opacity(0.04) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
        .animation(.easeInOut(duration: 0.15), value: isHovering)
    }
}
