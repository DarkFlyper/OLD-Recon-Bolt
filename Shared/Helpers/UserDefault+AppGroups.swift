import Foundation
import UserDefault

extension UserDefaults {
	static let shared = UserDefaults(suiteName: "group.juliand665.Recon-Bolt.shared")!
}

extension UserDefault {
	public init(wrappedValue: Value, _ key: String, migratingTo defaults: UserDefaults) {
		self.init(wrappedValue: wrappedValue, key, defaults: defaults)
		
		// swift doesn't call didSets within initializers
		migrateIfNeeded()
	}
	
	private mutating func migrateIfNeeded() {
		@UserDefault<Bool>("UserDefaults.hasMigrated.\(key)", defaults: defaults)
		var hasMigrated = false
		
		// always try to migrate items that aren't present, since the migration clearly failed and this avoids a failed migration from one process preventing a would-be successful migration in another
		guard !wasLoadedSuccessfully || !hasMigrated else { return }
		
		print(key, "needs migration", hasMigrated ? "because it failed to load" : "")
		
		do {
			let existingValue = try Value(defaultsRepresentation: .init(from: .standard, forKey: key))
			self.wrappedValue = existingValue
			print(key, "had existing value; migrated!")
		} catch {
			print(key, "migration failed!", error)
		}
		
		hasMigrated = true
	}
	
	public init(_ key: String, migratingTo defaults: UserDefaults) where Value: ExpressibleByNilLiteral {
		self.init(wrappedValue: nil, key, migratingTo: defaults)
	}
}
