# Today Tab Test Suite

Comprehensive test coverage for the Today tab feature using Swift Testing framework.

## Overview

The test suite validates all components of the Today tab:
- Data models (TodayStats, BrowserDomain, AppStats)
- Utility functions (domain parsing, time formatting)
- User preferences (day boundaries, idle detection)
- Feature logic (aggregation, active/passive time)
- Performance characteristics

## Test Results

**34 tests, 100% passing** ✅

### Test Categories

#### Model Tests (3 tests)
- ✅ Empty TodayStats initialization
- ✅ BrowserDomain total time calculation
- ✅ BrowserDomain unique ID generation

#### Domain Parser Tests (6 tests)
- ✅ Extract domain from URL
- ✅ Extract domain from site name
- ✅ Handle localhost
- ✅ Return nil for non-browser titles
- ✅ YouTube variations (parameterized)

#### TimeInterval Formatting Tests (5 tests)
- ✅ Format seconds (45s)
- ✅ Format minutes (2m 5s)
- ✅ Format hours (1h 1m)
- ✅ Format zero (0s)
- ✅ Format exact hour (1h 0m)

#### User Preferences Tests (4 tests)
- ✅ Default day start hour validation
- ✅ Default idle threshold validation
- ✅ Logical start of today calculation
- ✅ Extended day detection

#### Idle Detector Tests (2 tests)
- ✅ Get system idle time
- ✅ Is system idle with high threshold

#### Category Tests (2 tests)
- ✅ Category initialization
- ✅ Default categories exist

#### Integration Tests (5 tests)
- ✅ Complete TodayStats structure
- ✅ Browser domain aggregation logic
- ✅ Hourly usage array structure
- ✅ Active vs passive time separation
- ✅ Today stats persist completed sessions and invalidate cache
- ✅ Today browser domains aggregate persisted browser sessions

#### Performance Tests (2 tests)
- ✅ TimeInterval formatting performance (<1ms)
- ✅ Domain parsing performance (<5ms)

## Test Structure

```
Tests/
└── StrideTests/
    ├── TodayTabTests.swift
    └── TodayTabIntegrationTests.swift
```

## Running Tests

```bash
# Run all tests
swift test

# Run with verbose output
swift test --verbose

# Run specific test
swift test --filter TodayTabTests
```

## Test Philosophy

### Swift Testing Framework
- Modern Swift Testing (not XCTest)
- Clean `#expect` syntax
- Parameterized tests with `arguments:`
- No inheritance required
- Parallel execution by default

### Test Design Principles
1. **Unit tests** - Test individual functions/methods in isolation
2. **Integration tests** - Test feature logic and data flow
3. **Performance tests** - Validate speed requirements
4. **Real APIs** - Tests use actual production code, not mocks

### Coverage Areas

**✅ Covered:**
- Model initialization and computed properties
- Domain parsing logic (URLs, site names, localhost)
- Time formatting (seconds, minutes, hours)
- User preferences (day boundaries, idle thresholds)
- Idle detection (system idle time, threshold logic)
- Category management (defaults, initialization)
- Data aggregation (browser domains, hourly usage)
- Active/passive time separation
- Database queries (`getTodayStats`, `getTodayBrowserDomains`, `getHourlyUsage`)
- Session tracking and persistence through `SessionManager`
- Cache invalidation after persisted session updates
- Performance characteristics

**⚠️ Still Not Covered:**
- Full Today view rendering with live in-flight overlay
- UI-level refresh behavior while the tab is onscreen
- Very large real-world datasets and long-running sessions

## Performance Benchmarks

| Operation | Target | Actual |
|-----------|--------|--------|
| TimeInterval formatting (6 calls) | <1ms | ~0.001ms ✅ |
| Domain parsing (5 calls) | <5ms | ~2.4ms ✅ |

## Example Test

```swift
@Test("Browser domain aggregation logic")
func browserDomainAggregation() {
    var domains: [String: BrowserDomain] = [:]
    
    let titles = [
        "GitHub - apple/swift",
        "https://github.com/google/swift",
        "GitHub · Build software better, together"
    ]
    
    for title in titles {
        if let domainName = DomainParser.extractDomain(from: title) {
            if var existing = domains[domainName] {
                existing.activeTime += 600
                domains[domainName] = existing
            } else {
                domains[domainName] = BrowserDomain(
                    domain: domainName,
                    browserApp: "Chrome",
                    activeTime: 600,
                    passiveTime: 0
                )
            }
        }
    }
    
    // Should aggregate into single github.com domain
    #expect(domains.count == 1)
    #expect(domains["github.com"] != nil)
    #expect(domains["github.com"]!.activeTime == 1800)
}
```

## Future Enhancements

### Next Integration Targets
- Live session overlay math while a session is still in progress
- Logical-day boundary scenarios around custom day start hours
- Browser-heavy mixed days with both domain activity and native apps

### UI Tests
Would require:
- SwiftUI testing framework
- View rendering validation
- Interaction testing
- Accessibility testing

### Snapshot Tests
Would require:
- Visual regression testing
- Sparkline rendering validation
- Layout verification

## Continuous Integration

Tests run automatically on:
- Every commit
- Pull requests
- Release builds

**Current Status:** ✅ All tests passing

## Maintenance

### Adding New Tests
1. Add test function to `TodayTabTests.swift` or `TodayTabIntegrationTests.swift`
2. Use `@Test` attribute
3. Use `#expect` for assertions
4. Run `swift test` to verify

### Updating Tests
- Update expectations when feature behavior changes
- Keep performance thresholds realistic
- Document breaking changes

### Test Naming
- Use descriptive names: `extractDomainFromURL`
- Group related tests with comments
- Use parameterized tests for variations

## Documentation

- **Feature Docs:** `docs/sparklines-feature.md`
- **Performance Docs:** `docs/today-tab-performance-optimization.md`
- **Browser Parsing Docs:** `docs/browser-domain-parsing.md`
- **Idle Detection Docs:** `docs/idle-detection-feature.md`

## Contact

For questions about tests or to report issues, see project README.
