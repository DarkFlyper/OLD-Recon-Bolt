import SwiftUI
import ValorantAPI

struct StatisticsContainer: View {
	var user: User
	var matchList: MatchList
	
	@Environment(\.ownsProVersion) private var ownsProVersion
	@Environment(\.deepLink) private var deepLink
	
	var body: some View {
		if #available(iOS 16.0, *) {
			if ownsProVersion {
				StatisticsView(user: user, matchList: matchList)
			} else {
				GroupBox {
					VStack {
						Text("Statistics not available!", comment: "Statistics Pro purchase prompt")
							.multilineTextAlignment(.center)
							.font(.title.weight(.bold))
							.padding(.bottom, 4)
						
						Text("Statistics require \(Text("Recon Bolt Pro").fontWeight(.medium)), a one-time purchase including a variety of features. Want to give them a look?", comment: "Statistics Pro purchase prompt: 'Recon Bolt Pro' is inserted in the placeholder with a bolder font.")
							.frame(maxWidth: .infinity, alignment: .leading)
							.padding(.bottom, 12)
						
						// TODO: sales pitch incl. screenshots? blurred view?
						
						Button {
							deepLink(.storefront)
						} label: {
							HStack {
								Text("View Store in Settings", comment: "Statistics Pro purchase prompt: button")
								Image(systemName: "chevron.forward")
							}
						}
						.buttonStyle(.borderedProminent)
						.fontWeight(.medium)
					}
					.padding(8)
				}
				.padding()
				.navigationTitle("Statistics")
			}
		} else {
			GroupBox {
				VStack {
					Text("Statistics not available!", comment: "Statistics error for iOS <16")
						.font(.title.weight(.bold))
						.padding(.bottom, 4)
					Text("This feature requires iOS 16 or newer.", comment: "Statistics error for iOS <16")
				}
			}
			.padding()
			.navigationTitle("Statistics")
		}
	}
}

#if DEBUG
@available(iOS 16.0, *)
struct StatisticsViewWrapper_Previews: PreviewProvider {
	static var previews: some View {
		StatisticsContainer(user: PreviewData.user, matchList: PreviewData.matchList)
			.withToolbar()
			.previewDisplayName("Container")
	}
}
#endif
