import SwiftUI

/**
 * CurrentSessionView - The "Live" Tab
 * 
 * An atmospheric, real-time dashboard that serves as the heart of the Stride experience.
 * 
 * **Design Philosophy (Ambient Status):**
 * Instead of static data boxes, this view uses an "Ambient Status" approach where the 
 * entire UI breathes and reacts to the user's current activity. The background color
 * cross-fades based on the active app's category, creating a subconscious cue for 
 * productivity vs. leisure.
 * 
 * **Key Components:**
 * 1. `ambientBackground`: A Canvas-based mesh gradient that provides atmospheric feedback.
 * 2. `appBrandingSection`: Magazine-style typography emphasizing the active context.
 * 3. `heroTimerSection`: A minimalist, high-impact session clock.
 * 4. `Glass Cards`: Secondary metrics housed in blurred material containers.
 */
struct CurrentSessionView: View {
    @EnvironmentObject private var appState: AppState
    
    /// Controls the entry animations when the tab appears
    @State private var isAnimating = false
    
    /// Drives the subtle rotation of the background glow elements
    @State private var glowRotation: Double = 0
    
    // MARK: - Theme Constants
    
    /// Deep charcoal for primary reading (Editorial standard)
    private let textColor = Color(red: 0.1, green: 0.1, blue: 0.1)
    
    /// Soft gray for secondary metadata
    private let secondaryText = Color(red: 0.3, green: 0.3, blue: 0.3)
    
