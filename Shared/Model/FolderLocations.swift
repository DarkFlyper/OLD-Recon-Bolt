import Foundation
import HandyOperators

enum FolderLocations {
	private static let fileManager = FileManager.default
	
	private static let oldLocalData = try! fileManager.url(
		for: .cachesDirectory,
		in: .userDomainMask,
		appropriateFor: nil,
		create: true
	).appendingPathComponent("local")
	
	private static let newLocalData = fileManager
		.containerURL(forSecurityApplicationGroupIdentifier: "group.juliand665.Recon-Bolt.shared")!
		.appendingPathComponent("Library/Application Support/local", isDirectory: true)
	<- { newFolder in
#if !WIDGETS
		guard fileManager.fileExists(atPath: oldLocalData.path) else { return }
		// migrate
		do {
			try fileManager.createDirectory(at: newFolder.deletingLastPathComponent(), withIntermediateDirectories: true)
			try fileManager.moveItem(at: oldLocalData, to: newFolder)
		} catch {
			print("could not migrate from \(oldLocalData) to \(newFolder):", error)
			dump(error)
		}
#endif
	}
	
	static let localData = isInSwiftUIPreview
	? Bundle.main.resourceURL!.appendingPathComponent("Local", isDirectory: true)
	: newLocalData
}
