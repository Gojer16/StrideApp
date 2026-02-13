import SwiftUI

/**
 * WeeklyLogListView - A professional, responsive log of focus sessions.
 * 
 * **UX Improvements:**
 * 1. Responsive Layout: Replaces fixed table widths with flexible columns.
 * 2. Integrated Sorting: All columns, including the "Win" column, are now sortable.
 * 3. Clean Spacing: Increased separation between Task and Time for better readability.
 * 4. Hitbox Fixes: Ensures the entire row is interactive and columns align perfectly.
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
        case win
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
        case .win:
            return entries.sorted { ($0.isWinOfDay ? 1 : 0) > ($1.isWinOfDay ? 1 : 0) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: Table Header
            headerRow
            
            // MARK: Table Content
            List {
                ForEach(Array(sortedEntries.enumerated()), id: \.element.id) { index, entry in
                    EntryRow(
                        entry: entry,
                        onEdit: { onEdit(entry) },
                        onDelete: { onDelete(entry) }
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 15)
                    .animation(.spring(response: 0.4, dampingFraction: 0.75).delay(Double(index) * 0.02), value: isAnimating)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(cardBackground).shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 3))
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
    }
    
    // MARK: - Header Row
    
    private var headerRow: some View {
        HStack(spacing: 0) {
            HeaderCell(title: "DATE", sortOrder: .date, currentSort: $sortOrder)
                .frame(width: 100, alignment: .leading)
            
            HeaderCell(title: "CATEGORY", sortOrder: .category, currentSort: $sortOrder)
                .frame(width: 140, alignment: .leading)
            
            HeaderCell(title: "FOCUS TASK", sortOrder: .task, currentSort: $sortOrder)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HeaderCell(title: "DURATION", sortOrder: .time, currentSort: $sortOrder)
                .frame(width: 120, alignment: .leading)
            
            HeaderCell(title: "WIN", sortOrder: .win, currentSort: $sortOrder)
                .frame(width: 60, alignment: .center)
            
            // Actions placeholder
            Text("")
                .frame(width: 80)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(Color.black.opacity(0.03))
        .overlay(Rectangle().fill(Color.black.opacity(0.08)).frame(height: 1), alignment: .bottom)
    }
}

// MARK: - Subviews

private struct HeaderCell: View {
    let title: String
    let sortOrder: WeeklyLogListView.SortOrder
    @Binding var currentSort: WeeklyLogListView.SortOrder
    
    private let secondaryText = Color(hex: "#616161")
    private let accentColor = Color(hex: "#C75B39")
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                currentSort = sortOrder
            }
        }) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(currentSort == sortOrder ? accentColor : secondaryText.opacity(0.7))
                    .tracking(1)
                
                if currentSort == sortOrder {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct EntryRow: View {
    let entry: WeeklyLogEntry
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovering = false
    
    private let textColor = Color(hex: "#2C2C2C")
    private let secondaryText = Color(hex: "#616161")
    private let accentColor = Color(hex: "#C75B39")
    private let winColor = Color(hex: "#D4A853")
    
    var body: some View {
        HStack(spacing: 0) {
            // Date
            Text(entry.date.formattedDay)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(secondaryText)
                .frame(width: 100, alignment: .leading)
            
            // Category
            HStack(spacing: 8) {
                let color = WeeklyLogDatabase.shared.getCategoryColor(for: entry.category) ?? "#4A7C59"
                Circle().fill(Color(hex: color)).frame(width: 6, height: 6)
                Text(entry.category)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(textColor)
                    .lineLimit(1)
            }
            .frame(width: 140, alignment: .leading)
            
            // Task
            Text(entry.task)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(textColor)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 20) // Spacing from time
            
            // Time
            HStack(spacing: 4) {
                Text(entry.formattedHoursCount)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(accentColor)
                Text("(\(entry.timeInMinutes)m)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(secondaryText.opacity(0.6))
            }
            .frame(width: 120, alignment: .leading)
            
            // Win
            ZStack {
                if entry.isWinOfDay {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundColor(winColor)
                        .shadow(color: winColor.opacity(0.3), radius: 4)
                }
            }
            .frame(width: 60, alignment: .center)
            
            // Actions
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundColor(secondaryText.opacity(0.5))
                }
                .buttonStyle(.plain)
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(accentColor.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .frame(width: 80, alignment: .trailing)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(isHovering ? Color.black.opacity(0.02) : Color.clear))
        .onHover { h in withAnimation(.easeInOut(duration: 0.15)) { isHovering = h } }
    }
}
