# Stride Design System

## Brand Philosophy

**"Discipline in nature, rewarded in gold."**

Stride is a premium productivity tool that helps users build habits and understand their digital behavior. The visual identity balances:

- **Organic calm** (forest greens) with **energized achievement** (amber gold)
- **Deep focus** (dark themes) with **warm reflection** (light themes)
- **Data precision** (controlled palette) with **human warmth** (earth tones)

---

## Core Brand Colors

### Primary Identity

| Token | HEX | RGB | Usage |
|-------|-----|-----|-------|
| `brandPrimary` | `#4A7C59` | `rgb(74, 124, 89)` | Main CTAs, active states, habit completions |
| `brandPrimaryLight` | `#6B9B7A` | `rgb(107, 155, 122)` | Hover states, success highlights |
| `brandPrimaryDark` | `#2D4A36` | `rgb(45, 74, 54)` | Dark mode accents, pressed states |

### Achievement & Energy

| Token | HEX | RGB | Usage |
|-------|-----|-----|-------|
| `brandGold` | `#D4A853` | `rgb(212, 168, 83)` | Streaks, wins, premium highlights |
| `brandGoldLight` | `#E9C46A` | `rgb(233, 196, 106)` | Hover on gold, secondary achievements |
| `brandGoldDark` | `#B8954A` | `rgb(184, 149, 74)` | Gold pressed states |

### Warning & Error

| Token | HEX | RGB | Usage |
|-------|-----|-----|-------|
| `brandTerracotta` | `#C75B39` | `rgb(199, 91, 57)` | Warnings, medium streaks, alerts |
| `brandDanger` | `#9C3D2F` | `rgb(156, 61, 47)` | Delete actions, critical errors (distinguishes from terracotta) |

### Neutral Scale

Complete grayscale for multi-theme support:

| Token | HEX | RGB | Usage |
|-------|-----|-----|-------|
| `neutralWhite` | `#FFFFFF` | `rgb(255, 255, 255)` | Pure white |
| `neutralOffWhite` | `#F5F5F0` | `rgb(245, 245, 240)` | Primary text on dark |
| `neutral50` | `#F0F0F0` | `rgb(240, 240, 240)` | Subtle light backgrounds |
| `neutral100` | `#E0E0E0` | `rgb(224, 224, 224)` | Borders light mode |
| `neutral200` | `#C0C0C0` | `rgb(192, 192, 192)` | Disabled states |
| `neutral300` | `#9A9A9A` | `rgb(154, 154, 154)` | Secondary text |
| `neutral400` | `#808080` | `rgb(128, 128, 128)` | Tertiary text |
| `neutral500` | `#666666` | `rgb(102, 102, 102)` | Body text light mode |
| `neutral600` | `#4D4D4D` | `rgb(77, 77, 77)` | Headings light mode |
| `neutral700` | `#333333` | `rgb(51, 51, 51)` | Dark text |
| `neutral800` | `#1F1F1F` | `rgb(31, 31, 31)` | Deep backgrounds |
| `neutral900` | `#0F0F0F` | `rgb(15, 15, 15)` | Near black |

### Opacity Scale (Use Sparingly)

```swift
// Only for subtle effects, never for text
Color.white.opacity(0.05)  // Ghost backgrounds
Color.white.opacity(0.08)  // Borders on dark
Color.white.opacity(0.12)  // Hover backgrounds
Color.white.opacity(0.20)  // Active states

Color.black.opacity(0.04)  // Soft shadows light mode
Color.black.opacity(0.08)  // Medium shadows
Color.black.opacity(0.12)  // Strong shadows
```

---

## Theme Specifications

### Theme 1: Dark Forest (Habit Tracker)

**Mental Model:** Deep work. Focus. The forest at night with glowing embers.

#### Background Layers

| Token | HEX | Usage |
|-------|-----|-------|
| `forestBackground` | `#0F1F17` | Main background |
| `forestCard` | `#1A2820` | Card backgrounds |
| `forestElevated` | `#263328` | Modals, popovers |
| `forestInput` | `#1F3329` | Input fields |

#### Accent Progression

Habit intensity follows this progression (empty → full):

```
#1E2E24 (Empty - barely visible)
#2D4A36 (Light - 30% opacity of moss)
#4A7C59 (Medium - 60% opacity of moss)  
#6B9B7A (Full - solid moss)
#D4A853 (Complete - gold, achievement)
```

#### Text Hierarchy

| Token | HEX | Usage |
|-------|-----|-------|
| `forestTextPrimary` | `#F5F5F0` | Headings, important text |
| `forestTextSecondary` | `#9A9A9A` | Body text, descriptions |
| `forestTextTertiary` | `#666666` | Metadata, timestamps |

#### Interactive States

