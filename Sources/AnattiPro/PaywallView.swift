import SwiftUI

/// Anatti Pro paywall (Liquid Glass). Dismisses itself when `isPro` becomes true.
public struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var manager = SubscriptionManager.shared

    public init() {}

    private var ctaTitle: String {
        if let product = manager.product {
            return String(format: ProL10n.string("paywall.cta"), product.displayPrice)
        }
        return ProL10n.string("paywall.price.fallback")
    }

    private var isBusy: Bool { manager.purchaseState == .purchasing }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    features
                    purchaseSection
                    footer
                }
                .frame(maxWidth: 560)
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
            }
            closeButton
        }
        .task { await manager.start() }
        .onChange(of: manager.isPro) { _, newValue in
            guard newValue else { return }
            Task {
                try? await Task.sleep(for: .seconds(1.2))
                dismiss()
            }
        }
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.body.weight(.semibold))
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .padding(16)
        .accessibilityLabel(Text(LocalizedStringKey("paywall.close")))
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            Text(LocalizedStringKey("paywall.title"))
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text(LocalizedStringKey("paywall.subtitle"))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 32)
    }

    private var features: some View {
        GlassEffectContainer(spacing: 12) {
            VStack(alignment: .leading, spacing: 16) {
                featureRow("rectangle.on.rectangle", "paywall.feature.sizes")
                featureRow("film", "paywall.feature.video")
                featureRow("iphone", "paywall.feature.local")
                featureRow("globe", "paywall.feature.languages")
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: .rect(cornerRadius: 24))
        }
    }

    private func featureRow(_ symbol: String, _ key: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 30)
                .accessibilityHidden(true)
            Text(LocalizedStringKey(key))
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var purchaseSection: some View {
        VStack(spacing: 12) {
            statusMessage

            Button {
                Task { await manager.purchase() }
            } label: {
                HStack {
                    if isBusy { ProgressView() }
                    Text(ctaTitle)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .disabled(isBusy || manager.isPro)
            .accessibilityLabel(Text(ctaTitle))

            Button {
                Task { await manager.restore() }
            } label: {
                Text(LocalizedStringKey("paywall.restore"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.glass)
            .controlSize(.regular)
            .disabled(isBusy)
        }
    }

    @ViewBuilder
    private var statusMessage: some View {
        switch manager.purchaseState {
        case .pending:
            Label(LocalizedStringKey("paywall.pending"), systemImage: "hourglass")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        case .success:
            Label(LocalizedStringKey("paywall.thanks"), systemImage: "checkmark.seal.fill")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.green)
                .multilineTextAlignment(.center)
        case .failed(let key):
            Label(LocalizedStringKey(key), systemImage: "exclamationmark.triangle.fill")
                .font(.callout)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
        case .idle, .purchasing:
            if manager.isPro {
                Label(LocalizedStringKey("paywall.thanks"), systemImage: "checkmark.seal.fill")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.green)
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 10) {
            Text(LocalizedStringKey("paywall.renewal"))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 20) {
                Link(destination: PaywallLinks.terms) {
                    Text(LocalizedStringKey("paywall.terms"))
                }
                Link(destination: PaywallLinks.privacy) {
                    Text(LocalizedStringKey("paywall.privacy"))
                }
            }
            .font(.footnote)
        }
    }
}
