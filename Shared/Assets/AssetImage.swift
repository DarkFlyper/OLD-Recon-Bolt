import Foundation
import SwiftUI
import Protoquest
import HandyOperators

struct AssetImage: Hashable {
	var url: URL
	
	@ViewBuilder
	func view(
		renderingMode: Image.TemplateRenderingMode? = nil,
		aspectRatio: CGFloat? = nil,
		shouldLoadImmediately: Bool = false
	) -> some View {
		ImageView(
			image: self,
			renderingMode: renderingMode,
			aspectRatio: aspectRatio,
			shouldLoadImmediately: shouldLoadImmediately
		)
		.id(self)
#if DEBUG
		.modifier(ImageManagerProvider())
#endif
	}
	
#if WIDGETS
	static var preloaded: [Self: Image] = [:]
#endif
	
	var localURL: URL {
		Self.localFolder.appendingPathComponent(url.path, isDirectory: false)
	}
	
	func load() -> UIImage? {
		.init(contentsOfFile: localURL.path)
	}
	
	private static let localFolder = try! FileManager.default
		.url(
			for: .applicationSupportDirectory,
			in: .userDomainMask,
			appropriateFor: nil,
			create: true
		)
		.appendingPathComponent("AssetImage", isDirectory: true)
	
	static func removeCachedFiles() throws {
		try FileManager.default.removeItem(at: localFolder)
	}
	
	private struct ImageView: View {
		let image: AssetImage
		var renderingMode: Image.TemplateRenderingMode?
		/// aspect ratio for the placeholder shown when the image is not loaded
		var aspectRatio: CGFloat?
		var shouldLoadImmediately: Bool = false
		@State var loaded: UIImage?
		
		@State private var isShowingErrorAlert = false
		@State private var loadError: Error?
		
		@EnvironmentObject private var manager: ImageManager
		
		var body: some View {
			#if WIDGETS
			if let loaded = preloaded[image] {
				loaded
					.renderingMode(renderingMode)
					.resizable()
					.scaledToFit()
			} else {
				Color.primary.opacity(0.1)
					.aspectRatio(aspectRatio, contentMode: .fit)
			}
			#else
			switch manager.state(for: image) {
			case nil:
				content.onAppear {
					Task.detached(priority: .userInitiated) {
						await manager.download(image)
					}
				}
			case .downloading:
				content
					.overlay { ProgressView() }
			case .errored(let error):
				content
					.overlay { Image(systemName: "xmark.octagon.fill") }
					.onTapGesture {
						loadError = error
						isShowingErrorAlert = true
						Task.detached { await manager.download(image) }
					}
					.alert(
						"Image failed to load!",
						isPresented: $isShowingErrorAlert,
						presenting: loadError
					) { error in
						Button("Copy Error Details") {
							UIPasteboard.general.string = error.localizedDescription
						}
						Button("OK") {}
					}
			case .available:
				content
			}
			#endif
		}
		
		@ViewBuilder
		var content: some View {
			if let loaded = loaded ?? cached {
				Image(uiImage: loaded)
					.renderingMode(renderingMode)
					.resizable()
					.scaledToFit()
					.onChange(of: manager.cacheState(for: image)) { _ in self.loaded = nil }
			} else {
				let _ = load()
				Color.primary.opacity(0.1)
					.aspectRatio(aspectRatio, contentMode: .fit)
			}
		}
		
		private var cached: UIImage? {
			let state = manager.cacheState(for: image, loadImmediately: shouldLoadImmediately)
			guard case .cached(let image) = state else { return nil }
			return image
		}
		
		private func load() {
			guard case .tooLarge = manager.cacheState(for: image) else { return }
			Task.detached(priority: .userInitiated) {
				let unprepared = image.load()
				let loaded = unprepared?.preparingForDisplay() ?? unprepared
				await setLoaded(loaded)
			}
		}
		
		@MainActor
		private func setLoaded(_ loaded: UIImage?) {
			self.loaded = loaded
		}
	}
}

extension Optional where Wrapped == AssetImage {
	@ViewBuilder
	func view() -> some View {
		if let self {
			self.view()
		} else {
			Color.gray
		}
	}
}

#if DEBUG
private struct ImageManagerProvider: ViewModifier {
	func body(content: Content) -> some View {
		if isInSwiftUIPreview {
			content.environmentObject(ImageManager())
		} else {
			content
		}
	}
}
#endif

extension AssetClient {
	/// - returns: whether a new image was downloaded (false means old image is still correct)
	func ensureDownloaded(_ image: AssetImage) async throws -> Bool {
		// don't download images that we already have (assuming size will always change when the image changes)
		if let existingSize = FileManager.default.sizeOfItem(atPath: image.localURL.path) {
			print("\(image.url) found existing size \(existingSize)")
			let newSize = try await send(ImageSizeRequest(imageURL: image.url))
			guard newSize != existingSize else { return false }
		} else {
			assert(!FileManager.default.fileExists(atPath: image.localURL.path))
		}
		
		let imageData = try await send(ImageDownloadRequest(imageURL: image.url))
		try FileManager.default.createDirectory(
			at: image.localURL.deletingLastPathComponent(),
			withIntermediateDirectories: true
		)
		try imageData.write(to: image.localURL)
		return true
	}
}

extension FileManager {
	func sizeOfItem(atPath path: String) -> Int? {
		guard let size = try? attributesOfItem(atPath: path)[.size] else { return nil }
		return (size as! NSNumber).intValue
	}
}

private struct ImageDownloadRequest: GetDataRequest {
	var imageURL: URL
	
	var baseURLOverride: URL? {
		imageURL
	}
}

// TODO: use a hash instead
private struct ImageSizeRequest: GetRequest {
	var imageURL: URL
	
	var baseURLOverride: URL? {
		imageURL
	}
	
	var httpMethod: String { "HEAD" }
	
	func decodeResponse(from raw: Protoresponse) throws -> Int {
		.init(raw.httpMetadata!.expectedContentLength)
	}
}

extension AssetImage: Codable {
	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		url = try container.decode(URL.self)
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(url)
	}
}
