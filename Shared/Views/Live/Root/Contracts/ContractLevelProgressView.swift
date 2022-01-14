import SwiftUI
import ValorantAPI

struct ContractLevelProgressView: View {
	var data: ContractData
	var size: CGFloat = 32
	
	var body: some View {
		ZStack {
			CircularProgressView(lineWidth: 4) {
				CircularProgressLayer(
					end: data.currentLevelCompletion,
					shouldKnockOutSurroundings: true,
					color: .accentColor
				)
			} base: {
				Color.gray.opacity(0.25)
			}
			.frame(width: size, height: size)
			.padding(2)
			
			Text("\(data.levelNumber)")
				.font(.footnote)
		}
	}
}
