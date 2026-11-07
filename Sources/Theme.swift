import SwiftUI

// iOS 26 Liquid Glass styling with graceful fallback.
extension View {
    @ViewBuilder
    func glassButton() -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glass)
        } else {
            self.buttonStyle(.borderedProminent)
        }
    }

    @ViewBuilder
    func glassCard() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect()
        } else {
            self.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

extension CGFloat {
    func clamped(_ r: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, r.lowerBound), r.upperBound)
    }
}
