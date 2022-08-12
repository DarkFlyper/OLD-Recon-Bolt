import SwiftUI

struct ReferenceView: View {
	var body: some View {
		AssetsUnwrappingView { assets in
			List {
				Section {
					Group {
						NavigationLink {
							MapListView()
						} label: {
							Label("Maps", systemImage: "map")
						}
						
						NavigationLink {
							AgentListView()
						} label: {
							Label("Agents", systemImage: "person")
						}
					}
					.font(.title2)
					.padding(.vertical, 8)
				} footer: {
					Text("Version \(assets.version.version)")
				}
			}
		}
		.navigationTitle("Reference")
	}
}

#if DEBUG
struct ReferenceView_Previews: PreviewProvider {
	static var previews: some View {
		ReferenceView()
			.withToolbar()
	}
}
#endif
