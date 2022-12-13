import SwiftUI

struct InAppStorefront: View {
	@ObservedObject var store: InAppStore
	@State var purchaseError: Error?
	
	var body: some View {
		HStack {
			VStack(alignment: .leading, spacing: 12) {
				Text("Recon Bolt Pro")
					.font(.title2.bold())
					.foregroundColor(.blue)
				
				VStack(alignment: .leading, spacing: 8) {
					if store.ownsProVersion {
						Text("Thank you for supporting Recon Bolt!").font(.callout)
						Text("I hope you enjoy the pro features :)").font(.callout)
					} else {
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
						.font(.footnote)
					}
				}
			}
			.padding(.vertical, 8)
			
			Spacer()
			
			Image("Pro Icon")
				.resizable()
				.aspectRatio(contentMode: .fit)
				.frame(minWidth: 120, maxHeight: 256)
				.layoutPriority(-1)
		}
		
		NavigationLink("View All Features") {
			ProFeaturesOverview()
		}
		
		if !store.ownsProVersion {
			purchaseButton
		}
	}
	
	@ViewBuilder
	var purchaseButton: some View {
		if let product = store.proVersion.resolved {
			AsyncButton {
				do {
					try await store.purchase(product)
				} catch {
					print(error)
					purchaseError = error
				}
			} label: {
				Text("Purchase – \(product.displayPrice)")
					.frame(maxWidth: .infinity)
			}
			.alert("Purchase Failed!", for: $purchaseError)
		} else {
			HStack {
				Text("Loading Store Info…")
					.foregroundStyle(.secondary)
				Spacer()
				ProgressView()
			}
			.task { await store.fetchProducts() }
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
					Text("If you have accounts in multiple regions to play with friends around the world, this is the feature for you!")
				}
			}
			
			// TODO: implement
			Section {
				description("Home Screen Widgets") {
					Text("TODO")
					// TODO: note iOS 16+ restriction!
				}
			}
			
			// TODO: implement
			Section {
				description("Advanced Stats") {
					Text("TODO")
					// TODO: note iOS 16+ restriction (if applicable)!
				}
			}
			
			Section {
				HStack {
					Spacer()
					AppIcon.Thumbnail(icon: .default, size: 120)
					Spacer()
					AppIcon.Thumbnail(icon: .proBlue, size: 120)
					Spacer()
				}
				.padding()
				.frame(maxHeight: 256)
				
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
		Image("pro features/\(name)")
			.resizable()
			.aspectRatio(contentMode: .fit)
			.frame(maxWidth: .infinity, maxHeight: 256)
			.listRowInsets(.init())
			.aligningListRowSeparator()
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

#if DEBUG
struct InAppStorefront_Previews: PreviewProvider {
    static var previews: some View {
		Form {
			InAppStorefront(store: .init())
		}
		.withToolbar()
		//.previewDevice("iPad Pro (11-inch) (4th generation)")
		
		ProFeaturesOverview()
			.withToolbar()
    }
}
#endif
