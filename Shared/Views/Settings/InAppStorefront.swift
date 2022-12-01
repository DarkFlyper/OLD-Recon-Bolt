import SwiftUI

struct InAppStorefront: View {
	@ObservedObject var store: InAppStore
	
	var body: some View {
		VStack {
			HStack {
				VStack(alignment: .leading, spacing: 8) {
					Text("Recon Bolt Pro")
						.font(.title2.bold())
						.foregroundColor(.blue)
					
					VStack(alignment: .leading, spacing: 8) {
						let bullets: [LocalizedStringKey] = [
							"Support Further Development!",
							"Multiple Accounts",
							"Home Screen Widgets",
							"Advanced Stats",
						]
						ForEach(bullets.indexed(), id: \.index) { _, bullet in
							HStack(spacing: 8) {
								Circle().frame(width: 3, height: 3)
								Text(bullet)
							}
						}
					}
					.font(.footnote)
				}
				.padding(.vertical)
				
				Image("Pro Icon Transparent")
					.resizable()
					.aspectRatio(contentMode: .fit)
					.frame(minWidth: 120)
					.layoutPriority(-1)
			}
		}
		
		NavigationLink("View All Features") {
			ProFeaturesOverview()
		}
		
		if let product = store.proVersion.resolved {
			AsyncButton {
				do {
					try await store.purchase(product)
				} catch {
					print(error)
				}
			} label: {
				Text("Purchase – \(product.displayPrice)")
					.frame(maxWidth: .infinity)
			}
		}
	}
}

struct ProFeaturesOverview: View {
	var body: some View {
		List {
			Section {
				description("Support Development :)") {
					Text("Recon Bolt does not have and will never have ads. The only way it can make money is through in-app purchases.")
					
					Text("Getting money from Recon Bolt gives me the flexibility and motivation to keep improving the app!")
				}
			}
			
			Section {
				image("multiple accounts")
				
				description("Multiple Account Support") {
					Text("Add multiple accounts and seamlessly switch between them at any time.")
					// todo talk about use case for accounts in other regions
				}
			}
			
			// TODO: implement
			Section {
				description("Home Screen Widgets") {
					Text("TODO")
				}
			}
			
			// TODO: implement
			Section {
				description("Advanced Stats") {
					Text("TODO")
				}
			}
			
			// TODO: implement
			Section {
				description("Exclusive App Icon") {
					Text("As thanks for your support, you get to show off your status with an exclusive app icon!")
					Text("(You can switch between available icons at any time.)")
				}
			}
			
			Section {
				description("Family Sharing") {
					Text("Recon Bolt Pro supports Family Sharing, meaning if just one member of your iCloud family buys it, everyone can use it!")
				}
			}
		}
		.navigationTitle("Pro Features")
	}
	
	func image(_ name: String) -> some View {
		Image(name)
			.resizable()
			.aspectRatio(contentMode: .fit)
			.listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
			.alignmentGuide(.compatibleListRowSeparatorLeading) { $0[.leading] }
	}
	
	func description(_ headline: LocalizedStringKey, @ViewBuilder _ content: () -> some View) -> some View {
		VStack(alignment: .leading, spacing: 8) {
			Text(headline)
				.font(.title3.bold())
				.padding(.bottom, 4)
			
			content()
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(.vertical, 8)
	}
}

struct InAppStorefront_Previews: PreviewProvider {
    static var previews: some View {
		Form {
			InAppStorefront(store: .init())
		}
		.withToolbar()
		
		ProFeaturesOverview()
			.withToolbar()
    }
}
