import SwiftUI

struct ReferenceView: View {
	var body: some View {
		MapListView()
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
