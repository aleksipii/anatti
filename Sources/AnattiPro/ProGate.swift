import SwiftUI

/// Shown instead of Pro-only content (used by the Export tab).
public struct ProLockedView: View {
    private let onUnlock: () -> Void

    public init(onUnlock: @escaping () -> Void) {
        self.onUnlock = onUnlock
    }

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(LocalizedStringKey("export.locked"))
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
            Button(action: onUnlock) {
                Text(LocalizedStringKey("export.unlock"))
                    .font(.headline)
                    .padding(.horizontal, 12)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
    }
}

private struct RequiresProModifier: ViewModifier {
    let onLocked: () -> Void
    @State private var manager = SubscriptionManager.shared

    func body(content: Content) -> some View {
        if manager.isPro {
            content
        } else {
            ProLockedView(onUnlock: onLocked)
        }
    }
}

private struct PaywallSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) { PaywallView() }
    }
}

public extension View {
    /// Shows the view only for Pro users; otherwise a locked placeholder whose button calls `onLocked`
    /// (typically sets a flag that presents `paywallSheet`).
    func requiresPro(onLocked: @escaping () -> Void) -> some View {
        modifier(RequiresProModifier(onLocked: onLocked))
    }

    /// Presents `PaywallView` as a sheet.
    func paywallSheet(isPresented: Binding<Bool>) -> some View {
        modifier(PaywallSheetModifier(isPresented: isPresented))
    }
}
