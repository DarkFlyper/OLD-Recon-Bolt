import SwiftUI
import Combine
import HandyOperators

struct ContentView<ML: MatchList>: View {
	@State private var isLoggingIn = false
	@State private var client: Client?
	@State private var shouldShowUnranked = true
	
	@StateObject var matchList: ML
	
	@State private var loadTask: AnyCancellable?
	@State private var loadError: PresentedError?
	@State private var userInfo: UserInfo? {
		didSet {
			guard let userID = userInfo?.id else { return }
			matchList.switchUser(to: userID)
		}
	}
	
	private var isLoading: Bool { loadTask != nil }
	
	var body: some View {
		List {
			loadButton(
				matchList.minMissedMatches > 0
					? "Load \(matchList.minMissedMatches)+ Newer Matches"
					: "Load Newer Matches",
				task: matchList.loadNewerMatches(using:)
			)
			.frame(maxWidth: .infinity, alignment: .center)
			
			ForEach(
				shouldShowUnranked ? matchList.matches : matchList.matches.filter(\.isRanked),
				id: \.id,
				content: MatchCell.init(match:)
			)
			
			loadButton(
				"Load Older Matches",
				task: matchList.loadOlderMatches(using:)
			)
			.frame(maxWidth: .infinity, alignment: .center)
		}
		.in {
			#if os(macOS)
			$0.listStyle(InsetListStyle())
			#else
			$0.listStyle(InsetGroupedListStyle())
			#endif
		}
		.onAppear {
			guard client == nil else { return }
			isLoggingIn = true
		}
		.onChange(of: client?.id) { _ in
			isLoggingIn = false
			loadMatches()
		}
		.navigationTitle(userInfo?.account.name ?? "Matches")
		.toolbar {
			let accountButton = Button("Account") { isLoggingIn = true }
			let hideUnrankedButton = Button(shouldShowUnranked ? "Hide Unranked" : "Show Unranked")
				{ shouldShowUnranked.toggle() }
			#if os(macOS)
			hideUnrankedButton
			Spacer()
			accountButton
			#else
			ToolbarItemGroup(placement: .navigationBarLeading) { hideUnrankedButton }
			ToolbarItemGroup(placement: .navigationBarTrailing) { accountButton }
			#endif
		}
		// workaround for not being able to stack sheet modifiers yet
		.overlay(EmptyView().sheet(isPresented: $isLoggingIn) {
			LoginSheet(client: $client)
		})
		.overlay(EmptyView().alert(item: $loadError) { error in
			Alert(
				title: Text("Could not load matches!"),
				message: Text(error.error.localizedDescription),
				dismissButton: .default(Text("OK"))
			)
		})
		.in { list in
			#if os(macOS)
			list
			#else
			NavigationView { list }
				.navigationViewStyle(StackNavigationViewStyle())
			#endif
		}
	}
	
	private func loadButton(
		_ title: String,
		task: @escaping (Client) -> AnyPublisher<Bool, Error>
	) -> some View {
		Button(title) {
			executeLoad { client in
				task(client)
					.tryMap {
						if !$0 { throw LoadingError(message: "No further matches received.") }
					}
					.eraseToAnyPublisher()
			}
		}
		.disabled(loadTask != nil || client == nil)
		.in {
			#if os(macOS)
			$0
				.buttonStyle(LinkButtonStyle())
				.foregroundColor(.accentColor)
			#else
			$0
			#endif
		}
	}
	
	private func executeLoad(_ task: (Client) -> AnyPublisher<Void, Error>) {
		guard let client = client else { return }
		loadTask = task(client)
			.sinkResult {}
				   onFailure: { loadError = .init($0) }
				   always: { loadTask = nil }
	}
	
	func loadMatches() {
		executeLoad { client in
			client.getUserInfo()
				.receive(on: DispatchQueue.main)
				.map { userInfo = $0 }
				.flatMap {
					matchList.matches.isEmpty
						? matchList.loadOlderMatches(using: client)
						: Just(true).setFailureType(to: Error.self).eraseToAnyPublisher()
				}
				.map { _ in }
				.eraseToAnyPublisher()
		}
	}
	
	struct LoadingError: LocalizedError {
		var message: String
		
		var errorDescription: String? { message }
	}
}

struct ContentView_Previews: PreviewProvider {
	static let exampleMatchData = try! Data(
		contentsOf: Bundle.main
			.url(forResource: "example_matches", withExtension: "json")!
	)
	static let decoder = JSONDecoder() <- { $0.dateDecodingStrategy = .millisecondsSince1970 }
	static let exampleMatches = try! decoder
		.decode([Match].self, from: exampleMatchData)
	
	static var previews: some View {
		ContentView(matchList: PreviewMatchList(matches: exampleMatches))
			.preferredColorScheme(.light)
		ContentView(matchList: PreviewMatchList(matches: exampleMatches))
			.preferredColorScheme(.dark)
	}
}

struct PresentedError: Identifiable {
	let id = UUID()
	
	let error: Error
	
	init(_ error: Error) {
		self.error = error
	}
}
