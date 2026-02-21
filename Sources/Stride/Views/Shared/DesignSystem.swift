import SwiftUI

struct DesignSystem {
    
    // MARK: - Brand Colors
    
    struct Brand {
        static let moss = Color(hex: "#4A7C59")
        static let terracotta = Color(hex: "#C75B39")
        static let gold = Color(hex: "#D4A853")
        static let slate = Color(hex: "#5B7C8C")
        static let mossLight = Color(hex: "#6B9B7A")
    }
    
    // MARK: - Background Colors
    
    struct Background {
        static let warmPaper = Color(hex: "#FAF8F4")
        static let warmPaperLight = Color(red: 0.98, green: 0.973, blue: 0.957)
        static let darkPrimary = Color(hex: "#0F1F17")
        static let darkCard = Color(hex: "#1A2820")
        static let white = Color.white
    }
    
    // MARK: - Text Colors
    
    struct Text {
        static let primary = Color(hex: "#2C2C2C")
        static let secondary = Color(hex: "#616161")
        static let tertiary = Color(hex: "#999999")
        static let lightMuted = Color(hex: "#808080")
        static let lightDim = Color(hex: "#9A9A9A")
    }
    
    // MARK: - Semantic Colors
    
    struct Semantic {
        static let success = Brand.moss
        static let warning = Brand.terracotta
        static let highlight = Brand.gold
        static let info = Brand.slate
    }
    
    // MARK: - Typography
    
    struct Typography {
        // Headers
        static let titleLarge: Font = .system(size: 48, weight: .bold, design: .serif)
        static let titleMedium: Font = .system(size: 28, weight: .bold)
        static let titleSmall: Font = .system(size: 20, weight: .bold)
        
        // Body
        static let bodyLarge: Font = .system(size: 16, weight: .medium)
        static let bodyMedium: Font = .system(size: 14, weight: .medium)
        static let bodySmall: Font = .system(size: 13, weight: .medium)
        
        // Labels
        static let labelLarge: Font = .system(size: 14, weight: .semibold)
        static let labelMedium: Font = .system(size: 12, weight: .semibold)
        static let labelSmall: Font = .system(size: 11, weight: .semibold)
        static let labelMicro: Font = .system(size: 10, weight: .bold)
        
        // Mono
        static let timer: Font = .system(size: 100, weight: .thin, design: .rounded)
        static let statLarge: Font = .system(size: 44, weight: .bold, design: .rounded)
        static let statMedium: Font = .system(size: 24, weight: .bold, design: .rounded)
        static let statSmall: Font = .system(size: 18, weight: .bold, design: .rounded)
    }
    
    // MARK: - Spacing
    
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
        static let huge: CGFloat = 40
        static let massive: CGFloat = 60
    }
    
    // MARK: - Corner Radius
    
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }
    
    // MARK: - Shadows
    
    struct Shadow {
        static let small = ShadowStyle(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        static let medium = ShadowStyle(color: .black.opacity(0.04), radius: 12, x: 0, y: 3)
        static let large = ShadowStyle(color: .black.opacity(0.06), radius: 20, x: 0, y: 10)
        
        struct ShadowStyle {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }
    }
    
    // MARK: - Animation
    
    struct Animation {
        static let entrance = AnimationStyle(response: 0.6, dampingFraction: 0.8)
        static let micro = AnimationStyle(response: 0.3, dampingFraction: 0.7)
        static let sheet = AnimationStyle(response: 0.3, dampingFraction: 0.8)
        static let quick = AnimationStyle(response: 0.2, dampingFraction: 0.4)
        
        struct AnimationStyle {
            let response: Double
            let dampingFraction: Double
            
            var spring: SwiftUI.Animation {
                .spring(response: response, dampingFraction: dampingFraction)
            }
            
            var easeInOut: SwiftUI.Animation {
                .easeInOut(duration: response)
            }
        }
    }
}

struct GlassMaterial: View {
    var cornerRadius: CGFloat = DesignSystem.CornerRadius.xxl
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.white.opacity(0.4))
            .background(
                BlurView(style: .hudWindow)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: DesignSystem.Shadow.medium.color, radius: DesignSystem.Shadow.medium.radius, x: DesignSystem.Shadow.medium.x, y: DesignSystem.Shadow.medium.y)
    }
}

struct CardStyle: ViewModifier {
    var cornerRadius: CGFloat = DesignSystem.CornerRadius.xl
    var padding: CGFloat = DesignSystem.Spacing.xxl
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: DesignSystem.Shadow.medium.color, radius: DesignSystem.Shadow.medium.radius, x: DesignSystem.Shadow.medium.x, y: DesignSystem.Shadow.medium.y)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle(cornerRadius: CGFloat = DesignSystem.CornerRadius.xl, padding: CGFloat = DesignSystem.Spacing.xxl) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius, padding: padding))
    }
}
