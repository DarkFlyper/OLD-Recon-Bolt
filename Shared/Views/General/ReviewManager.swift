import StoreKit
import UserDefault

enum ReviewManager {
	@UserDefault("usageScore")
	private static var usageScore = 0
	private static var hasRequestedReview = false
	
	static func registerUsage(points: Int) {
		usageScore += points
		print("usage score:", usageScore)
	}
	
	static func requestReviewIfAppropriate() {
		if usageScore > 100 {
			usageScore = 0
			requestReview()
		}
	}
	
	private static func requestReview() {
		// ugh
		let scene = UIApplication.shared.connectedScenes
			.compactMap { $0 as? UIWindowScene }
			.first { $0.activationState == .foregroundActive }
		guard let scene else { return }
		SKStoreReviewController.requestReview(in: scene)
	}
}
