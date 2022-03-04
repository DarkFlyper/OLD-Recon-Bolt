import SwiftUI

struct ReferenceView: View {
	@Environment(\.assets) private var assets
	
	var body: some View {
		Group {
			if let assets = assets {
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
			} else {
				Text("Assets not downloaded!")
					.foregroundStyle(.secondary)
					.frame(maxWidth: .infinity, maxHeight: .infinity)
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
			.inEachColorScheme()
	}
}
#endif
