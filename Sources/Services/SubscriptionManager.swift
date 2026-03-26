import Foundation
import StoreKit

/// R16: Subscription management for Caliber
@available(macOS 13.0, *)
public final class CaliberSubscriptionManager: ObservableObject {
    public static let shared = CaliberSubscriptionManager()
    @Published public private(set) var subscription: CaliberSubscription?
    @Published public private(set) var products: [Product] = []
    
    private init() {}
    
    public func loadProducts() async {
        do {
            products = try await Product.products(for: [
                "com.caliber.macos.pro.monthly",
                "com.caliber.macos.pro.yearly",
                "com.caliber.macos.team.monthly",
                "com.caliber.macos.team.yearly"
            ])
        } catch { print("Failed to load products") }
    }
    
    public func canAccess(_ feature: CaliberFeature) -> Bool {
        guard let sub = subscription else { return false }
        switch feature {
        case .projects: return sub.tier != .free
        case .calibrationWizard: return sub.tier != .free
        case .advancedReports: return sub.tier == .pro || sub.tier == .team
        case .widgets: return sub.tier != .free
        case .shortcuts: return sub.tier != .free
        case .teamSharing: return sub.tier == .team
        }
    }
    
    public func updateStatus() async {
        var found: CaliberSubscription = CaliberSubscription(tier: .free)
        for await result in Transaction.currentEntitlements {
            do {
                let t = try checkVerified(result)
                if t.productID.contains("team") {
                    found = CaliberSubscription(tier: .team, status: t.revocationDate == nil ? "active" : "expired")
                } else if t.productID.contains("pro") {
                    found = CaliberSubscription(tier: .pro, status: t.revocationDate == nil ? "active" : "expired")
                }
            } catch { continue }
        }
        await MainActor.run { self.subscription = found }
    }
    
    public func restore() async throws {
        try await AppStore.sync()
        await updateStatus()
    }
    
    private func checkVerified<T>(_ r: VerificationResult<T>) throws -> T {
        switch r { case .unverified: throw NSError(domain: "Caliber", code: -1); case .verified(let s): return s }
    }
}

public enum CaliberFeature { case projects, calibrationWizard, advancedReports, widgets, shortcuts, teamSharing }
