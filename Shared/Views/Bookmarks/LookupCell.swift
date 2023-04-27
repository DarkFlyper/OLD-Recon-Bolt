import SwiftUI
import ValorantAPI

struct LookupCell: View {
	@State var gameName = ""
	@State var tagLine = ""
	@State var isLoading = false
	@ObservedObject var history: LookupHistory
	
	@FocusState private var focusedField: Field?
	
	@Environment(\.loadWithErrorAlerts) private var load
	
	@ScaledMetric(relativeTo: .body) private var maxNameFieldWidth = 150
	@ScaledMetric(relativeTo: .body) private var tagFieldWidth = 50
	
	var body: some View {
		ZStack {
			// this button is not visible but triggers when the cell is tapped—.onTapGesture breaks actual buttons in the cell
			Button("cell tap trigger") {
				print("cell tapped!")
				focusedField = .gameName
			}
			.opacity(0)
			
			content
		}
	}
	
	private var content: some View {
		ScrollViewReader { scrollView in
			HStack {
				HStack {
					TextField(String(localized: "Name", comment: "Bookmark/Player List: lookup name placeholder"), text: $gameName)
						.frame(maxWidth: maxNameFieldWidth)
						.focused($focusedField, equals: .gameName)
						.submitLabel(.next)
						.onSubmit {
							focusedField = .tagLine
						}
					
					HStack {
						Text("#", comment: "Bookmark/Player List: lookup text fields")
							.foregroundStyle(.secondary)
						
						TextField(String(localized: "Tag", comment: "Bookmark/Player List: lookup tag placeholder"), text: $tagLine)
							.frame(width: tagFieldWidth)
							.focused($focusedField, equals: .tagLine)
							.submitLabel(.search)
							.onSubmit { lookUpPlayer(scrollView: scrollView) }
					}
					.onTapGesture {
						focusedField = .tagLine
					}
				}
				.textInputAutocapitalization(.never)
				.autocorrectionDisabled()
				.opacity(isLoading ? 0.5 : 1)
				
				Spacer()
				
				Button {
					lookUpPlayer(scrollView: scrollView)
				} label: {
					Label(String(localized: "Look Up", comment: "Bookmark/Player List: lookup button"), systemImage: "magnifyingglass")
				}
				.disabled(gameName.isEmpty || tagLine.isEmpty)
				.fixedSize()
				.overlay(alignment: .leading) {
					if isLoading {
						ProgressView()
					}
				}
			}
			.aligningListRowSeparator()
			.disabled(isLoading)
			.padding(.vertical, 8)
		}
	}
	
	private func lookUpPlayer(scrollView: ScrollViewProxy) {
		guard !gameName.isEmpty, !tagLine.isEmpty else { return }
		Task {
			isLoading = true
			let name = "\(gameName) #\(tagLine)"
			await load(errorTitle: "Could not look up \(name)") {
				let (user, location) = try await HenrikClient.shared.lookUpPlayer(name: gameName, tag: tagLine)
				LocalDataProvider.dataFetched(user)
				dispatchPrecondition(condition: .onQueue(.main))
				history.lookedUp(user.id, location: location)
				scrollView.scrollTo(user.id, anchor: nil) // TODO: this doesn't seem to do anything
			}
			isLoading = false
		}
	}
	
	enum Field: Hashable {
		case gameName
		case tagLine
	}
}

#if DEBUG
struct LookupCell_Previews: PreviewProvider {
	static var previews: some View {
		VStack(spacing: 0) {
			LookupCell(history: LookupHistory())
				.padding()
			Divider()
			LookupCell(gameName: "Example", tagLine: "EX123", history: LookupHistory())
				.padding()
			Divider()
			LookupCell(gameName: "Example", tagLine: "EX123", isLoading: true, history: LookupHistory())
				.padding()
		}
		.frame(width: 400)
		.previewLayout(.sizeThatFits)
	}
}
#endif
