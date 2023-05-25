import SwiftUI
import ValorantAPI
import Combine

@available(iOS 16.0, *)
struct LoadingSection: View {
	var matchList: MatchList
	@Binding var fetchedMatches: [MatchDetails]
	
	@State var fetchCount = 20
	@StateObject private var fetcher = MatchFetcher()
	
	@Environment(\.valorantLoad) private var load
	
	private var sublist: ArraySlice<CompetitiveUpdate> {
		matchList.matches.prefix(fetchCount)
	}
	
	var body: some View {
		Section {
			VStack(alignment: .leading, spacing: 16) {
				Text("To gather statistics, we first need to load matches to process. Note that large amounts can take a long time, especially when downloading for the first time!", comment: "Stats: match loading")
				
				Divider()
				
				VStack {
					Text("Matches to load: **\(fetchCount)**", comment: "Stats: match loading")
					
					let oldestTime = sublist.last!.startTime
					Text("Data going back to \(oldestTime, format: .dateTime.year().month().day())", comment: "Stats: match loading")
						.foregroundStyle(.secondary)
						.font(.footnote)
					
					HStack {
						changeButtons(magnitude: 1)
						changeButtons(magnitude: 10)
						changeButtons(magnitude: 100)
						
						Button {
							fetchCount = matchList.matches.count
						} label: {
							Text("All \(matchList.matches.count)", comment: "Stats: match loading")
						}
						.disabled(fetchCount == matchList.matches.count)
					}
					.buttonStyle(.bordered)
					.onAppear {
						fetchCount = clamp(fetchCount)
					}
					
					// TODO: use date instead? or at least allow cutting off from the top? button to filter to specific act?
				}
				.backgroundStyle(Color(.tertiarySystemGroupedBackground))
				.frame(maxWidth: .infinity)
				
				Divider()
				
				Button {
					fetcher.fetchMatches(withIDs: sublist.lazy.map(\.id), load: load)
				} label: {
					Text("Load Latest \(fetchCount) Match(es)", comment: "Stats: match loading")
				}
				.bold()
				.buttonStyle(.borderedProminent)
				.frame(maxWidth: .infinity)
			}
			.padding(.vertical, 4)
			
			if !fetcher.errors.isEmpty {
				VStack(alignment: .leading, spacing: 4) {
					NavigationLink {
						errorList()
					} label: {
						Text("\(fetcher.errors.count) Error(s)", comment: "Stats: match loading")
					}
					
					Text("The remaining \(fetcher.matches.count) match(es) loaded correctly and are displayed below.", comment: "Stats: match loading")
						.font(.footnote)
						.foregroundStyle(.secondary)
				}
			}
		} header: {
			Text("Load Data", comment: "Stats: match loading")
		} footer: {
			let fetchedCount = sublist.count { fetcher.matches.keys.contains($0.id) }
			Text("\(fetchedCount)/\(fetchCount) loaded", comment: "Stats: match loading")
		}
		.onReceive(fetcher.objectWillChange
			.debounce(for: 0.2, scheduler: DispatchQueue.main)
		) { _ in
			fetchedMatches = sublist.compactMap { fetcher.matches[$0.id] }
		}
	}
	
	func errorList() -> some View {
		List(matchList.matches) { match in
			if let error = fetcher.errors[match.id] {
				NavigationLink {
					errorDetails(error, for: match)
				} label: {
					Text(match.startTime, format: .dateTime.year().month().day().hour().minute())
				}
			}
		}
		.navigationTitle("Match Loading Errors")
	}
	
	func errorDetails(_ error: Error, for match: CompetitiveUpdate) -> some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 8) {
				Text("Match", comment: "Stats: error details")
					.font(.title3.bold())
				match.mapID.map(MapImage.LabelText.init)
				Text(match.id.description)
				
				Text("Error", comment: "Stats: error details")
					.font(.title3.bold())
					.padding(.top)
				Text(error.localizedDescription)
			}
			.frame(maxWidth: .infinity, alignment: .leading)
			.padding()
		}
		.navigationBarTitleDisplayMode(.inline)
		.navigationTitle("Error Details")
		.toolbar {
			Button {
				UIPasteboard.general.string = "\(match.id)\n\(error.localizedDescription)"
			} label: {
				Label(String(localized: "Copy Error", comment: "Stats: error details: accessibility label"), systemImage: "doc.on.doc")
			}
		}
	}
	
	@ViewBuilder
	func changeButtons(magnitude: Int) -> some View {
		if magnitude <= matchList.matches.count {
			VStack {
				changeButton(increment: +magnitude)
				changeButton(increment: -magnitude)
			}
		}
	}
	
	func changeButton(increment: Int) -> some View {
		Button(increment > 0 ? "+\(increment)" : "\(increment)") {
			fetchCount = clamp(fetchCount + increment)
		}
		.disabled(clamp(fetchCount + increment) == fetchCount)
		.monospacedDigit()
	}
	
	func clamp(_ count: Int) -> Int {
		count.clamped(to: 1...matchList.matches.count)
	}
}

@MainActor
private final class MatchFetcher: ObservableObject {
	@Published var matches: [Match.ID: MatchDetails] = [:]
	@Published var errors: [Match.ID: Error] = [:]
	@Published var fetchCount = 0 // so fetching less matches still changes the object
	private var tokens: [Match.ID: AnyCancellable] = [:]
	
	func fetchMatches(withIDs ids: some Collection<Match.ID>, load: @escaping ValorantLoadFunction) {
		fetchCount = ids.count
		for match in ids {
			guard tokens[match] == nil else { continue }
			tokens[match] = LocalDataProvider.shared.matchDetailsManager
				.objectPublisher(for: match)
				.receive(on: DispatchQueue.main)
				.sink { [weak self] in
					self?.matches[match] = $0.value
					self?.errors[match] = nil
				}
			
			Task {
				await load { [weak self] in
					do {
						try await MatchDetails.autoUpdate(for: match, using: $0)
					} catch {
						self?.errors[match] = error
					}
				}
			}
		}
	}
}

#if DEBUG
@available(iOS 16.0, *)
struct LoadingSection_Previews: PreviewProvider {
	static var previews: some View {
		Container(matchList: PreviewData.matchList)
			.withToolbar()
	}
	
	struct Container: View {
		var matchList: MatchList
		@State var fetchedMatches: [MatchDetails] = []
		
		var body: some View {
			Form {
				LoadingSection(matchList: matchList, fetchedMatches: $fetchedMatches)
			}
		}
	}
}
#endif
