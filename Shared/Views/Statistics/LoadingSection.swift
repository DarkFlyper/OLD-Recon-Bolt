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
			VStack(alignment: .leading, spacing: 12) {
				Text("To gather statistics, we first need to load matches to process. Note that large amounts can take a long time, especially when downloading for the first time!")
				
				HStack {
					Stepper("\(fetchCount) matches", value: $fetchCount, in: 1...matchList.matches.count)
					
					Button("All \(matchList.matches.count)") {
						fetchCount = matchList.matches.count
					}
					.buttonStyle(.bordered)
					.disabled(fetchCount == matchList.matches.count)
				}
				.onAppear {
					fetchCount = min(fetchCount, matchList.matches.count)
				}
				
				let oldestTime = sublist.last!.startTime
				Text("Data going back to \(oldestTime, format: .dateTime.year().month().day())")
					.foregroundStyle(.secondary)
					.font(.footnote)
				
				// TODO: use date instead? or at least allow cutting off from the top? button to filter to specific act?
				
				Button("Load Latest \(fetchCount) Matches") {
					fetcher.fetchMatches(withIDs: sublist.lazy.map(\.id), load: load)
				}
				.bold()
				.buttonStyle(.borderedProminent)
				.frame(maxWidth: .infinity)
			}
			.padding(.vertical, 4)
		} header: {
			Text("Load Data")
		} footer: {
			let fetchedCount = sublist.count { fetcher.matches.keys.contains($0.id) }
			Text("\(fetchedCount)/\(fetchCount) loaded (\(fetcher.errors.count) errors)")
		}
		.onReceive(fetcher.objectWillChange.debounce(for: 0.2, scheduler: DispatchQueue.main)) { _ in
			// compute stats
			statistics = .init(userID: matchList.userID, matches: sublist.compactMap { fetcher.matches[$0.id] })
		}
	}
}

@MainActor
private final class MatchFetcher: ObservableObject {
	@Published var matches: [Match.ID: MatchDetails] = [:]
	@Published var errors: [Error] = []
	private var tokens: [Match.ID: AnyCancellable] = [:]
	
	func fetchMatches(withIDs ids: some Sequence<Match.ID>, load: @escaping ValorantLoadFunction) {
		errors = []
		
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
						self?.errors.append(error)
					}
				}
			}
		}
	}
}
