enum Managers {
	@MainActor static let accounts = AccountManager()
	@MainActor static let assets = AssetManager()
	// TODO: this storage should really be shared with the main app somehow…
	@MainActor static let images = ImageManager()
}