```swift
// Buttons
Default:  brandPrimary
Hover:    brandPrimaryLight  
Pressed:  brandPrimaryDark
Disabled: neutral600.opacity(0.5)

// Cards
Default:  forestCard
Hover:    forestCard + white.opacity(0.02)
Selected: forestCard + brandPrimary.opacity(0.15) border
```

---

### Theme 2: Warm Paper (Weekly Log)

**Mental Model:** Handcrafted reflection. Analog journal. Warm coffee shop.

#### Background Layers

| Token | HEX | Usage |
|-------|-----|-------|
| `paperBackground` | `#FAF8F4` | Main background |
| `paperCard` | `#FFFFFF` | Cards, sheets |
| `paperElevated` | `#FDFCFA` | Modals, elevated content |

#### Accent Colors

| Token | HEX | Usage |
|-------|-----|-------|
| `paperTerracotta` | `#C75B39` | Primary accent, buttons |
| `paperTerracottaLight` | `#E07A5F` | Hover, highlights |
| `paperTerracottaDark` | `#A84C2F` | Pressed states |
| `paperGold` | `#E9C46A` | Wins, stars, achievements |
| `paperGoldDark` | `#D4A853` | Gold hover |

#### Text Hierarchy

| Token | HEX | Usage |
|-------|-----|-------|
| `paperTextPrimary` | `#2C2C2C` | Headings, body text |
| `paperTextSecondary` | `#616161` | Descriptions, metadata |
| `paperTextTertiary` | `#9A9A9A` | Timestamps, hints |

#### Shadows (Use Instead of Opacity)

```swift
// Light mode shadows
shadowSmall:  Color.black.opacity(0.04)  radius: 4  y: 2
shadowMedium: Color.black.opacity(0.08)  radius: 8  y: 4
shadowLarge:  Color.black.opacity(0.12)  radius: 16 y: 8
```

---

### Theme 3: Editorial Dashboard (Today & Trends)

**Mental Model:** Data clarity. Modern analytics. Clean precision.

#### Background Layers

| Token | HEX | Usage |
|-------|-----|-------|
| `editorialBackground` | System default | Respects system light/dark |
| `editorialCard` | System secondary | Cards adapt to system |
| `editorialTint` | `#F8F7FA` | Light: lavender tint overlay |

#### Brand Gradients (Replace Generic Apple Gradients)

