import Foundation
import UserDefault
import HandyOperators

struct Chronology<Entry> where Entry: ChronologyEntry {
	private(set) var entries: [Entry] = []
	private(set) var estimatedMissedEntries = 0 {
		didSet { assert(estimatedMissedEntries >= 0) }
	}
	
	/// - throws: if nothing changed (no new entries added and minMissedEntries unchanged)
	func addingEntries(_ new: [Entry], startIndex sentStartIndex: Int) throws -> Self {
		let new = self <- { $0.tryToAddEntries(new, startIndex: sentStartIndex) }
		
		guard false
				|| new.estimatedMissedEntries != estimatedMissedEntries
				|| new.entries.count != entries.count
		else { throw NoNewEntriesError() }
		
		return new
	}
	
	private mutating func tryToAddEntries(_ new: [Entry], startIndex sentStartIndex: Int) {
		guard !new.isEmpty else {
			print("no entries passed to addEntries!")
			return
		}
		guard !entries.isEmpty else {
			entries = new
			return
		}
		
		let firstNew = new.first!
		let lastNew = new.last!
		
		// oof
		if let overlapStart = entries.firstIndexByID(of: firstNew) {
			let expectedOverlapStart = sentStartIndex - estimatedMissedEntries
			estimatedMissedEntries += max(0, expectedOverlapStart - overlapStart)
			
			guard let lastIndex = new.firstIndexByID(of: entries.last!) else { return }
			let nonOverlapping = new.suffix(from: lastIndex + 1)
			guard !nonOverlapping.isEmpty else { return }
			
			entries.append(contentsOf: nonOverlapping)
		} else if let _ = entries.firstIndexByID(of: lastNew) {
			// sometimes the api seems to decide to discard some older games?? let's work with that
			estimatedMissedEntries = sentStartIndex
			guard let firstKnown = new.firstIndexByID(of: entries.first!) else {
				// all new entries already known
				estimatedMissedEntries = sentStartIndex
				return
			}
			
			let nonOverlapping = new.prefix(upTo: firstKnown)
			guard !nonOverlapping.isEmpty else { return }
			
			entries = nonOverlapping + entries
			estimatedMissedEntries = sentStartIndex
		} else {
			// no overlap!
			if entries.last!.time > firstNew.time {
				assert(sentStartIndex == entries.count + estimatedMissedEntries)
				// first older match is right before our current oldest
				entries.append(contentsOf: new)
			} else if entries.first!.time < lastNew.time {
				// TODO: figure out how to handle this; easiest would be to just keep refreshing until we reach our newest existing match
				print("non-contiguous match history: too many entries played since last refresh!")
				estimatedMissedEntries = sentStartIndex + new.count * 3/2
			} else {
				fatalError("unexpected state!")
			}
		}
	}
	
	private struct NoNewEntriesError: LocalizedError {
		let errorDescription: String? = "No further entries received."
	}
}

extension Chronology: Codable where Entry: Codable {}

protocol ChronologyEntry: Identifiable {
	var time: Date { get }
}

private extension Array where Element: Identifiable {
	func firstIndexByID(of element: Element) -> Index? {
		let id = element.id
		return firstIndex { $0.id == id }
	}
}
