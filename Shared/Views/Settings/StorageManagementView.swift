import SwiftUI
import ValorantAPI

struct StorageManagementView: View {
	@ObservedObject var manager: StorageManager
	@ObservedObject var accountManager: AccountManager
	
	var body: some View {
		List {
			LabeledSpace("Total Space Used", bytes: manager.totalBytes)
			
			MatchListsSection(accountManager: accountManager)
			
			Section("By Kind") {
				FolderOverview(
					title: "Match Lists",
					rootFolder: LocalDataProvider.shared.matchListManager.folderURL
				)
				FolderOverview(
					title: "Match Details",
					rootFolder: LocalDataProvider.shared.matchDetailsManager.folderURL
				)
				FolderOverview(
					title: "Career Summaries",
					rootFolder: LocalDataProvider.shared.careerSummaryManager.folderURL,
					clear: { try await LocalDataProvider.shared.careerSummaryManager.clearOut() }
				)
				FolderOverview(
					title: "Users",
					rootFolder: LocalDataProvider.shared.userManager.folderURL,
					clear: { try await LocalDataProvider.shared.userManager.clearOut() }
				)
				FolderOverview(
					title: "Identities",
					rootFolder: LocalDataProvider.shared.playerIdentityManager.folderURL,
					clear: { try await LocalDataProvider.shared.playerIdentityManager.clearOut() }
				)
			}
		}
		.navigationTitle("Manage Local Storage")
		.navigationBarTitleDisplayMode(.inline)
	}
	
	private struct MatchListsSection: View {
		@State var totalBytes: Int64?
		@State var byAccount: [User.ID: Int64]?
		@State var unaccountedFor: (matches: Set<Match.ID>, bytes: Int64)?
		@State var isConfirmingDelete = false
		
		@ObservedObject var accountManager: AccountManager
		@EnvironmentObject var bookmarkList: BookmarkList
		
		@Environment(\.loadWithErrorAlerts) private var load
		
		var body: some View {
			Section("Matches") {
				LabeledSpace("Total", bytes: totalBytes)
				
				ForEach(accountManager.storedAccounts, id: \.self) { (account: User.ID) in
					LabeledSpace(bytes: byAccount?[account, default: 0]) {
						Image(systemName: "person.crop.circle")
						UserLabel(userID: account)
					}
				}
				
				ForEach(bookmarkList.bookmarks, id: \.self) { bookmark in
					LabeledSpace(bytes: byAccount?[bookmark.user, default: 0]) {
						Image(systemName: "bookmark")
						UserLabel(userID: bookmark.user)
					}
				}
				
				LabeledSpace(unaccountedFor.map {
					"\($0.matches.count) from other players"
				} ?? "Other Players", bytes: unaccountedFor?.bytes)
				
				if let (matches, bytes) = unaccountedFor {
					Button("Free up these \(bytes, format: .byteCount(style: .file))", role: .destructive) {
						isConfirmingDelete = true
					}
					.confirmationDialog("Confirm Delete", isPresented: $isConfirmingDelete) {
						Button("Delete \(matches.count) Matches", role: .destructive) {
							Task {
								await load("Could not free up space!") {
									try await LocalDataProvider.shared.matchDetailsManager.clearOut(idFilter: matches)
								}
							}
						}
					}
				}
			}
			.detachedTask {
				await load("Could not determine used storage!") {
					try await computeTotals()
				}
			}
		}
		
