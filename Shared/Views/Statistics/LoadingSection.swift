import SwiftUI
import ValorantAPI
import Combine

@available(iOS 16.0, *)
struct LoadingSection: View {
	var matchList: MatchList
	@Binding var statistics: Statistics?
	
	@State var fetchCount = 20
	@StateObject private var fetcher = MatchFetcher()
	
	@Environment(\.valorantLoad) private var load
	
	private var sublist: ArraySlice<CompetitiveUpdate> {
		matchList.matches.prefix(fetchCount)
	}
	
	var body: some View {
		Section {
			VStack(alignment: .leading, spacing: 16) {
				Text("To gather statistics, we first need to load matches to process. Note that large amounts can take a long time, especially when downloading for the first time!")
				
				Divider()
				
				VStack {
					Text("Matches to load: ") + Text("\(fetchCount)").bold()
					
					let oldestTime = sublist.last!.startTime
					Text("Data going back to \(oldestTime, format: .dateTime.year().month().day())")
						.foregroundStyle(.secondary)
						.font(.footnote)
					
					HStack {
						changeButtons(magnitude: 1)
						changeButtons(magnitude: 10)
						changeButtons(magnitude: 100)
						
						Button("All \(matchList.matches.count)") {
							fetchCount = matchList.matches.count
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
				
				Button("Load Latest \(fetchCount) Matches") {
					fetcher.fetchMatches(withIDs: sublist.lazy.map(\.id), load: load)
				}
				.bold()
				.buttonStyle(.borderedProminent)
				.frame(maxWidth: .infinity)
			}
			.padding(.vertical, 4)
			
			if !fetcher.errors.isEmpty {
				NavigationLink("^[\(fetcher.errors.count) Errors](inflect: true, morphology: { partOfSpeech: \"noun\" })") {
					errorList()
				}
			}
		} header: {
			Text("Load Data")
		} footer: {
			let fetchedCount = sublist.count { fetcher.matches.keys.contains($0.id) }
			Text("\(fetchedCount)/\(fetchCount) loaded")
		}
		.onReceive(
			fetcher.objectWillChange
				.debounce(for: 0.2, scheduler: DispatchQueue.main),
			perform: { _ in
				print("received")
				let userID = matchList.userID
				let matches = sublist.compactMap { fetcher.matches[$0.id] }
				Task.detached(priority: .userInitiated) {
					print("computing!")
					let stats = Statistics(userID: userID, matches: matches)
					await MainActor.run {
						self.statistics = stats
					}
				}
			}
		)
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
				Text("Match")
					.font(.title3.bold())
				match.mapID.map(MapImage.LabelText.init)
				Text(match.id.description)
				
				Text("Error")
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
				Label("Copy Error", systemImage: "doc.on.doc")
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
		max(1, min(matchList.matches.count, count))
	}
}

@MainActor
private final class MatchFetcher: ObservableObject {
	@Published var matches: [Match.ID: MatchDetails] = [:]
	@Published var errors: [Match.ID: Error] = [:]
	private var tokens: [Match.ID: AnyCancellable] = [:]
	
	func fetchMatches(withIDs ids: some Sequence<Match.ID>, load: @escaping ValorantLoadFunction) {
		errors = [:]
		
		for match in ids {
			guard tokens[match] == nil else { continue }
			tokens[match] = LocalDataProvider.shared.matchDetailsManager
				.objectPublisher(for: match)
				.receive(on: DispatchQueue.main)
				.sink { [weak self] in self?.matches[match] = $0.value }
			
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
		Container(matchList: PreviewData.matchList, statistics: PreviewData.statistics)
			.withToolbar()
	}
	
	struct Container: View {
		var matchList: MatchList
		@State var statistics: Statistics?
		
		var body: some View {
			Form {
				LoadingSection(matchList: matchList, statistics: $statistics)
			}
		}
	}
}
#endif
