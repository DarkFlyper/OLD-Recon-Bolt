import SwiftUI

struct AboutScreen: View {
	var body: some View {
		List {
			Text("""
				Hi! I'm Julian Dunskus, and I made this app.

				Recon Bolt started development in early 2021, back when it wasn't yet possible to see your RR gains and losses in the game, but the API offered those numbers. I made an app to see the numbers and better understand my rank changes.

				As you can guess, the scope expanded massively over time to what you're using now. I hope you're enjoying it!

				If you've encountered a bug or have some feedback, I'm always happy to hear it on the Discord Server or GitHub :)
				""", comment: "About Screen"
			)
			
			Section(header: Text("Links", comment: "About Screen: section")) {
				ListLink("Discord Server", destination: "https://discord.gg/bwENMNRqNa")
				ListLink("GitHub Repo", destination: "https://github.com/juliand665/Recon-Bolt")
				ListLink("Official Website", destination: "https://dapprgames.com/recon-bolt")
				ListLink("Twitter @juliand665", destination: "https://twitter.com/juliand665")
			}
			
			Section(header: Text("Credits", comment: "About Screen: section")) {
				Text("Many thanks to the volunteer translators from our Discord server who have been hard at working translating the app to new languages!", comment: "About Screen")
				
				VStack(alignment: .leading, spacing: 8) {
					Link("Valorant-API.com" as String, destination: URL(string: "https://valorant-api.com")!)
					Text("An invaluable API hosting all the assets (images, data, etc.) used throughout Valorant. This is where almost every image in the app comes from.", comment: "About Screen")
				}
			}
		}
		.navigationTitle("About")
	}
}

struct ListLink: View {
	var label: LocalizedStringKey
	var icon: String?
	var destination: URL
	
	init(_ label: LocalizedStringKey, icon: String? = nil, destination: String) {
		self.label = label
		self.destination = .init(string: destination)!
		self.icon = icon
	}
	
	var body: some View {
		Link(destination: destination) {
			NavigationLink {} label: {
				Label(label, systemImage: icon ?? "link")
			}
			.tint(.primary)
		}
	}
}

#if DEBUG
struct AboutScreen_Previews: PreviewProvider {
    static var previews: some View {
        AboutScreen()
			.withToolbar()
    }
}
#endif
