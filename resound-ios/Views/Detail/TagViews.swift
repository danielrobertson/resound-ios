import SwiftUI

/// Wraps chips onto new lines when a row runs out of width, like the web's
/// flex-wrap tag rows.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(fitting: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.map { $0.height }.reduce(0, +) + spacing * CGFloat(max(0, rows.count - 1))
        let width = rows.map { $0.width }.max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(fitting: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func rows(fitting maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            let widthIfAdded = current.width + (current.indices.isEmpty ? 0 : spacing) + size.width
            if !current.indices.isEmpty && widthIfAdded > maxWidth {
                rows.append(current)
                current = Row()
            }
            current.indices.append(index)
            current.width += (current.indices.count == 1 ? 0 : spacing) + size.width
            current.height = max(current.height, size.height)
        }
        if !current.indices.isEmpty {
            rows.append(current)
        }
        return rows
    }
}

/// One tag capsule. Passing `onRemove` appends a small ✕ affordance.
struct TagChip: View {
    let tag: String
    var onRemove: (() -> Void)?

    var body: some View {
        HStack(spacing: 6) {
            Text(tag)
                .font(.body(12, .medium, relativeTo: .caption))
                .foregroundStyle(Color.appForeground.opacity(0.8))
                .lineLimit(1)

            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color.appMutedForeground)
                        .frame(width: 16, height: 16)
                        .contentShape(Circle())
                }
                .accessibilityLabel("Remove tag \(tag)")
            }
        }
        .padding(.leading, 12)
        .padding(.trailing, onRemove == nil ? 12 : 8)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.appMuted))
        .overlay(Capsule().strokeBorder(Color.appBorder.opacity(0.7)))
    }
}
