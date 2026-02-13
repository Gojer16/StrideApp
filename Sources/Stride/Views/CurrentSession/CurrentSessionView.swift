import SwiftUI

/**
 * CurrentSessionView - Displays the currently active app and session information
 *
 * Aesthetic: Warm Paper/Editorial Light
 * - Warm cream/paper backgrounds (#F5F1EB, #FAF8F5)
 * - Soft charcoal text (#2C2C2C, #3D3D3D)
 * - Terracotta/ochre accents (#C75B39, #D4A574)
 * - Soft shadows and depth
 * - Clean editorial typography
 */
struct CurrentSessionView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isPulsing = false
    @State private var isAnimating = false
    @State private var glowRotation: Double = 0
    
    private let backgroundColor = Color(red: 0.98, green: 0.973, blue: 0.957)
    private let cardBackground = Color.white
    private let accentColor = Color(red: 0.78, green: 0.357, blue: 0.224)
    private let textColor = Color(red: 0.173, green: 0.173, blue: 0.173)
    private let secondaryText = Color(red: 0.38, green: 0.38, blue: 0.38)
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 48) {
                    Spacer()
                        .frame(height: 20)
                    
                    liveIndicator
                    
                    appInfoSection
                    
                    timerSection
                    
                    statsSection
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 40)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                isAnimating = true
            }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                glowRotation = 360
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isPulsing.toggle()
            }
        }
    }
    
    // MARK: - Live Indicator
    private var liveIndicator: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 16, height: 16)
                
                Circle()
                    .fill(accentColor)
                    .frame(width: 8, height: 8)
                    .opacity(isPulsing ? 1 : 0.4)
                    .scaleEffect(isPulsing ? 1.1 : 0.9)
            }
            
            Text("LIVE TRACKING")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(secondaryText)
                .tracking(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(cardBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .overlay(
            Capsule()
                .strokeBorder(accentColor.opacity(0.25), lineWidth: 1)
        )
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : -20)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isAnimating)
    }
    
    // MARK: - App Info Section
    private var appInfoSection: some View {
        VStack(spacing: 24) {
            ZStack {
                // Rotating glow effect
                Circle()
                    .fill(
                        AngularGradient(
                            colors: [
                                accentColor.opacity(0.2),
                                accentColor.opacity(0.08),
                                accentColor.opacity(0.04),
                                accentColor.opacity(0.08),
                                accentColor.opacity(0.2)
                            ],
                            center: .center
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)
                    .rotationEffect(.degrees(glowRotation))
                
                // Outer ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                accentColor.opacity(0.4),
                                accentColor.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 140, height: 140)
                
                // Inner fill
                Circle()
                    .fill(cardBackground)
                    .frame(width: 130, height: 130)
                    .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                Color.black.opacity(0.08),
                                lineWidth: 1
                            )
                    )
                
                // App icon
                Image(systemName: "app.fill")
                    .font(.system(size: 56, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolRenderingMode(.hierarchical)
            }
            .scaleEffect(isAnimating ? 1.0 : 0.8)
            .opacity(isAnimating ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: isAnimating)
            
            VStack(spacing: 10) {
                Text(appState.activeAppName)
                    .font(.system(size: 36, weight: .bold, design: .default))
                    .foregroundColor(textColor)
                
                if !appState.activeWindowTitle.isEmpty {
                    Text(appState.activeWindowTitle)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(secondaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 20)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: isAnimating)
        }
    }
    
    // MARK: - Timer Section
    private var timerSection: some View {
        ZStack {
            // Background glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            accentColor.opacity(0.12),
                            accentColor.opacity(0.04),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
            
            // Outer track
            Circle()
                .stroke(Color.black.opacity(0.06), lineWidth: 12)
                .frame(width: 240, height: 240)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: min(CGFloat(appState.elapsedTime.truncatingRemainder(dividingBy: 3600)) / 3600, 1))
                .stroke(
                    AngularGradient(
                        colors: [
                            accentColor.opacity(0.9),
                            accentColor,
                            accentColor.opacity(0.9)
                        ],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 240, height: 240)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: appState.elapsedTime)
                .shadow(color: accentColor.opacity(0.25), radius: 8, x: 0, y: 0)
            
            // Timer content
            VStack(spacing: 10) {
                Text(appState.formattedTime)
                    .font(.system(size: 64, weight: .light, design: .rounded))
                    .foregroundColor(textColor)
                    .monospacedDigit()
                
                Text("This Session")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(secondaryText)
                    .tracking(0.5)
            }
        }
        .scaleEffect(isAnimating ? 1.0 : 0.9)
        .opacity(isAnimating ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: isAnimating)
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 20) {
            QuickStatCard(
                icon: "eye.fill",
                value: "\(appState.totalVisitsToday)",
                label: "Visits Today",
                color: accentColor
            )
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 30)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4), value: isAnimating)
            
            QuickStatCard(
                icon: "hourglass",
                value: appState.totalTimeToday.formatted(),
                label: "Total Time",
                color: accentColor.opacity(0.85)
            )
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 30)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5), value: isAnimating)
        }
    }
}