		nonisolated func computeTotals() async throws {
			let listManager = LocalDataProvider.shared.matchListManager
			let matchManager = LocalDataProvider.shared.matchDetailsManager
			let total = recursiveSize(ofDirectory: listManager.folderURL)
			guard !Task.isCancelled else { return }
			
			let knownAccounts = await accountManager.storedAccounts + bookmarkList.bookmarks.lazy.map(\.user)
			let matchLists = await listManager.cachedObjects(for: knownAccounts)
			let knownMatches = matchLists.lazy.flatMap(\.matches).map(\.id)
			let usageByMatch = try await matchManager.diskUsage(for: knownMatches)
			guard !Task.isCancelled else { return }
			let byAccount: [User.ID: Int64] = .init(uniqueKeysWithValues: matchLists.lazy.map {
				($0.userID, $0.matches
					.lazy
					.compactMap { usageByMatch.tally[$0.id] }
					.reduce(0 as Int64, +))
			})
			
			await MainActor.run {
				self.totalBytes = total
				self.unaccountedFor = (usageByMatch.unknownIDs, usageByMatch.unaccountedFor)
				self.byAccount = byAccount
			}
		}
	}
	
	private struct FolderOverview: View {
		var title: LocalizedStringKey
		var rootFolder: URL
		var clear: (() async throws -> Void)?
		
		@State var total: Int64?
		
		@Environment(\.loadWithErrorAlerts) private var load
		
		var body: some View {
			LabeledSpace(title, bytes: total)
				.detachedTask { total = recursiveSize(ofDirectory: rootFolder) }
				.swipeActions {
					if let clear {
						AsyncButton(role: .destructive) {
							await load("Could not delete files!") { try await clear() }
						} label: {
							Label("Clear All", systemImage: "trash")
						}
					}
				}
		}
	}
}

extension View {
	func detachedTask(priority: TaskPriority = .userInitiated, operation: @escaping @Sendable () async -> Void) -> some View {
		task(priority: priority) { // start with the specified priority too
			let task = Task.detached(priority: priority, operation: operation) // detach to not block main queue with long-running ops
			await withTaskCancellationHandler {
				await task.value
			} onCancel: {
				task.cancel()
			}
		}
	}
}

private struct LabeledSpace<Label: View>: View {
	let bytes: Int64?
	@ViewBuilder var label: Label
	
	var body: some View {
		HStack {
			label
			Spacer()
			if let bytes {
				Text(bytes, format: .byteCount(style: .file))
					.foregroundStyle(bytes == 0 ? .tertiary : .secondary)
					.monospacedDigit()
			} else {
				ProgressView()
			}
		}
	}
}

extension LabeledSpace where Label == Text {
	init(_ title: LocalizedStringKey, bytes: Int64?) {
		self.init(bytes: bytes) { Text(title) }
	}
}

extension LabeledSpace where Label == UserLabel {
	init(_ userID: User.ID, bytes: Int64?) {
		self.init(bytes: bytes) { UserLabel(userID: userID) }
	}
}

@MainActor
final class StorageManager: ObservableObject {
	@Published private(set) var totalBytes: Int64?
	
	init() {
		Task.detached(priority: .userInitiated) {
			let total = recursiveSize(ofDirectory: FolderLocations.localData)
			await MainActor.run {
				self.totalBytes = total
			}
		}
	}
}

private func recursiveSize(ofDirectory root: URL) -> Int64 {
	guard !isInSwiftUIPreview else { return 12345 }
	
	// rather than lots of little filesystem requests, we'll just do one directory listing and work with that.
	let contents = try! FileManager.default.contentsOfDirectory(
		at: root,
		includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey]
	)
	
	return contents
		.lazy
		.map { url -> Int64 in
			guard !Task.isCancelled else { return 0 }
			let values = try! url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
			return values.isDirectory! ? recursiveSize(ofDirectory: url) : Int64(values.fileSize!)
		}
		.reduce(0, +)
}

#if DEBUG
struct StorageManagementView_Previews: PreviewProvider {
	static var previews: some View {
		StorageManagementView(manager: .init(), accountManager: .mocked)
			.withToolbar()
			.environmentObject(BookmarkList(
				bookmarks: PreviewData.pregameInfo.team.players
					.lazy
					.map(\.id)
					.map { .init(user: $0, location: .europe) }
					.suffix(3)
			))
	}
}
#endif
