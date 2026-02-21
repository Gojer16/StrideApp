import SwiftUI

/**
 * SettingsView - Application preferences and configuration.
 * 
 * Allows users to customize app behavior including the "Deceptive Day" offset
 * for late-night work sessions.
 */
struct SettingsView: View {
    @ObservedObject private var preferences = UserPreferences.shared
    
    // MARK: - Design System
    private let backgroundColor = Color(red: 0.98, green: 0.973, blue: 0.957)
    private let textColor = Color(red: 0.1, green: 0.1, blue: 0.1)
    private let secondaryText = Color(red: 0.4, green: 0.4, blue: 0.4)
    private let accentColor = Color(hex: "#4A7C59")
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 40) {
                    // Header
                    headerSection
                        .padding(.top, 24)
                    
                    // Day Boundary Settings
                    dayBoundarySection
                    
                    Spacer()
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SETTINGS")
                .font(.system(size: 12, weight: .black))
                .foregroundColor(accentColor)
                .tracking(2)
                .textCase(.uppercase)
            
            Text("Preferences")
                .font(.system(size: 48, weight: .bold, design: .serif))
                .foregroundColor(textColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var dayBoundarySection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Section Title
            VStack(alignment: .leading, spacing: 8) {
                Text("Day Boundary")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(textColor)
                
                Text("Define when your day starts. Sessions before this time count as the previous day.")
                    .font(.system(size: 14))
                    .foregroundColor(secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Hour Picker
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    Text("Day starts at:")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(textColor)
                    
                    Picker("", selection: $preferences.dayStartHour) {
                        ForEach(0..<24) { hour in
                            Text(formatHour(hour))
                                .tag(hour)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 140)
                }
                
                // Live Preview
                if preferences.dayStartHour > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(accentColor)
                                .font(.system(size: 14))
                            
                            Text(previewText)
                                .font(.system(size: 13))
                                .foregroundColor(secondaryText)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(accentColor.opacity(0.08))
                        )
                    }
                }
            }
            .padding(24)
            .background(glassMaterial)
        }
    }
    
    // MARK: - Helpers
    
    private var glassMaterial: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.white.opacity(0.6))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.03), radius: 20, x: 0, y: 10)
    }
    
    private func formatHour(_ hour: Int) -> String {
        if hour == 0 {
            return "Midnight (12:00 AM)"
        } else if hour < 12 {
            return "\(hour):00 AM"
        } else if hour == 12 {
            return "Noon (12:00 PM)"
        } else {
            return "\(hour - 12):00 PM"
        }
    }
    
    private var previewText: String {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        
        if currentHour < preferences.dayStartHour {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMMM d"
            return "Right now, you're in extended mode. Today tab shows \(formatter.string(from: yesterday))."
        } else {
            return "Sessions before \(formatHour(preferences.dayStartHour)) will count as the previous day."
        }
    }
}