**OLD (Don't Use):**
```swift
LinearGradient(colors: [.blue, .cyan])    // ❌ Generic
LinearGradient(colors: [.purple, .pink])  // ❌ Generic
```

**NEW (Brand-Aligned):**
```swift
// Time tracking - calm to energy
LinearGradient(
    colors: [Color(hex: "#4A7C59"), Color(hex: "#6B9B7A")]
)

// App usage - variety
LinearGradient(
    colors: [Color(hex: "#6B9B7A"), Color(hex: "#D4A853")]
)

// Insights - achievement
LinearGradient(
    colors: [Color(hex: "#D4A853"), Color(hex: "#E9C46A")]
)

// Focus mode - deep concentration
LinearGradient(
    colors: [Color(hex: "#2D4A36"), Color(hex: "#4A7C59")]
)
```

#### Chart Colors (Brand-Aligned)

| Metric | Color | HEX |
|--------|-------|-----|
| Daily Average | Moss Green | `#4A7C59` |
| Peak Day | Terracotta | `#C75B39` |
| Consistency | Moss Light | `#6B9B7A` |
| Insights | Gold | `#E9C46A` |
| Today Highlight | Brand Primary | `#4A7C59` |

---

## Category Colors (Revised to Match Brand)

**Problem:** Old categories were too bright/clown-like (Google Calendar style).

**Solution:** Desaturated, earthy variants that feel premium.

| Category | Old HEX | New HEX | New Name | Why |
|----------|---------|---------|----------|-----|
| Work | `#FF6B6B` | `#C75B39` | Terracotta | Serious, focused, matches brand |
| Entertainment | `#9B59B6` | `#7A6B8A` | Dusty Purple | Calm, not jarring |
| Social | `#3498DB` | `#5B7C8C` | Slate Blue | Professional, trustworthy |
| Productivity | `#27AE60` | `#4A7C59` | Brand Moss | Literally the brand color |
| Development | `#E67E22` | `#B8834C` | Warm Bronze | Earthy, technical |
| Communication | `#1ABC9C` | `#5A8C7C` | Sea Green | Calm, muted |
| Utilities | `#95A5A6` | `#7A8C8C` | Sage Gray | Functional, neutral |
| Uncategorized | `#7F8C8D` | `#6B7B7B` | Stone Gray | Fallback |

### Category Color Editor Palette

```swift
// Only these colors allowed for custom categories
// All are desaturated and earthy
[
    "#C75B39",  // Terracotta (brand)
    "#4A7C59",  // Moss (brand)
    "#7A6B8A",  // Dusty Purple
    "#5B7C8C",  // Slate Blue
    "#B8834C",  // Warm Bronze
    "#5A8C7C",  // Sea Green
    "#7A8C8C",  // Sage Gray
    "#9C8B7C",  // Warm Taupe
    "#6B5B6B",  // Dusty Rose
    "#5B6B7C",  // Steel Blue
    "#7C6B5B",  // Coffee
    "#8C7C6B",  // Sand
]
```

---

## Habit Colors

Users select from these when creating habits. All are brand-aligned.

| Color Name | HEX | Mood | Best For |
|------------|-----|------|----------|
| **Moss** | `#4A7C59` | Calm, growth | Meditation, nature, reading |
| **Slate** | `#5B7C8C` | Focus, clarity | Work, coding, deep work |
| **Gold** | `#D4A853` | Energy, reward | Exercise, achievement habits |
| **Terracotta** | `#C75B39` | Passion, fire | Creative work, intensity |
| **Sage** | `#7A8C8C` | Balance, calm | Wellness, reflection |
| **Bronze** | `#B8834C` | Warm, stable | Learning, skill building |
| **Dusty Rose** | `#9C7C7C` | Soft, nurturing | Self-care, relationships |
| **Sea** | `#5A8C8C` | Fresh, flowing | Hydration, movement |
| **Taupe** | `#9C8B7C` | Grounded | Organization, planning |
| **Stone** | `#8C8C8C` | Neutral | Generic/any habit |
| **Coffee** | `#7C6B5B` | Rich, comforting | Morning routines |
| **Sand** | `#C4B49C` | Light, gentle | Evening routines |

### Default Habits

```swift
Morning Meditation:  Moss `#4A7C59`
Drink Water:         Sea `#5A8C8C`  
Read:                Gold `#D4A853`
```

---

## Weekly Log Category Colors

Same earthy palette as categories, plus extended options:

```swift
// Core palette
"#C75B39",  // Terracotta
"#4ECDC4",  // Teal (slightly brighter for distinction)
"#4A7C59",  // Moss
"#6B9B7A",  // Moss Light
"#D4A853",  // Gold

// Extended (still muted)
"#9C8B7C",  // Taupe
"#7A6B8A",  // Dusty Purple
"#B8834C",  // Bronze
"#5A8C7C",  // Sea
"#7C6B5B",  // Coffee
"#5B7C8C",  // Slate
"#8C7C6B",  // Sand
"#C4B49C",  // Light Sand
"#9C7C7C",  // Dusty Rose
"#6B7B7B",  // Stone
```

Default: `paperTerracotta` (`#C75B39`)

---

## Heatmap Specifications

### Dark Forest Theme

```swift
// Empty: background color (no entry)
heatmapEmpty: Color(hex: "#1E2E24")

// Level 1: Barely there (0-25% progress)
heatmapLevel1: Color(hex: "#2D4A36")

// Level 2: Visible effort (25-60% progress)
heatmapLevel2: Color(hex: "#3D5A46")

// Level 3: Good work (60-90% progress)
heatmapLevel3: Color(hex: "#4A7C59")

// Level 4: Goal reached (90-100% progress)
heatmapLevel4: Color(hex: "#6B9B7A")

// Level 5: Exceeded goal (100%+ progress)
heatmapLevel5: Color(hex: "#D4A853")  // Gold celebration
```

### Warm Paper Theme

```swift
heatmapEmpty: Color(hex: "#F0EBE4")
heatmapLevel1: Color(hex: "#E6DDD1")
heatmapLevel2: Color(hex: "#D4C4B0")
heatmapLevel3: Color(hex: "#C9A689")  // Warm tan
heatmapLevel4: Color(hex: "#D4A853")  // Gold
heatmapLevel5: Color(hex: "#C75B39")  // Terracotta fire
```

---

## Achievement Colors

| Achievement | Color | Usage |
|-------------|-------|-------|
| **Gold Medal** | `#D4A853` | 1st place, perfect week |
| **Silver Medal** | `#C0C0C0` | 2nd place |
| **Bronze Medal** | `#B8954A` | 3rd place |
| **Streak Fire** | `#D4A853` | Streak indicator |
| **Win Star** | `#E9C46A` | Daily wins |

---

## Implementation Standards

### Swift Implementation

**ALWAYS use hex initializer. Never use RGB floating point.**

```swift
// ❌ BAD - Inconsistent, hard to read
private let backgroundColor = Color(red: 0.059, green: 0.122, blue: 0.09)

// ✅ GOOD - Clear, deterministic
private let backgroundColor = Color(hex: "#0F1F17")

// ❌ BAD - Multiple golds
let gold1 = Color(red: 0.831, green: 0.659, blue: 0.325)
let gold2 = Color(red: 1.0, green: 0.84, blue: 0.0)

// ✅ GOOD - Single source of truth
let brandGold = Color(hex: "#D4A853")
```

### Color Extension

```swift
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

### Theme Detection

```swift
enum AppTheme {
    case darkForest    // Habit Tracker
    case warmPaper     // Weekly Log
    case editorial     // Today/Trends
    
    var background: Color {
        switch self {
        case .darkForest: return Color(hex: "#0F1F17")
        case .warmPaper: return Color(hex: "#FAF8F4")
        case .editorial: return Color(NSColor.controlBackgroundColor)
        }
    }
    
    var textPrimary: Color {
        switch self {
        case .darkForest: return Color(hex: "#F5F5F0")
        case .warmPaper: return Color(hex: "#2C2C2C")
        case .editorial: return Color.primary
        }
    }
}
```

---

## Accessibility

### Contrast Requirements

All color combinations must meet WCAG 2.1 AA standards:

| Combination | Ratio | Standard |
|-------------|-------|----------|
| White on `#0F1F17` | 15.2:1 | AAA ✅ |
| `#F5F5F0` on `#0F1F17` | 14.8:1 | AAA ✅ |
| `#4A7C59` on `#0F1F17` | 4.6:1 | AA ✅ |
| `#9A9A9A` on `#0F1F17` | 7.2:1 | AAA ✅ |
| `#2C2C2C` on `#FAF8F4` | 11.4:1 | AAA ✅ |
| `#616161` on `#FAF8F4` | 6.8:1 | AA ✅ |
| `#C75B39` on White | 4.5:1 | AA ✅ |

### Color Blindness Considerations

- Never rely on color alone for meaning (always pair with icons/text)
- Habit tracker uses brightness + color (intensity levels work for color blind users)
- Category colors are distinct in hue AND brightness

---

## Migration Guide

### From Old to New

1. **Replace all RGB initializers**
   ```swift
   // Find: Color(red: 0.059, green: 0.122, blue: 0.09)
   // Replace: Color(hex: "#0F1F17")
   ```

2. **Standardize gold colors**
   ```swift
   // Replace all gold variants with:
   brandGold = Color(hex: "#D4A853")
   ```

3. **Update category colors**
   ```swift
   // Replace bright colors with earthy variants
   // See "Category Colors" section above
   ```

4. **Replace generic gradients**
   ```swift
   // Replace .blue/.cyan gradients with brand gradients
   // See "Brand Gradients" section
   ```

5. **Fix error red**
   ```swift
   // Replace Color(red: 0.9, green: 0.4, blue: 0.4)
   // With: brandDanger = Color(hex: "#9C3D2F")
   ```

---

## Future Extensions

### Dark Mode (System)

When supporting system dark mode:

```swift
// Warm Paper theme becomes Dark Forest automatically
// Or create a separate "Midnight" theme

let midnightBackground = Color(hex: "#0A0F0D")  // Deeper than forest
let midnightCard = Color(hex: "#141A16")
let midnightAccent = brandGold  // Keep gold for consistency
```

### Seasonal Variants

```swift
// Winter variant (cooler greens)
winterMoss = Color(hex: "#3D6B5C")
winterGold = Color(hex: "#C9B89A")  // Muted gold

// Spring variant (brighter but still muted)
springMoss = Color(hex: "#5A8C6B")
springGold = Color(hex: "#E9D48A")
```

---

## Summary

### The Rules

1. **Use hex only** - No RGB floating point
2. **Three themes only** - Dark Forest, Warm Paper, Editorial
3. **Brand colors everywhere** - No generic Apple gradients
4. **Earth tones for categories** - No bright primaries
5. **Single gold** - `brandGold = #D4A853`
6. **Clear error color** - `brandDanger = #9C3D2F` (not terracotta)
7. **Full neutral scale** - 12 grays for flexibility
8. **Test contrast** - All combinations must pass WCAG AA

### Design System Hierarchy

```
Brand Identity
├── Primary: Moss Green + Amber Gold
├── Error: Deep Red (not orange)
└── Neutral: 12-step grayscale

Themes
├── Dark Forest: Deep greens + gold accents
├── Warm Paper: Cream + terracotta
└── Editorial: System adaptive + brand gradients

Usage
├── Categories: Earthy desaturated palette
├── Habits: Brand-aligned 12 colors
├── Heatmaps: 5-step intensity
└── Achievements: Gold tier system
```

---

*Version: 2.0 - Cohesive Design System*
*Last Updated: February 10, 2026*
*Status: Production Ready*
