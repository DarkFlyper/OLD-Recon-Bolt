import StoreKit

enum ReviewManager {
	static var hasRequestedReview = false
	
	static func requestReview() {
		// ugh
		let scene = UIApplication.shared.connectedScenes
			.compactMap { $0 as? UIWindowScene }
			.first { $0.activationState == .foregroundActive }
		guard let scene else { return }
		SKStoreReviewController.requestReview(in: scene)
	}
}
