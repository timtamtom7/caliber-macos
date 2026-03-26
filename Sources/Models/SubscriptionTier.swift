import Foundation

/// R16: Subscription tiers for Caliber
public enum CaliberSubscriptionTier: String, Codable, CaseIterable {
    case free = "free"
    case pro = "pro"
    case team = "team"
    
    public var displayName: String {
        switch self { case .free: return "Free"; case .pro: return "Caliber Pro"; case .team: return "Caliber Team" }
    }
    public var monthlyPrice: Decimal? {
        switch self { case .free: return nil; case .pro: return 4.99; case .team: return 9.99 }
    }
    public var maxMeasurements: Int? {
        switch self { case .free: return 50; case .pro: return nil; case .team: return nil }
    }
    public var supportsProjects: Bool { self != .free }
    public var supportsCalibrationWizard: Bool { self != .free }
    public var supportsAdvancedReports: Bool { self == .pro || self == .team }
    public var supportsWidgets: Bool { self != .free }
    public var supportsShortcuts: Bool { self != .free }
    public var supportsTeamSharing: Bool { self == .team }
    public var trialDays: Int { self == .free ? 0 : 14 }
}

public struct CaliberSubscription: Codable {
    public let tier: CaliberSubscriptionTier
    public let status: String
    public let expiresAt: Date?
    public init(tier: CaliberSubscriptionTier, status: String = "active", expiresAt: Date? = nil) {
        self.tier = tier; self.status = status; self.expiresAt = expiresAt
    }
}