    var body: some View {
        ZStack {
            // Layer 0: The reactive atmospheric background
            ambientBackground
            
            ScrollView {
                VStack(spacing: 60) {
                    // Top margin for breathing room
                    Spacer().frame(height: 40)
                    
                    // Layer 1: Live Status Header
                    HStack {
                        Spacer()
                        liveIndicator
                    }
                    .padding(.horizontal, 40)
                    
                    // Layer 2: Central Focus (App Branding + Timer)
                    VStack(spacing: 32) {
                        appBrandingSection
                        heroTimerSection
                    }
                    
                    // Layer 3: Contextual Info (Stats + Recent History)
                    if isAnimating {
                        HStack(spacing: 24) {
                            statsGlassCard
                            recentActivityGlassCard
                        }
                        .padding(.horizontal, 40)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            // Trigger entry animations with a smooth spring
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                isAnimating = true
            }
            // Start the slow atmospheric rotation
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                glowRotation = 360
            }
        }
    }
    
    // MARK: - Subviews
    
    /**
     * A dynamic mesh gradient background.
     * 
     * Uses SwiftUI Canvas for high-performance rendering of blurred shapes.
     * The colors are bound to `appState.currentCategoryColor` with a 2-second
     * interpolation for smooth transitions during app switches.
     */
    private var ambientBackground: some View {
        ZStack {
            // Solid base
            Color.white.ignoresSafeArea()
            
            // The "Glow" shapes
            Canvas { context, size in
                context.addFilter(.blur(radius: 60))
                context.drawLayer { ctx in
                    // Two overlapping ellipses create the "mesh" effect
                    let rect1 = CGRect(x: size.width * 0.2, y: size.height * 0.1, width: size.width * 0.6, height: size.height * 0.4)
                    let rect2 = CGRect(x: size.width * 0.5, y: size.height * 0.5, width: size.width * 0.5, height: size.height * 0.4)
                    
                    ctx.fill(Path(ellipseIn: rect1), with: .color(appState.currentCategoryColor.opacity(0.15)))
                    ctx.fill(Path(ellipseIn: rect2), with: .color(appState.currentCategoryColor.opacity(0.1)))
                }
            }
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 2.0), value: appState.currentCategoryColor)
            
            // Softening layer to maintain text legibility
            Color.white.opacity(0.4).ignoresSafeArea()
        }
    }
    
    /**
     * Magazine-style app title and window context.
     * 
     * Uses a Serif font for the primary name to evoke a sense of "craft" and "editorial quality."
     */
    private var appBrandingSection: some View {
        VStack(spacing: 16) {
            // Category Badge
            HStack(spacing: 8) {
                Circle()
                    .fill(appState.currentCategoryColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: appState.currentCategoryColor.opacity(0.5), radius: 4)
                
                Text(appState.activeAppName.uppercased())
                    .font(.system(size: 12, weight: .black))
                    .tracking(3)
                    .foregroundColor(secondaryText)
            }
            
            // App Name (Editorial Style)
            Text(appState.activeAppName)
                .font(.system(size: 52, weight: .bold, design: .serif))
                .foregroundColor(textColor)
                .contentTransition(.interpolate)
            
            // Active Window (Subtle Context)
            if !appState.activeWindowTitle.isEmpty {
                Text(appState.activeWindowTitle)
                    .font(.system(size: 16, weight: .medium, design: .default))
                    .italic()
                    .foregroundColor(secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 60)
                    .lineLimit(2)
            }
        }
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
    }
    
    /**
     * Large, readable timer.
     * 
     * Uses a thin rounded font for modern precision without feeling clinical.
     */
    private var heroTimerSection: some View {
        VStack(spacing: 8) {
            Text(appState.formattedTime)
                .font(.system(size: 100, weight: .thin, design: .rounded))
                .foregroundColor(textColor)
                .monospacedDigit()
                .shadow(color: appState.currentCategoryColor.opacity(0.1), radius: 20, x: 0, y: 10)
            
            Text("SESSION ELAPSED")
                .font(.system(size: 10, weight: .bold))
                .tracking(4)
                .foregroundColor(secondaryText.opacity(0.6))
        }
        .scaleEffect(isAnimating ? 1 : 0.95)
        .opacity(isAnimating ? 1 : 0)
    }
    
    /**
     * High-level daily metrics in a glass container.
     */
    private var statsGlassCard: some View {
        VStack(spacing: 20) {
            statRow(icon: "eye.fill", label: "Visits Today", value: "\(appState.totalVisitsToday)")
            Divider().opacity(0.5)
            statRow(icon: "hourglass", label: "Total Time", value: appState.totalTimeToday.formatted())
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(glassMaterial)
    }
    
    /**
     * Real-time history log in a glass container.
     */
    private var recentActivityGlassCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("RECENT CONTEXT")
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundColor(secondaryText.opacity(0.7))
            
            VStack(spacing: 12) {
                // We filter the current app to avoid redundancy
                let displayApps = appState.recentApps
                    .filter { $0.name != appState.activeAppName }
                    .prefix(3)
                
                if displayApps.isEmpty {
                    Text("No recent context")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                } else {
                    ForEach(displayApps) { app in
                        HStack {
                            Image(systemName: guessIcon(for: app.name))
                                .font(.system(size: 12))
                                .foregroundColor(appState.currentCategoryColor)
                                .frame(width: 24, height: 24)
                                .background(appState.currentCategoryColor.opacity(0.1))
                                .clipShape(Circle())
                            
                            Text(app.name)
                                .font(.system(size: 13, weight: .semibold))
                            
                            Spacer()
                            
                            Text(app.totalTimeSpent.formatted())
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(glassMaterial)
    }
    
    /**
     * The pulsing live dot.
     */
    private var liveIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(appState.currentCategoryColor)
                .frame(width: 6, height: 6)
            
            Text("LIVE")
                .font(.system(size: 10, weight: .black))
                .tracking(2)
                .foregroundColor(secondaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(glassMaterial)
    }
    
    // MARK: - Styling Components
    
    /**
     * A reusable "Glassmorphism" material style.
     * Uses native macOS blurring (NSVisualEffectView) behind a tinted white layer.
     */
    private var glassMaterial: some View {
        RoundedRectangle(cornerRadius: 32, style: .continuous)
            .fill(.white.opacity(0.4))
            .background(
                BlurView(style: .hudWindow)
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(.white.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.03), radius: 20, x: 0, y: 10)
    }
    
    /**
     * Standardized row for key-value statistics.
     */
    private func statRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(appState.currentCategoryColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(secondaryText)
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
            }
            Spacer()
        }
    }
    
    /**
     * Logic for mapping common app names to SF Symbols.
     */
    private func guessIcon(for appName: String) -> String {
        let name = appName.lowercased()
        if name.contains("xcode") || name.contains("code") || name.contains("terminal") { return "hammer.fill" }
        if name.contains("safari") || name.contains("chrome") || name.contains("firefox") { return "safari.fill" }
        if name.contains("slack") || name.contains("discord") || name.contains("message") { return "message.fill" }
        return "app.fill"
    }
}

/**
 * BlurView - Bridge for NSVisualEffectView to provide native macOS blurring.
 * 
 * Necessary because SwiftUI's .background(.ultraThinMaterial) behaves
 * differently on macOS compared to iOS.
 */
struct BlurView: NSViewRepresentable {
    let style: NSVisualEffectView.Material
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = style
        view.blendingMode = .withinWindow
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = style
    }
}
