import SwiftUI

struct DonutChartItem: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let color: Color
    
    var percentage: Double {
        0
    }
}

struct DonutChart: View {
    let items: [DonutChartItem]
    let lineWidth: CGFloat
    let centerContent: AnyView?
    
    init(
        items: [DonutChartItem],
        lineWidth: CGFloat = 28,
        @ViewBuilder center: () -> some View = { EmptyView() }
    ) {
        self.items = items
        self.lineWidth = lineWidth
        self.centerContent = AnyView(center())
    }
    
    private var total: Double {
        items.reduce(0) { $0 + $1.value }
    }
    
    private func startAngle(for index: Int) -> Double {
        guard total > 0 else { return 0 }
        
        var start: Double = 0
        for i in 0..<index {
            start += items[i].value / total
        }
        return start
    }
    
    private func endAngle(for index: Int) -> Double {
        guard total > 0 else { return 0 }
        
        var end: Double = 0
        for i in 0...index {
            end += items[i].value / total
        }
        return end
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.black.opacity(0.03), lineWidth: lineWidth)
            
            ForEach(Array(items.prefix(5).enumerated()), id: \.element.id) { index, item in
                Circle()
                    .trim(from: startAngle(for: index), to: endAngle(for: index))
                    .stroke(
                        item.color,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt)
                    )
                    .rotationEffect(.degrees(-90))
            }
            
            centerContent
        }
    }
}

struct DonutChartLegend: View {
    let items: [DonutChartItem]
    let valueFormatter: (Double) -> String
    
    init(
        items: [DonutChartItem],
        valueFormatter: @escaping (Double) -> String = { TimeInterval($0).formattedShort }
    ) {
        self.items = items
        self.valueFormatter = valueFormatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            ForEach(items.prefix(5)) { item in
                HStack(spacing: DesignSystem.Spacing.sm) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(item.color)
                        .frame(width: 12, height: 12)
                    
                    Text(item.label)
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Text.primary)
                    
                    Spacer()
                    
                    Text(valueFormatter(item.value))
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(DesignSystem.Text.secondary)
                }
            }
        }
    }
}

struct DonutChartWithLegend: View {
    let items: [DonutChartItem]
    let centerValue: String
    let centerLabel: String
    
    init(
        items: [DonutChartItem],
        centerValue: String,
        centerLabel: String = "LABELS"
    ) {
        self.items = items
        self.centerValue = centerValue
        self.centerLabel = centerLabel
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xxxl) {
            DonutChart(items: items) {
                VStack(spacing: 2) {
                    Text(centerValue)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.Text.primary)
                    Text(centerLabel)
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(DesignSystem.Text.secondary)
                }
            }
            .frame(width: 140, height: 140)
            
            DonutChartLegend(items: items)
        }
    }
}
